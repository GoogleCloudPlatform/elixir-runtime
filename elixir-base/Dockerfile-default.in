# Copyright 2017 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Base image for Elixir that includes a default Elixir installation.

FROM elixir-asdf

ARG erlang_version
ARG elixir_version

ENV DEFAULT_ERLANG_VERSION=${erlang_version} \
    DEFAULT_ELIXIR_VERSION=${elixir_version}

# Install Erlang and Elixir via asdf
RUN asdf install erlang ${erlang_version} \
    && asdf global erlang ${erlang_version} \
    && asdf install elixir ${elixir_version} \
    && asdf global elixir ${elixir_version} \
    && mix local.hex --force \
    && mix local.rebar --force
