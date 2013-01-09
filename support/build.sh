#!/bin/bash

set -e
set -x

if [ "$AWS_ID" == "" ]; then
    echo "must set AWS_ID"
    exit 1
fi

if [ "$AWS_SECRET" == "" ]; then
    echo "must set AWS_SECRET"
    exit 1
fi

MY_DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BUILD_RC="$(dirname ${MY_DIR})/buildpack.rc"
. "${BUILD_RC}"

s3Bucket="${s3Bucket?Missing s3Bucket}"
sourcesBaseUrl="${sourcesBaseUrl?Missing sourcesBaseUrl}"

buildNumber=$(date -u '+%Y%m%dT%H%M%SZ')
baseDir="$( cd -P "$( dirname "$0" )" && pwd )"
tempDir="$( mktemp -d -t $(basename $0).XXXXXXXX )" || exit 1

srcBuildInfo="${tempDir}/buildInfo.txt"
echo "Head-Commit-Id: $(git rev-parse HEAD)" >> "${srcBuildInfo}"
echo >> "${srcBuildInfo}"
echo "Git-Status:" >> "${srcBuildInfo}"
git status >> "${srcBuildInfo}"

buildLogOut="${tempDir}/out.log"
touch "${buildLogOut}"
tail -f "${buildLogOut}" &
exec 1>"${buildLogOut}"

buildLogErr="${tempDir}/err.log"
touch "${buildLogErr}"
tail -f "${buildLogErr}" &
exec 2>"${buildLogErr}"

cp "${baseDir}/vulcan_build.sh" "${tempDir}/vulcan_build.sh"
vulcan build -v \
    -c "SOURCES_BASE_URL='${sourcesBaseUrl}' bash vulcan_build.sh" \
    -p "/app/vendor" \
    -s "${tempDir}" \
    -o "${tempDir}/build.tar.gz"

# upload all build artifacts to s3
for f in ${tempDir}/*
do
    "${baseDir}/aws/s3" put "${s3Bucket}" \
        "builds/${buildNumber}/$(basename ${f})" "${f}"
done

sed -i "s/^buildNumber=.*/buildNumber=\"${buildNumber}\"/" "${BUILD_RC}"
rm -rf "${tempDir}"
