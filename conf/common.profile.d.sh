#!/bin/sh

vendor_dir="/app/vendor"
apache_dir="${vendor_dir}/apache"
php_dir="${vendor_dir}/php"
newrelic_dir="${vendor_dir}/newrelic"

# tailFile filename [prefix]
tailFile() {
    local fileName
    local prefix
    fileName="${1?filename missing}"
    prefix="${2=$(basename ${fileName})}"
    touch "${fileName}"
    tail -F "${fileName}" | sed  --unbuffered -e "s/^/${prefix} /" &
}
