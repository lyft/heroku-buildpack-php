#!/bin/sh

. ~/.profile.d/common.sh

# add php binaries to the path
export PATH="${php_dir}/bin:${PATH}"
# make sure php extensions can be found
export LD_LIBRARY_PATH="${php_dir}/ext:${LD_LIBRARY_PATH}"
