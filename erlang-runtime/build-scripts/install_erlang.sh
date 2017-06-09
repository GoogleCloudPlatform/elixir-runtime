#!/bin/bash

set -ex

# https://packages.erlang-solutions.com/erlang/esl-erlang/FLAVOUR_1_general/esl-erlang_19.3-1~debian~jessie_amd64.deb
# https://packages.erlang-solutions.com/erlang/esl-erlang/FLAVOUR_1_general/esl-erlang_19.2.3-1~debian~jessie_amd64.deb
# https://packages.erlang-solutions.com/erlang/esl-erlang/FLAVOUR_1_general/esl-erlang_19.1.5-1~debian~jessie_amd64.deb
# https://packages.erlang-solutions.com/erlang/esl-erlang/FLAVOUR_1_general/esl-erlang_19.0.7-1~debian~jessie_amd64.deb

# install erlang
curl https://packages.erlang-solutions.com/erlang/esl-erlang/FLAVOUR_1_general/esl-erlang_${ERLANG_VERSION}~debian~jessie_amd64.deb \
    -o /tmp/erlang.deb
dpkg -i /tmp/erlang.deb
rm /tmp/erlang.deb
