#!/bin/bash -eux
dest=/tftpboot/initrd.cpio.gz
rm -rf tmpdir
mkdir tmpdir
cd tmpdir
mkdir -p bin etc run sbin usr/bin usr/sbin var
install -D /opt/build/busybox/busybox bin/busybox
ln -s busybox bin/sh
install -D ../init.sh init
find . | cpio --create --format='newc' | gzip -c > ${dest}
cd ..
rm -rf tmpdir
