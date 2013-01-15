#!/bin/sh

. ~/.profile.d/common.sh

# add apache binaries to the path
export PATH="${apache_dir}/bin:${PATH}"

tailFile "${apache_dir}/logs/error_log" apache-error-log
tailFile "${apache_dir}/logs/access_log" apache-access-log
tailFile "${apache_dir}/logs/access_log.json" apache-access-log-json
