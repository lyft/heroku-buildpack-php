#!/bin/sh

. ~/.profile.d/common.sh

# add apache binaries to the path
export PATH="${apache_dir}/bin:${PATH}"
