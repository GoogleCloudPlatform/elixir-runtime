#!/bin/bash

set -ex

# install erlang
curl https://packages.erlang-solutions.com/erlang/esl-erlang/FLAVOUR_1_general/esl-erlang_${ERLANG_VERSION}-1~debian~jessie_amd64.deb \
    -o /tmp/erlang.deb
dpkg -i /tmp/erlang.deb
rm /tmp/erlang.deb
