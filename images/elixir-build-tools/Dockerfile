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

# Install build script files.
COPY app/ /app/

# Install NodeJS
RUN mkdir /app/nodejs \
    && curl -s https://nodejs.org/dist/v6.11.2/node-v6.11.2-linux-x64.tar.gz \
      | tar xzf - --directory=/app/nodejs --strip-components=1

# Install Yarn
RUN mkdir /app/yarn \
    && curl -s -L https://yarnpkg.com/latest.tar.gz \
      | tar xzf - --directory=/app/yarn --strip-components=1

# Install CloudSQL Proxy
RUN curl -s https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 \
      > /app/cloud_sql_proxy \
    && chmod a+x /app/cloud_sql_proxy


# Generate a minimal image with only the tool files themselves. This image
# can be downloaded quickly and the files copied into a build image.

FROM scratch

COPY --from=builder /app/ /build_tools/
