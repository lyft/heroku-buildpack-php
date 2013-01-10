#!/bin/bash

set -e
set -x

arch="$(uname -m)"
sourcesBaseUrl="${SOURCES_BASE_URL?SOURCES_BASE_URL is missing}"
vendor_dir="/app/vendor"
mkdir -p "${vendor_dir}"

# Build apache
apache_version="2.2.23"
echo "Building apache ${apache_version}"
apache_dir="${vendor_dir}/apache"
mkdir -p "${apache_dir}"
curl -L -o "httpd-${apache_version}.tar.gz" \
           "${sourcesBaseUrl}/httpd-${apache_version}.tar.gz"
tar xzf "httpd-${apache_version}.tar.gz"
pushd "httpd-${apache_version}/"
# Keep the configuration options in alphabetical order
# Keep the list of modules in alphabetical order
./configure \
    --disable-actions \
    --disable-cgi \
    --disable-userdir \
    --enable-modules="deflate headers logio rewrite unique-id" \
    --prefix="${apache_dir}" \
    --with-mpm=prefork
make install
# Make sure relevant apache binaries are available in the path
export PATH="${apache_dir}/bin:${PATH}"
echo "${apache_dir}/bin" >> ${vendor_dir}/environment.paths
popd

# Build php
php_version="5.3.20"
echo "Building php ${php_version}"
php_dir="${vendor_dir}/php"
mkdir -p "${php_dir}"
curl -L -o "php-${php_version}.tar.gz" \
           "${sourcesBaseUrl}/php-${php_version}.tar.gz"
tar xzf "php-${php_version}.tar.gz"
pushd "php-${php_version}/"
# Keep the configuration options in alphabetical order
./configure \
    --disable-all \
    --disable-debug \
    --enable-ctype \
    --enable-dom \
    --enable-filter \
    --enable-hash \
    --enable-inline-optimization \
    --enable-json \
    --enable-libxml \
    --enable-phar \
    --enable-posix \
    --enable-reflection \
    --enable-session \
    --enable-simplexml \
    --enable-spl \
    --enable-xml \
    --enable-xmlreader \
    --enable-xmlwriter \
    --prefix="${php_dir}" \
    --with-apxs2="${apache_dir}/bin/apxs" \
    --with-config-file-path="${php_dir}/etc/" \
    --with-config-file-scan-dir="${php_dir}/etc/ext.d/" \
    --with-curl \
    --with-openssl \
    --with-pcre-regex \
    --with-pear \
    --with-readline \
    --with-zlib
make
make install
cp php.ini-* "${php_dir}/etc/"
# Make sure relevant php binaries are available in the path
export PATH="${php_dir}/bin:${PATH}"
echo "${php_dir}/bin" >> ${vendor_dir}/environment.paths
popd

# Build php extensions
echo "Building php extensions"
php_extension_dir="$(php -i | grep 'extension_dir' | cut -d'>' -f3 | sed 's/ //g')"

php_apc_version="3.1.9"
echo "   apc ${php_apc_version}"
curl -L -o "APC-${php_apc_version}.tgz" \
           "${sourcesBaseUrl}/APC-${php_apc_version}.tgz"
tar xzf "./APC-${php_apc_version}.tgz"
pushd "APC-${php_apc_version}"
phpize
./configure
make
make install
popd

php_mongo_version="1.3.2"
echo "   mongo ${php_mongo_version}"
curl -L -o "mongo-${php_mongo_version}.tgz" \
           "${sourcesBaseUrl}/mongo-${php_mongo_version}.tgz"
gunzip "./mongo-${php_mongo_version}.tgz"
pecl install "./mongo-${php_mongo_version}.tar"

php_newrelic_version="3.1.5.136"
echo "   newrelic ${php_newrelic_version}"
curl -L -o "newrelic-php5-${php_newrelic_version}-linux.tar.gz" \
           "${sourcesBaseUrl}/newrelic-php5-${php_newrelic_version}-linux.tar.gz"
tar xzf "./newrelic-php5-${php_newrelic_version}-linux.tar.gz"
pushd "newrelic-php5-${php_newrelic_version}-linux"
php_api=$(php -i | grep 'PHP Extension =' | cut -d'>' -f2 | sed 's/ //g')
if php -i | grep -q 'Thread Safety => disabled'
then
    php_zts=""
else
    php_zts="-zts"
fi
if [ "${arch}" == "x86_64" ]
then
    newrelic_arch="x64"
else
    echo "Unsupported newrelic arch: ${arch}"
    exit 1
fi
cp "agent/${newrelic_arch}/newrelic-${php_api}${php_zts}.so" "${php_extension_dir}/newrelic.so"
newrelic_daemon_dir="${vendor_dir}/newrelic/"
mkdir -p "${newrelic_daemon_dir}"
cp "daemon/newrelic-daemon.${newrelic_arch}" "${newrelic_daemon_dir}/newrelic-daemon"
popd

# Clean up build artifacts
echo "Cleaning up build"
mv "${apache_dir}/conf/httpd.conf" "${apache_dir}/conf/httpd.conf-dist"
rm -rf "${apache_dir}/manual"
rm -rf "${apache_dir}/include"
find "${apache_dir}/lib" -name "*.a" -exec 'rm' '{}' ';'
find "${apache_dir}/lib" -name "*.la" -exec 'rm' '{}' ';'
rm -rf "${php_dir}/include"

echo "Build completed"
