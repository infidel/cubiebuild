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
netstat -n -u -a | grep ':69 '
test -d /tftpboot
test -w /tftpboot

rm -f ${imgdest}
ln ${imgsrc} ${imgdest}
pyboot -l /tmp/${USER}-load-image.log -v cubieboard2
set +e
rm /tmp/${USER}-load_img.log
./load_img.py
result=$?
cat /tmp/${USER}-load_img.log
exit $result
