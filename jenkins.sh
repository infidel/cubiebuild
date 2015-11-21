#!/bin/bash
# vi:ts=4:sw=4:et

args=($SSH_ORIGINAL_COMMAND)
export PATH=$PATH:/opt/conmux/bin

case "${args[0]}" in
    test)
        echo "This is a test"
        env
        ;;
    pyboot)
        pyboot/pyboot cubieboard2
        ;;
    xen-arm-builder)
        docker run --rm --privileged \
            --link apt-cacher:proxy -e "http_proxy=http://proxy:3142/" \
            -e BOARD=cubieboard2 -e DISTROVER=trusty \
            -v /opt/build:/opt/build -w /opt/build/xen-arm-builder \
            xen-sdcard-builder bash /opt/build/scripts/jenkins-rebuild.sh ${args[1]}
        ;;
    *)
        echo "Invalid command: ${args[0]}"
        exit 1
        ;;
esac
