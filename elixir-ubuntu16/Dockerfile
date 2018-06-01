# Copyright 2018 Google LLC
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


# Basic Ubuntu environment for running Elixir web apps.
# Installs dependencies, and sets up locale and environment variables.
# Does not include ERTS or Elixir, however.

FROM gcr.io/gcp-runtimes/ubuntu_16_0_4

# Install key dependencies including locale
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y \
    && apt-get -y upgrade \
    && apt-get install -y -q --no-install-recommends \
        apt-utils \
        locales \
        tzdata \
        unixodbc \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && apt-get clean \
    && rm -f /var/lib/apt/lists/*_*

# Set locale and other elements of the production environment
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    MIX_ENV=prod \
    REPLACE_OS_VARS=true \
    TERM=xterm \
    PORT=8080

# Initialize entrypoint
WORKDIR /app
EXPOSE 8080
ENTRYPOINT []
CMD []
