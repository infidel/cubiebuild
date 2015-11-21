#!/bin/sh -eux
# vi:shiftwidth=2

IMG=${BOARD-cubieboard2}.img

losetup -f ${IMG}
LOOPDEV=$(losetup -j ${IMG} -o 0 | cut -d ":" -f 1)

MLOOPDEV=`echo $LOOPDEV | sed -e 's,/dev/,/dev/mapper/,g'`
kpartx -avs ${LOOPDEV}

mount ${MLOOPDEV}p2 /mnt
mount -o bind /proc /mnt/proc
mount -o bind /dev /mnt/dev

