#!/bin/bash

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


set -e

DIRNAME=$(dirname $0)

OS_NAME=ubuntu18
PROJECT=
NAMESPACE=elixir
IMAGE_TAG=staging
PREBUILT_ERLANG_VERSIONS=()
if [ -f ${DIRNAME}/erlang-versions.txt ]; then
  mapfile -t PREBUILT_ERLANG_VERSIONS < ${DIRNAME}/erlang-versions.txt
fi

show_usage() {
  echo "Usage: ./erlang-release.sh [flags...]" >&2
  echo "Flags:" >&2
  echo '  -e <versions>: comma separated versions (defaults to erlang-versions.txt)' >&2
  echo '  -n <namespace>: set the images namespace (defaults to `elixir`)' >&2
  echo '  -o <osname>: build against the given os base image (defaults to `ubuntu18`)' >&2
  echo '  -p <project>: set the images project (defaults to current gcloud config setting)' >&2
  echo '  -t <tag>: the image tag to release (defaults to `staging`)' >&2
}

OPTIND=1
while getopts ":e:n:p:t:h" opt; do
  case ${opt} in
    e)
      if [ "${OPTARG}" = "none" ]; then
        PREBUILT_ERLANG_VERSIONS=()
      else
        IFS=',' read -r -a PREBUILT_ERLANG_VERSIONS <<< "${OPTARG}"
      fi
      ;;
    n)
      NAMESPACE=${OPTARG}
      ;;
    o)
      OS_NAME=${OPTARG}
      ;;
    p)
      PROJECT=${OPTARG}
      ;;
    t)
      IMAGE_TAG=${OPTARG}
      ;;
    h)
      show_usage
      exit 0
      ;;
    \?)
      echo "Invalid option: -${OPTARG}" >&2
      echo >&2
      show_usage
      exit 1
      ;;
    :)
      echo "Option ${OPTARG} requires a parameter" >&2
      echo >&2
      show_usage
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))

if [ "${#PREBUILT_ERLANG_VERSIONS[@]}" = "0" ]; then
  echo "No versions to release. Aborting."
  exit 1
fi

if [ -z "${PROJECT}" ]; then
  PROJECT=$(gcloud config get-value project)
  echo "**** Using project from gcloud config: ${PROJECT}" >&2
fi

PREBUILT_IMAGE_PREFIX=gcr.io/${PROJECT}/${NAMESPACE}/${OS_NAME}/prebuilt/otp-

for version in "${PREBUILT_ERLANG_VERSIONS[@]}"; do
  gcloud container images add-tag --project ${PROJECT} \
    ${PREBUILT_IMAGE_PREFIX}${version}:${IMAGE_TAG} \
    ${PREBUILT_IMAGE_PREFIX}${version}:latest -q
  echo "**** Tagged image ${PREBUILT_IMAGE_PREFIX}${version}:${IMAGE_TAG} as latest"
done
