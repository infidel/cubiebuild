#!/bin/bash -x
# This script runs inside the Docker container

which hexdump >/dev/null || sudo apt-get install -y bsdmainutils || exit 1

# Partly based on: http://steve-jansen.github.io/blog/2014/11/20/how-to-use-jenkins-to-monitor-cron-jobs/
start_time=`date +"%s"`
/opt/build/scripts/rebuild.sh > rebuild.log 2>&1
result=$?
end_time=`date +"%s"`
duration_ms=$((1000 * ($end_time - $start_time) ))
echo -n "<run><log encoding=\"hexBinary\">" > rebuild.xml
cat rebuild.log | hexdump -v -e '1/1 "%02x"' >> rebuild.xml
echo -n "</log><result>$result</result><duration>$duration_ms</duration></run>" >> rebuild.xml
# Don't show the password
set +x
if curl -X POST -u "external:1a8f1b99271b30ac3c388cfc823ba218" -d@rebuild.xml https://jenkins-lukedunstan.rhcloud.com/job/xen-arm-builder_external/postBuildResult ; then
    echo "postBuildResult OK"
else
    echo "postBuildResult failed"
fi
