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

PROJECT=
NAMESPACE="elixir"
IMAGE_TAG=
ASDF_IMAGE_TAG=staging
PREBUILT_ERLANG_VERSIONS=()
if [ -f ${DIRNAME}/erlang-versions.txt ]; then
  mapfile -t PREBUILT_ERLANG_VERSIONS < ${DIRNAME}/erlang-versions.txt
fi
STAGING_FLAG=
AUTO_YES=

show_usage() {
  echo 'Usage: ./erlang-build.sh [flags...]' >&2
  echo 'Flags:' >&2
  echo '  -a <tag>: use this asdf image tag (defaults to `staging`)' >&2
  echo '  -e <versions>: comma separated versions (defaults to erlang-versions.txt)' >&2
  echo '  -n <namespace>: set the images namespace (defaults to `elixir`)' >&2
  echo '  -p <project>: set the images project (defaults to current gcloud config setting)' >&2
  echo '  -s: also tag new images as `staging`' >&2
  echo '  -t <tag>: set the new image tag (creates a new tag if not provided)' >&2
  echo '  -y: automatically confirm' >&2
}

OPTIND=1
while getopts ":a:e:n:p:st:yh" opt; do
  case $opt in
    a)
      ASDF_IMAGE_TAG=$OPTARG
      ;;
    e)
      if [ "$OPTARG" = "none" ]; then
        PREBUILT_ERLANG_VERSIONS=()
      else
        IFS=',' read -r -a PREBUILT_ERLANG_VERSIONS <<< "$OPTARG"
      fi
      ;;
    n)
      NAMESPACE=$OPTARG
      ;;
    p)
      PROJECT=$OPTARG
      ;;
    s)
      STAGING_FLAG="true"
      ;;
    t)
      IMAGE_TAG=$OPTARG
      ;;
    y)
      AUTO_YES="true"
      ;;
    h)
      show_usage
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      echo >&2
      show_usage
      exit 1
      ;;
    :)
      echo "Option $OPTARG requires a parameter" >&2
      echo >&2
      show_usage
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))

if [ -z "$PROJECT" ]; then
  PROJECT=$(gcloud config get-value project)
  echo "Using project from gcloud config: $PROJECT" >&2
fi
if [ -z "$IMAGE_TAG" ]; then
  IMAGE_TAG=$(date +%Y-%m-%d-%H%M%S)
  echo "Creating new IMAGE_TAG: $IMAGE_TAG" >&2
fi

if [ "${#ArrayName[@]}" = "0" ]; then
  echo "No versions to build. Aborting."
  exit 1
fi

echo
echo "Using gcr.io/$PROJECT/$NAMESPACE/asdf:$ASDF_IMAGE_TAG"
echo "Building images:"
for version in "${PREBUILT_ERLANG_VERSIONS[@]}"; do
  echo "  gcr.io/$PROJECT/$NAMESPACE/prebuilt/debian8/otp-${version}:$IMAGE_TAG"
done
if [ "$STAGING_FLAG" = "true" ]; then
  echo "and tagging them as staging."
else
  echo "but NOT tagging them as staging."
fi
if [ -z "$AUTO_YES" ]; then
  read -r -p "Ok to build? [Y/n] " response
  response=${response,,}  # tolower
  if [[ "$response" =~ ^(no|n)$ ]]; then
    echo "Aborting."
    exit 1
  fi
fi
echo

for version in "${PREBUILT_ERLANG_VERSIONS[@]}"; do
  gcloud container builds submit $DIRNAME/elixir-prebuilt-erlang \
    --config $DIRNAME/elixir-prebuilt-erlang/cloudbuild.yaml --project $PROJECT \
    --substitutions _TAG=$IMAGE_TAG,_NAMESPACE=$NAMESPACE,_ASDF_TAG=$ASDF_IMAGE_TAG,_ERLANG_VERSION=$version
  echo "**** Built image: gcr.io/$PROJECT/$NAMESPACE/prebuilt/debian8/otp-${version}:$IMAGE_TAG"
  if [ "$STAGING_FLAG" = "true" ]; then
    gcloud container images add-tag --project $PROJECT \
      gcr.io/$PROJECT/$NAMESPACE/prebuilt/debian8/otp-${version}:$IMAGE_TAG \
      gcr.io/$PROJECT/$NAMESPACE/prebuilt/debian8/otp-${version}:staging -q
    echo "**** Tagged image as gcr.io/$PROJECT/$NAMESPACE/prebuilt/debian8/otp-${version}:staging"
  fi
done
