#!/bin/bash

set -e
set -x

arch="$(uname -m)"
vendor_dir="/app/vendor"
mkdir -p "${vendor_dir}"

function getSource() {
    local fileName="${1?filename is missing}"
    local sourcesBaseUrl="${SOURCES_BASE_URL?SOURCES_BASE_URL is missing}"
    curl --retry 5 -L -o "${fileName}" "${sourcesBaseUrl}/${fileName}"
}

# Build apache
apache_version="2.2.23"
echo "Building apache ${apache_version}"
apache_dir="${vendor_dir}/apache"
mkdir -p "${apache_dir}"
getSource "httpd-${apache_version}.tar.gz"
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
getSource "php-${php_version}.tar.gz"
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
    --with-iconv \
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
getSource "APC-${php_apc_version}.tgz"
tar xzf "./APC-${php_apc_version}.tgz"
pushd "APC-${php_apc_version}"
phpize
./configure
make
make install
popd

php_mongo_version="1.3.7"
echo "   mongo ${php_mongo_version}"
getSource "mongo-${php_mongo_version}.tgz"
gunzip "./mongo-${php_mongo_version}.tgz"
pecl install "./mongo-${php_mongo_version}.tar"

php_memcache_version="2.2.7"
echo "   memcache ${php_memcache_version}"
getSource "memcache-${php_memcache_version}.tgz"
gunzip "./memcache-${php_memcache_version}.tgz"
printf "yes\n" | pecl install "./memcache-${php_memcache_version}.tar"

# Build NewRelic
if [ "${arch}" == "x86_64" ]
then
    newrelic_arch="x64"
else
    echo "Unsupported newrelic arch: ${arch}"
    exit 1
fi
newrelic_dir="${vendor_dir}/newrelic"
mkdir "${newrelic_dir}"

#  php extension
php_newrelic_version="3.1.5.136"
echo "Building newrelic php extension ${php_newrelic_version}"
getSource "newrelic-php5-${php_newrelic_version}-linux.tar.gz"
tar xzf "./newrelic-php5-${php_newrelic_version}-linux.tar.gz"
pushd "newrelic-php5-${php_newrelic_version}-linux"
php_api=$(php -i | grep 'PHP Extension =' | cut -d'>' -f2 | sed 's/ //g')
if php -i | grep -q 'Thread Safety => disabled'
then
    php_zts=""
else
    php_zts="-zts"
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
