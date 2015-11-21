#!/bin/bash -eux
imgname=cubieboard2.img
imgsrc=/opt/build/xen-arm-builder/${imgname}
imgdest=/tftpboot/${imgname}

echo Checking for .pyboot
test -f .pyboot
echo Checking for conmux-console
which conmux-console
echo Checking for image
test -f ${imgsrc}
echo Checking for TFTP server
netstat -n -u -a | grep ':68 '
test -d /tftpboot
test -w /tftpboot

rm -f ${imgdest}
ln ${imgsrc} ${imgdest}
pyboot -l /tmp/pyboot-tftp-dd.log -v cubieboard2
