#!/bin/bash -eux

which hexdump >/dev/null || sudo apt-get install -y bsdmainutils || exit 1
which curl >/dev/null

buildname="$1"
shift
logbase=/tmp/jenkins-external
logfile=${logbase}.log
logxml=${logbase}.xml
api_token=`cat /opt/build/api-token.txt`

# Partly based on: http://steve-jansen.github.io/blog/2014/11/20/how-to-use-jenkins-to-monitor-cron-jobs/
start_time=`date +"%s"`
# Don't fail the log upload if the build fails
set +e
"$@" > ${logfile} 2>&1
result=$?
set -e
end_time=`date +"%s"`

# Generate XML
duration_ms=$((1000 * ($end_time - $start_time) ))
echo -n "<run><log encoding=\"hexBinary\">" > ${logxml}
cat ${logfile} | hexdump -v -e '1/1 "%02x"' >> ${logxml}
echo -n "</log><result>$result</result><duration>$duration_ms</duration></run>" >> ${logxml}
# Don't show the password
set +x
if curl -X POST -u "external:${api_token}" -d@${logxml} https://jenkins-lukedunstan.rhcloud.com/job/${buildname}/postBuildResult ; then
    echo "postBuildResult OK"
else
    echo "postBuildResult failed"
fi
