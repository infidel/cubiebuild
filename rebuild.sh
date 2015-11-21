#!/bin/bash -eux
git status
git diff
git log -1

if [ -d u-boot/.git ] ; then
    cd u-boot
    git clean -fxd
    git checkout -f
    git status
    git log -1
    cd ..
fi
if [ -d linux/.git ] ; then
    cd linux
    git clean -fxd
    git checkout -f
    git status
    git log -1
    cd ..
fi
if [ -d xen/.git ] ; then
    cd xen
    git clean -fxd
    git checkout -f
    git status
    git log -1
    cd ..
fi
rm cubieboard2.img

time make clone
if [ -d u-boot/.git ] ; then
    (cd u-boot && git log -1 && git status)
fi
if [ -d linux/.git ] ; then
    (cd linux && git log -1 && git status)
fi
if [ -d xen/.git ] ; then
    (cd xen && git log -1 && git status)
fi

time make build
time make ${BOARD-cubieboard2}.img
