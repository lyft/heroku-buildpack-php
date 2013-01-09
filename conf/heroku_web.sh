vendor_dir="/app/vendor"
apache_dir="${vendor_dir}/apache"
php_dir="${vendor_dir}/php"

export LD_LIBRARY_PATH="${php_dir}/ext"

echo "Launching apache"
exec "${apache_dir}/bin/httpd" -DNO_DETACH
