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


# Use the Elixir base image for building.
FROM elixir-base

# Build the Dockerfile generation script
COPY src/ /src/
RUN cd /src \
    && mix deps.get \
    && mix escript.build


# Use the Elixir base image again for the generator runtime.
FROM elixir-base

ARG os_image=""
ARG asdf_image=""
ARG builder_image=""
ARG prebuilt_erlang_images=""
ARG default_erlang_version=""
ARG default_elixir_version=""

ENV DEFAULT_OS_IMAGE=${os_image} \
    DEFAULT_ASDF_IMAGE=${asdf_image} \
    DEFAULT_BUILDER_IMAGE=${builder_image} \
    DEFAULT_PREBUILT_ERLANG_IMAGES=${prebuilt_erlang_images} \
    DEFAULT_ERLANG_VERSION=${default_erlang_version} \
    DEFAULT_ELIXIR_VERSION=${default_elixir_version}

# Install the wrapper script and templates.
COPY app/ /app/

# Copy the built generate_dockerfile escript
COPY --from=0 /src/generate_dockerfile /app/generate_dockerfile

# The entry point runs the generation script.
ENTRYPOINT ["/app/generate_dockerfile.sh"]
