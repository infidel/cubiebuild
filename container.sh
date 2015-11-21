#!/bin/sh
if [ "$1" == "-i" ] ; then
    interactive=-it
    shift
fi
docker run ${interactive} --rm --privileged \
    --link apt-cacher:proxy -e "http_proxy=http://proxy:3142/" \
    -e BOARD=cubieboard2 -e DISTROVER=trusty \
    -v /opt/build:/opt/build -w /opt/build/xen-arm-builder \
    xen-sdcard-builder "$@"
