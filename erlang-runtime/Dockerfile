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

# Dockerfile for Running Erlang

FROM gcr.io/google-appengine/debian8

RUN apt-get update -y && \
    apt-get -y upgrade && \
    apt-get install -y --no-install-recommends \
        curl \
        gettext \
        git \
        locales \
        libsctp1 \
        libwxgtk3.0-0 \
        libwxbase3.0-0

ARG ERLANG_VERSION="19.3"
ARG LANG=en_US.UTF-8

ENV ERLANG_VERSION=$ERLANG_VERSION \
    LANG=$LANG

COPY build-scripts /build-scripts
RUN /build-scripts/install_erlang.sh && \
    /build-scripts/set_locale.sh
