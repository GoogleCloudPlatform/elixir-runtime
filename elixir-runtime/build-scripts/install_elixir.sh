#!/bin/bash

set -ex

# https://packages.erlang-solutions.com/erlang/elixir/FLAVOUR_2_download/elixir_1.4.4-1~debian~jessie_amd64.deb
# https://packages.erlang-solutions.com/erlang/elixir/FLAVOUR_2_download/elixir_1.3.4-1~debian~jessie_amd64.deb
# https://packages.erlang-solutions.com/erlang/elixir/FLAVOUR_2_download/elixir_1.2.6-1~debian~jessie_amd64.deb
# https://packages.erlang-solutions.com/erlang/elixir/FLAVOUR_2_download/elixir_1.1.1-2~debian~jessie_amd64.deb

curl https://packages.erlang-solutions.com/erlang/elixir/FLAVOUR_2_download/elixir_${ELIXIR_VERSION}~debian~jessie_amd64.deb \
    -o /tmp/elixir.deb

dpkg -i /tmp/elixir.deb

rm /tmp/elixir.deb
