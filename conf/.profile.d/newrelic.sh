#!/bin/sh

. ~/.profile.d/common.sh

if [ "${NEW_RELIC_LICENSE_KEY}" != "" ]
then
    # Setup newrelic php extension
    # NB: the newrelic daemon will automatically be started by the php extension
    newrelic_php_conf="${php_dir}/etc/ext.d/newrelic.ini"
    tailFile "${newrelic_dir}/newrelic-daemon.log" newrelic-daemon
    tailFile "${newrelic_dir}/php_agent.log" newrelic-php-agent
    sed -i -e "s/^newrelic\.enabled.*/newrelic.enabled = true/" "${newrelic_php_conf}"
    sed -i -e "s/^newrelic\.license.*/newrelic.license = \"${NEW_RELIC_LICENSE_KEY}\"/" "${newrelic_php_conf}"
    if [ "${NEW_RELIC_APP_NAME}" != "" ]
    then
        sed -i -e "s/^newrelic\.appname.*/newrelic.appname = \"${NEW_RELIC_APP_NAME}\"/" "${newrelic_php_conf}"
    fi
fi
