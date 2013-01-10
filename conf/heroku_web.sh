set -e

vendor_dir="/app/vendor"
apache_dir="${vendor_dir}/apache"
php_dir="${vendor_dir}/php"

# tailFile filename [prefix]
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
    echo -n "Enabling NewRelic.."
    newrelic_dir="${vendor_dir}/newrelic"
    # Setup newrelic php extension
    # NB: the newrelic daemon will automatically be started by the php extension
    newrelic_php_conf="${php_dir}/etc/ext.d/newrelic.ini"
    tailFile "${newrelic_dir}/newrelic-daemon.log" newrelic-daemon
    tailFile "${newrelic_dir}/php_agent.log" newrelic-php-agent
    sed -i -e "s/^newrelic\.enabled.*/newrelic.enabled = true/" "${newrelic_php_conf}"
    sed -i -e "s/^newrelic\.license.*/newrelic.license = \"${NEWRELIC_LICENSE_KEY}\"/" "${newrelic_php_conf}"
    echo -n " php.."
    # Setup newrelic system monitoring
    #
    # Disable nrsysmond for now. An error is printed:
    #   [29/timer] error: IA/FSLIST failed
    # 
    #newrelic_nrsysmond_cfg="${newrelic_dir}/nrsysmond.cfg"
    #tailFile "${newrelic_dir}/nrsysmond.log" newrelic-nrsysmond
    #sed -i -e "s/^license_key.*/license_key=\"${NEWRELIC_LICENSE_KEY}\"/" "${newrelic_nrsysmond_cfg}"
    #"${newrelic_dir}/nrsysmond" -c "${newrelic_nrsysmond_cfg}"
    #echo -n " nrsysmond.."
    echo " Done!"
fi

echo "Launching apache"
exec "${apache_dir}/bin/httpd" -DNO_DETACH
