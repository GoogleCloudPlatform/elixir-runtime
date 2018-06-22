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


# Debian plus asdf for installing and managing ERTS and Elixir.
# Does not include any actual installations of ERTS or Elixir.

FROM elixir-os

ARG asdf_dir=/opt/asdf
ARG asdf_version

# Install prerequisites for building Erlang and Elixir
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y \
    && apt-get install -y -q --no-install-recommends \
        autoconf \
        automake \
        build-essential \
        curl \
        fop \
        git \
        libncurses-dev \
        libreadline-dev \
        libssl-dev \
        unixodbc-dev \
        unzip \
        xsltproc \
    && apt-get clean \
    && rm -f /var/lib/apt/lists/*_*

# Install Elixir and Erlang via asdf
ENV ASDF_DIR=${asdf_dir} \
    PATH=${asdf_dir}/bin:${asdf_dir}/shims:${PATH}
RUN mkdir -p ${asdf_dir} \
    && git clone https://github.com/asdf-vm/asdf.git ${asdf_dir} --branch v${asdf_version} \
    && asdf plugin-add erlang \
    && asdf plugin-add elixir
