#!/usr/bin/env python
#
# Downloads cubieboard2.img to a board that is running an initramfs,
# power cycles the board, and verifies that the first boot is successful.
# This is similar to pyboot but is used for a later stage.

from __future__ import print_function
import hashlib
import os
import pexpect
import sys


conmux_board = 'cubieboard2'
tftp_dir = '/tftpboot'
tftp_ip = '192.168.2.105'
image_name = 'cubieboard2.img'
image_path = os.path.join(tftp_dir, image_name)
log_path = '/tmp/{}-load_img.log'.format(os.getenv('USER'))
prompt = r"(# )|(\(initramfs\) )"


def command(c, s):
    print('cmd: ' + s)
    c.sendline(s)


def expect_prompt(c):
    i = c.expect(prompt, timeout=10)
    assert i == 0


def md5sum_and_size(path):
    h = hashlib.md5()
    size = 0
    with open(path, 'rb') as f:
        block = f.read(65536)
        while block:
            size += len(block)
            h.update(block)
            block = f.read(65536)
    return h.hexdigest(), size


def load_image(c):
    command(c, 'tftp -g -r {} -l - {} | dd of=/dev/mmcblk0 bs=1M'.format(image_name, tftp_ip))
    print('Downloading image...', end='', flush=True)
    while True:
        i = c.expect([
            r'(\d+) bytes \([^)]*\) copied',
            image_name,
            ], timeout=60)
        if i == 0:
            size = int(c.match.group(1))
            return size
        else:
            assert i == 1
            #print('.', end='', flush=True)


def verify_image(c, size):
    assert size % 1048576 == 0
    megs = size // 1048576
    command(c, 'dd if=/dev/mmcblk0 bs=1M count={} | md5sum'.format(megs))
    print('Verifying image...')
    c.expect(r'([0-9a-f]{32})\s+-', timeout=600)
    checksum = c.match.group(1)
    expect_prompt(c)
    return checksum


def main():
    if sys.version_info.major == 3:
        kwargs = dict(encoding='utf-8', codec_errors='ignore')
    else:
        kwargs = {}
    c = pexpect.spawn("conmux-console {}".format(conmux_board), timeout=30, **kwargs)
    c.logfile = open(log_path, 'w')
    #c.logfile_read = sys.stdout

    print('Checking for prompt')
    command(c, '\n')
    expect_prompt(c)

    print('Calculating source md5sum...')
    checksum, size = md5sum_and_size(image_path)
    print('Source size: {} md5sum: {}'.format(size, checksum))

    actual_size = load_image(c)
    if actual_size != size:
        print('Error: incorrect size {} != {}'.format(actual_size, size))
        return 1

    command(c, '\n')
    expect_prompt(c)
    actual_checksum = verify_image(c, size)
    if actual_checksum != checksum:
        print('Error: incorrect md5sum {} != {}'.format(actual_checksum, checksum))
        return 1
    print('Verified OK')

    print('Running sync')
    command(c, 'sync')
    expect_prompt(c)
    print('Power cycling')
    command(c, '~$hardreset')
    c.expect('U-Boot', timeout=30)
    print('Waiting for kernel')
    c.expect(['Booting Linux', 'Linux version'], timeout=60)
    print('Waiting for userspace')
    c.expect(['login:', '# '], timeout=600)

    print('Finished successfully.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
