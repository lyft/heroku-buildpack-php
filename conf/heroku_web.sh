vendor_dir="/app/vendor"
apache_dir="${vendor_dir}/apache"
php_dir="${vendor_dir}/php"

touch "${apache_dir}/logs/error_log"
tail -F "${apache_dir}/logs/error_log" &
touch "${apache_dir}/logs/access_log"
tail -F "${apache_dir}/logs/access_log" &
export LD_LIBRARY_PATH="${php_dir}/ext"

echo "Launching apache"
exec "${apache_dir}/bin/httpd" -DNO_DETACH
