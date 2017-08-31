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
BASE_IMAGE_PROJECT=
BASE_IMAGE_TAG="staging"
IMAGE_TAG="same"
STAGING_FLAG=
UPLOAD_BUCKET=

show_usage() {
  echo "Usage: ./build-pipeline.sh [-p <project>] [-q <base-image-project>]"
  echo "       [-t <image-tag>] [-i <base-image-tag>] [-b <upload-bucket>] [-s]" >&2
  echo "Flags:" >&2
  echo '  -p: set the build pipeline images project (defaults to gcloud config)' >&2
  echo '  -q: set the base image project (defaults to same as build pipeline project)' >&2
  echo '  -i: set the base image tag (defaults to staging)' >&2
  echo '  -t: set the new images tag (defaults to same)' >&2
  echo '  -b: set the gcs bucket to upload the cloudbuild pipeline to (defaults to no upload)' >&2
  echo '  -s: also tag new images as staging' >&2
}

OPTIND=1
while getopts ":p:q:i:t:sb:h" opt; do
  case $opt in
    p)
      PROJECT=$OPTARG
      ;;
    q)
      BASE_IMAGE_PROJECT=$OPTARG
      ;;
    i)
      BASE_IMAGE_TAG=$OPTARG
      ;;
    t)
      IMAGE_TAG=$OPTARG
      ;;
    s)
      STAGING_FLAG="true"
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

if [ -z "$BASE_IMAGE_PROJECT" ]; then
  BASE_IMAGE_PROJECT=$PROJECT
fi

if [ "$BASE_IMAGE_TAG" = "staging" -o "$BASE_IMAGE_TAG" = "latest" ]; then
  SYMBOL=$BASE_IMAGE_TAG
  BASE_IMAGE_TAG=$(gcloud container images list-tags gcr.io/$BASE_IMAGE_PROJECT/elixir --filter=tags=$BASE_IMAGE_TAG --format="get(tags)" | sed -n 's|.*\([0-9]\{4\}-*[01][0-9]-*[0123][0-9][-_]*[0-9]\{6\}\).*|\1|p')
  echo "Setting BASE_IMAGE_TAG to ${SYMBOL}: $BASE_IMAGE_TAG" >&2
fi

if [ "$IMAGE_TAG" = "new" ]; then
  IMAGE_TAG=$(date +%Y-%m-%d-%H%M%S)
  echo "Creating new IMAGE_TAG: $IMAGE_TAG" >&2
fi
if [ "$IMAGE_TAG" = "same" ]; then
  IMAGE_TAG=$BASE_IMAGE_TAG
  echo "Setting IMAGE_TAG to $IMAGE_TAG (same as base image tag)" >&2
fi

gcloud container builds submit images \
  --config $DIRNAME/build-pipeline.yaml --project $PROJECT \
  --substitutions _TAG=$IMAGE_TAG,_BASE_TAG=$BASE_IMAGE_TAG,_BASE_PROJECT_ID=$BASE_IMAGE_PROJECT
echo "Built image: gcr.io/$PROJECT/elixir/generate-dockerfile:$IMAGE_TAG"

if [ "$STAGING_FLAG" = "true" ]; then
  gcloud container images add-tag --project $PROJECT \
    gcr.io/$PROJECT/elixir/build-tools:$IMAGE_TAG \
    gcr.io/$PROJECT/elixir/build-tools:staging -q
  gcloud container images add-tag --project $PROJECT \
    gcr.io/$PROJECT/elixir/generate-dockerfile:$IMAGE_TAG \
    gcr.io/$PROJECT/elixir/generate-dockerfile:staging -q
  echo "Tagged image as gcr.io/$PROJECT/elixir/generate-dockerfile:staging"
fi

if [ -n "$UPLOAD_BUCKET" ]; then
  mkdir -p $DIRNAME/tmp
  sed -e "s|\$PROJECT|${PROJECT}|g; s|\$TAG|${IMAGE_TAG}|g" \
    < $DIRNAME/elixir.yaml.in > $DIRNAME/tmp/elixir-$IMAGE_TAG.yaml
  gsutil cp $DIRNAME/tmp/elixir-$IMAGE_TAG.yaml gs://$UPLOAD_BUCKET/elixir-$IMAGE_TAG.yaml
  echo "Created runtime config: gs://$UPLOAD_BUCKET/elixir-$IMAGE_TAG.yaml"
  if [ "$STAGING_FLAG" = "true" ]; then
    gsutil cp gs://$UPLOAD_BUCKET/elixir-$IMAGE_TAG.yaml gs://$UPLOAD_BUCKET/elixir-staging.yaml
    echo "Set staging runtime config: gs://$UPLOAD_BUCKET/elixir-staging.yaml"
  fi
fi
