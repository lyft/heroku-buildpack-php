set -e
set -x

vendor_dir="/app/vendor"
apache_dir="${vendor_dir}/apache"
php_dir="${vendor_dir}/php"

touch "${apache_dir}/logs/error_log"
tail -F "${apache_dir}/logs/error_log" | sed -e 's/^/apache-error /' &
touch "${apache_dir}/logs/access_log"
tail -F "${apache_dir}/logs/access_log" | sed -e 's/^/apache-access /' &
touch "${apache_dir}/logs/access_log.json"
tail -F "${apache_dir}/logs/access_log.json" | sed -e 's/^/apache-access-json /' &

export LD_LIBRARY_PATH="${php_dir}/ext"

if [ "${NEWRELIC_LICENSE_KEY}" != "" ]
then
    newrelic_dir="${vendor_dir}/newrelic"
    newrelic_php_conf="${php_dir}/etc/ext.d/newrelic.ini"
    touch "${newrelic_dir}/newrelic-daemon.log"
    tail -F "${newrelic_dir}/newrelic-daemon.log" | sed -e 's/^/newrelic-daemon /' &
    touch "${newrelic_dir}/php_agent.log"
    tail -F "${newrelic_dir}/php_agent.log" | sed -e 's/^/newrelic-php-agent /' &
    sed -i -e "s/^newrelic\.enabled.*/newrelic.enabled = true" "${newrelic_php_conf}"
    sed -i -e "s/^newrelic\.license.*/newrelic.license = \"${NEWRELIC_LICENSE_KEY}\"/" "${newrelic_php_conf}"
fi

echo "Launching apache"
exec "${apache_dir}/bin/httpd" -DNO_DETACH
