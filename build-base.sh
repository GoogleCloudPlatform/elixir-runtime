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
IMAGE_TAG="new"
STAGING_FLAG=

show_usage() {
  echo "Usage: ./build-base.sh [-p <project>] [-t <image-tag>] [-s]" >&2
  echo "Flags:" >&2
  echo '  -p: set the base image project (defaults to gcloud config)' >&2
  echo '  -t: set the base image tag (defaults to new)' >&2
  echo '  -s: also tag new image as staging' >&2
}

OPTIND=1
while getopts ":p:t:sh" opt; do
  case $opt in
    p)
      PROJECT=$OPTARG
      ;;
    t)
      IMAGE_TAG=$OPTARG
      ;;
    s)
      STAGING_FLAG="true"
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

if [ "$IMAGE_TAG" = "new" ]; then
  IMAGE_TAG=$(date +%Y-%m-%d-%H%M%S)
  echo "Creating new IMAGE_TAG: $IMAGE_TAG" >&2
fi

if [ -z "$PROJECT" ]; then
  PROJECT=$(gcloud config get-value project)
  echo "Using project from gcloud config: $PROJECT" >&2
fi

gcloud container builds submit images --config $DIRNAME/build-base.yaml \
  --project $PROJECT --substitutions _TAG=$IMAGE_TAG

if [ "$STAGING_FLAG" = "true" ]; then
  gcloud container images add-tag --project $PROJECT \
    gcr.io/$PROJECT/elixir:$IMAGE_TAG \
    gcr.io/$PROJECT/elixir:staging -q
fi
