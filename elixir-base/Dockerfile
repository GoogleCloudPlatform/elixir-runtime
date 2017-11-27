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


# Base image for Elixir

FROM elixir-debian

ARG default_erlang_version=20.1
ARG default_elixir_version=1.5.2-otp-20
ARG asdf_dir=/opt/asdf
ARG asdf_version=0.4.0

# Install prerequisites for building Erlang and Elixir
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y \
    && apt-get install -y -q --no-install-recommends \
        autoconf \
        build-essential \
        curl \
        git \
        libncurses-dev \
        libreadline-dev \
        libssl-dev \
        unixodbc-dev \
        unzip \
    && apt-get clean \
    && rm -f /var/lib/apt/lists/*_*

# Install Elixir and Erlang via asdf
ENV DEFAULT_ERLANG_VERSION=${default_erlang_version} \
    DEFAULT_ELIXIR_VERSION=${default_elixir_version} \
    ASDF_DIR=${asdf_dir} \
    PATH=${asdf_dir}/bin:${asdf_dir}/shims:${PATH}
RUN mkdir -p ${asdf_dir} \
    && git clone https://github.com/asdf-vm/asdf.git ${asdf_dir} --branch v${asdf_version} \
    && asdf plugin-add erlang \
    && asdf plugin-add elixir \
    && asdf install erlang ${default_erlang_version} \
    && asdf install elixir ${default_elixir_version} \
    && asdf global erlang ${default_erlang_version} \
    && asdf global elixir ${default_elixir_version} \
    && mix local.hex --force \
    && mix local.rebar --force

# Production environment
ENV MIX_ENV=prod \
    REPLACE_OS_VARS=true \
    TERM=xterm

# Initialize entrypoint
WORKDIR /app
EXPOSE 8080
ENV PORT=8080
ENTRYPOINT []
CMD []
