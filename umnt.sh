#!/bin/sh -eux
# vi:shiftwidth=2

IMG=${BOARD-cubieboard2}.img

umount /mnt/proc || true
umount /mnt/dev || true

# cleanup loops
for loop_dev in $(losetup -j ${IMG} | cut -d ":" -f 1); do
  loop_dev_mapper=`echo ${loop_dev} | sed -e 's,/dev/,/dev/mapper/,g'`
  umount ${loop_dev_mapper}p1 || true
  umount ${loop_dev_mapper}p2 || true
  kpartx -d ${loop_dev} || true
  losetup -d ${loop_dev} || true
done
