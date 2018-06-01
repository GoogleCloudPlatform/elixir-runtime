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


# Builder image.

FROM elixir-asdf

# Parameters
ARG nodejs_version
ARG gcloud_version

ARG nodejs_dir=/opt/nodejs
ARG gcloud_dir=/opt/gcloud
ARG misc_bin_dir=/opt/bin

# Install python which is necessary for gcloud
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y \
    && apt-get install -y -q python2.7 \
    && apt-get clean \
    && rm -f /var/lib/apt/lists/*_*

# Install build script files.
RUN mkdir -p ${misc_bin_dir}
COPY access_cloud_sql ${misc_bin_dir}/

# Install NodeJS
RUN mkdir -p ${nodejs_dir} \
    && curl -s https://nodejs.org/dist/v${nodejs_version}/node-v${nodejs_version}-linux-x64.tar.gz \
      | tar xzf - --directory=${nodejs_dir} --strip-components=1

# Install CloudSQL Proxy
RUN curl -s https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 > /opt/bin/cloud_sql_proxy \
    && chmod a+x /opt/bin/cloud_sql_proxy \
    && mkdir /cloudsql

# Install Google Cloud SDK
RUN mkdir -p ${gcloud_dir} \
    && curl -s https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${gcloud_version}-linux-x86_64.tar.gz \
      | tar xzf - --directory=${gcloud_dir} --strip-components=1

ENV PATH=${misc_bin_dir}:${nodejs_dir}/bin:${gcloud_dir}/bin:${PATH}
