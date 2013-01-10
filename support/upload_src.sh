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

baseDir="$( cd -P "$( dirname "$0" )" && pwd )"

for sourceFile in "$@"
do
    echo "Uploading source "${sourceFile}" to ${s3Bucket}"
    "${baseDir}/aws/s3" put "${s3Bucket}" \
    "sources/$(basename ${sourceFile})" "${sourceFile}"
done
