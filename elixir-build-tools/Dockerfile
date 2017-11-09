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


# Working image, downloads all the tools into the /app directory.

# Use the base image as a tool to download things.
FROM elixir-base AS builder

# Versions
ARG NODEJS_VERSION=8.9.1
ARG GCLOUD_VERSION=179.0.0

# Install build script files.
RUN mkdir /build_tools
WORKDIR /build_tools
COPY access_cloud_sql /build_tools/

# Install NodeJS
RUN mkdir /build_tools/nodejs \
    && curl -s https://nodejs.org/dist/v${NODEJS_VERSION}/node-v${NODEJS_VERSION}-linux-x64.tar.gz \
      | tar xzf - --directory=/build_tools/nodejs --strip-components=1

# Install Yarn
RUN mkdir /build_tools/yarn \
    && curl -s -L https://yarnpkg.com/latest.tar.gz \
      | tar xzf - --directory=/build_tools/yarn --strip-components=1

# Install CloudSQL Proxy
RUN curl -s https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 \
      > /build_tools/cloud_sql_proxy \
    && chmod a+x /build_tools/cloud_sql_proxy

# Install Google Cloud SDK
RUN curl -s https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_VERSION}-linux-x86_64.tar.gz \
      > google-cloud-sdk.tar.gz \
    && tar xzf google-cloud-sdk.tar.gz \
    && rm google-cloud-sdk.tar.gz


# Generate a minimal image with only the tool files themselves. This image
# can be downloaded quickly and the files copied into a build image.

FROM scratch

COPY --from=builder /build_tools/ /build_tools/
