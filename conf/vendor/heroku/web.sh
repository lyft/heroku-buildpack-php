set -e

. ~/.profile.d/common.sh

echo "Launching apache"
exec "${apache_dir}/bin/httpd" -D FOREGROUND
