#!/bin/bash

set -ex

curl https://packages.erlang-solutions.com/erlang/elixir/FLAVOUR_2_download/elixir_${ELIXIR_VERSION}-1~debian~jessie_all.deb \
    -o /tmp/elixir.deb

dpkg -i /tmp/elixir.deb

rm /tmp/elixir.deb
