set -e

vendor_dir="/app/vendor"
apache_dir="${vendor_dir}/apache"
php_dir="${vendor_dir}/php"

tailFile() {
    local fileName
    local prefix
    fileName="${1?filename missing}"
    prefix="${2=$(basename ${fileName})}"
    touch "${fileName}"
    tail -F "${fileName}" | sed  --unbuffered -e "s/^/${prefix} /" &
}

tailFile "${apache_dir}/logs/error_log" apache-error-log
tailFile "${apache_dir}/logs/access_log" apache-access-log
tailFile "${apache_dir}/logs/access_log.json" apache-access-log-json

tailFile "${php_dir}/php_errors.log" php-errors
export LD_LIBRARY_PATH="${php_dir}/ext"

if [ "${NEWRELIC_LICENSE_KEY}" != "" ]
then
    newrelic_dir="${vendor_dir}/newrelic"
    newrelic_php_conf="${php_dir}/etc/ext.d/newrelic.ini"
    tailFile "${newrelic_dir}/newrelic-daemon.log" newrelic-daemon
    tailFile "${newrelic_dir}/php_agent.log" newrelic-php-agent
    sed -i -e "s/^newrelic\.enabled.*/newrelic.enabled = true/" "${newrelic_php_conf}"
    sed -i -e "s/^newrelic\.license.*/newrelic.license = \"${NEWRELIC_LICENSE_KEY}\"/" "${newrelic_php_conf}"
fi

echo "Launching apache"
exec "${apache_dir}/bin/httpd" -DNO_DETACH
