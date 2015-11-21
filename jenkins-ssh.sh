#!/bin/bash
# vi:ts=4:sw=4:et
#
# This script is meant to be run via ssh by specifying it in authorized_keys

args=($SSH_ORIGINAL_COMMAND)
export PATH=$PATH:/opt/conmux/bin:/opt/build/pyboot
scripts=/opt/build/scripts

case "${args[0]}" in
    test)
        echo "This is a test"
        env
        ;;
    pyboot-tftp-dd)
        cd ${scripts}/pyboot-tftp-dd
        #${scripts}/jenkins-external.sh ./run.sh
        ./run.sh
        ;;
    xen-arm-builder)
        ${scripts}/container.sh ${scripts}/jenkins-external.sh xen-arm-builder_external ${scripts}/rebuild.sh
        ;;
    *)
        echo "Invalid command: ${args[0]}"
        exit 1
        ;;
esac
