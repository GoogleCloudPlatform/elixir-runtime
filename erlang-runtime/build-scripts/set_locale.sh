#!/bin/bash

set -ex

# set locale
echo ${LANG} UTF-8 > /etc/locale.gen
locale-gen
dpkg-reconfigure locales

export LANG=${LANG}
export LANGUAGE=${LANG}
# export LC_ALL=${LANG}
