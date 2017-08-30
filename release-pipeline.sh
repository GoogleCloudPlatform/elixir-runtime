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
IMAGE_TAG="staging"
UPLOAD_BUCKET=

show_usage() {
  echo "Usage: ./release-pipeline.sh [-p <project>] [-t <image-tag>]" >&2
  echo "Flags:" >&2
  echo '  -p: set the build pipeline images project (defaults to gcloud config)' >&2
  echo '  -t: the image tag to release (defaults to staging)' >&2
  echo '  -b: set the gcs bucket to upload the cloudbuild pipeline to (defaults to no upload)' >&2
}

OPTIND=1
while getopts ":p:t:b:h" opt; do
  case $opt in
    p)
      PROJECT=$OPTARG
      ;;
    t)
      IMAGE_TAG=$OPTARG
      ;;
    b)
      UPLOAD_BUCKET=$OPTARG
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

gcloud container images add-tag --project $PROJECT \
  gcr.io/$PROJECT/elixir/build-tools:$IMAGE_TAG \
  gcr.io/$PROJECT/elixir/build-tools:latest -q
gcloud container images add-tag --project $PROJECT \
  gcr.io/$PROJECT/elixir/generate-dockerfile:$IMAGE_TAG \
  gcr.io/$PROJECT/elixir/generate-dockerfile:latest -q
echo "Tagged image gcr.io/$PROJECT/elixir/generate-dockerfile:$IMAGE_TAG as latest"

if [ -n "$UPLOAD_BUCKET" ]; then
  gsutil cp gs://$UPLOAD_BUCKET/elixir-$IMAGE_TAG.yaml gs://$UPLOAD_BUCKET/elixir.yaml
  echo "Promoted runtime config gs://$UPLOAD_BUCKET/elixir-$IMAGE_TAG.yaml to gs://$UPLOAD_BUCKET/elixir.yaml"
fi
