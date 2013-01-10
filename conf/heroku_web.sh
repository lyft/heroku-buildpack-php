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

echo "Launching apache"
exec "${apache_dir}/bin/httpd" -DNO_DETACH
