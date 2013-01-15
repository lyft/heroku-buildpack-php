#!/bin/sh

. ~/.profile.d/common.sh

# add php binaries to the path
export PATH="${php_dir}/bin:${PATH}"

tailFile "${php_dir}/php_errors.log" php-errors
export LD_LIBRARY_PATH="${php_dir}/ext:${LD_LIBRARY_PATH}"
