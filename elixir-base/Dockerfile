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

FROM gcr.io/google-appengine/debian8

ARG ERLANG_PACKAGE_VERSION
ARG ELIXIR_PACKAGE_VERSION

# Install base packages and set up locale
RUN apt-get update -y \
    && apt-get -y upgrade \
    && apt-get install -y -q --no-install-recommends \
        apt-utils curl git locales \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen en_US.UTF-8

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en

# Install Erlang and Elixir
RUN curl -s https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb -o /tmp/erlang.deb \
    && dpkg -i /tmp/erlang.deb \
    && rm /tmp/erlang.deb \
    && apt-get update -y \
    && apt-get install -y -q --no-install-recommends erlang=${ERLANG_PACKAGE_VERSION} \
    && apt-get install -y -q --no-install-recommends elixir=${ELIXIR_PACKAGE_VERSION} \
    && apt-get clean \
    && rm -f /var/lib/apt/lists/*_* \
    && mix local.hex --force \
    && mix local.rebar --force

# Production environment
ENV MIX_ENV=prod

# Initialize entrypoint
WORKDIR /app
EXPOSE 8080
ENV PORT=8080
ENTRYPOINT []
CMD []
