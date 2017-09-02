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

DEFAULT_ERLANG_PACKAGE="1:20.0-1"
DEFAULT_ELIXIR_PACKAGE="1.5.1-1"

PROJECT=
NAMESPACE="runtime"
IMAGE_TAG=
STAGING_FLAG=
UPLOAD_BUCKET=
ERLANG_PACKAGE=
ELIXIR_PACKAGE=
AUTO_YES=

show_usage() {
  echo "Usage: ./build.sh [-p <project>] [-n <image-namespace>]"
  echo "       [-t <image-tag>] [-i <base-image-tag>] [-b <upload-bucket>] [-s]" >&2
  echo "Flags:" >&2
  echo '  -b: set the gcs bucket to upload the cloudbuild pipeline to (defaults to no upload)' >&2
  echo '  -e: request a specific Erlang package version' >&2
  echo '  -n: set the images namespace (defaults to runtime)' >&2
  echo '  -p: set the images project (defaults to gcloud config)' >&2
  echo '  -s: also tag new images as staging' >&2
  echo '  -t: set the new images tag (defaults to creating a new tag)' >&2
  echo '  -x: request a specific Elixir package version' >&2
  echo '  -y: automatically confirm' >&2
}

OPTIND=1
while getopts ":b:e:n:p:st:x:yh" opt; do
  case $opt in
    b)
      UPLOAD_BUCKET=$OPTARG
      ;;
    e)
      ERLANG_PACKAGE=$OPTARG
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
    x)
      ELIXIR_PACKAGE=$OPTARG
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
if [ -z "$ERLANG_PACKAGE" ]; then
  ERLANG_PACKAGE=$DEFAULT_ERLANG_PACKAGE
  echo "Using default Erlang package version: $ERLANG_PACKAGE" >&2
fi
if [ -z "$ELIXIR_PACKAGE" ]; then
  ELIXIR_PACKAGE=$DEFAULT_ELIXIR_PACKAGE
  echo "Using default Elixir package version: $ELIXIR_PACKAGE" >&2
fi

echo "Building base, tools, and dockerfile generator images:"
echo "  gcr.io/$PROJECT/$NAMESPACE/base:$IMAGE_TAG"
echo "  gcr.io/$PROJECT/$NAMESPACE/build-tools:$IMAGE_TAG"
echo "  gcr.io/$PROJECT/$NAMESPACE/generate-dockerfile:$IMAGE_TAG"
if [ "$STAGING_FLAG" = "true" ]; then
  echo "and tagging them as staging."
else
  echo "but NOT tagging them as staging."
fi
if [ -n "$UPLOAD_BUCKET" ]; then
  echo "Also creating and uploading a new runtime config:"
  echo "  gs://$UPLOAD_BUCKET/elixir-$IMAGE_TAG.yaml"
  if [ "$STAGING_FLAG" = "true" ]; then
    echo "  gs://$UPLOAD_BUCKET/elixir-staging.yaml"
  else
    echo "but NOT promoting it to staging."
  fi
fi
if [ -z "$AUTO_YES" ]; then
  read -r -p "Ok to build? [Y/n] " response
  response=${response,,}  # tolower
  if [[ "$response" =~ ^(no|n)$ ]]; then
    echo "Aborting."
    exit 1
  fi
fi

gcloud container builds submit images \
  --config $DIRNAME/cloudbuild.yaml --project $PROJECT \
  --substitutions _TAG=$IMAGE_TAG,_NAMESPACE=$NAMESPACE,_ERLANG_PACKAGE=$ERLANG_PACKAGE,_ELIXIR_PACKAGE=$ELIXIR_PACKAGE
echo "**** Built image: gcr.io/$PROJECT/$NAMESPACE/base:$IMAGE_TAG"
echo "**** Built image: gcr.io/$PROJECT/$NAMESPACE/build-tools:$IMAGE_TAG"
echo "**** Built image: gcr.io/$PROJECT/$NAMESPACE/generate-dockerfile:$IMAGE_TAG"

if [ "$STAGING_FLAG" = "true" ]; then
  gcloud container images add-tag --project $PROJECT \
    gcr.io/$PROJECT/$NAMESPACE/base:$IMAGE_TAG \
    gcr.io/$PROJECT/$NAMESPACE/base:staging -q
  echo "**** Tagged image as gcr.io/$PROJECT/$NAMESPACE/base:staging"
  gcloud container images add-tag --project $PROJECT \
    gcr.io/$PROJECT/$NAMESPACE/build-tools:$IMAGE_TAG \
    gcr.io/$PROJECT/$NAMESPACE/build-tools:staging -q
  echo "**** Tagged image as gcr.io/$PROJECT/$NAMESPACE/build-tools:staging"
  gcloud container images add-tag --project $PROJECT \
    gcr.io/$PROJECT/$NAMESPACE/generate-dockerfile:$IMAGE_TAG \
    gcr.io/$PROJECT/$NAMESPACE/generate-dockerfile:staging -q
  echo "**** Tagged image as gcr.io/$PROJECT/$NAMESPACE/generate-dockerfile:staging"
fi

if [ -n "$UPLOAD_BUCKET" ]; then
  mkdir -p $DIRNAME/tmp
  sed -e "s|\$PROJECT|${PROJECT}|g; s|\$NAMESPACE|${NAMESPACE}|g; s|\$TAG|${IMAGE_TAG}|g" \
    < $DIRNAME/elixir.yaml.in > $DIRNAME/tmp/elixir-$IMAGE_TAG.yaml
  gsutil cp $DIRNAME/tmp/elixir-$IMAGE_TAG.yaml gs://$UPLOAD_BUCKET/elixir-$IMAGE_TAG.yaml
  echo "**** Created runtime config: gs://$UPLOAD_BUCKET/elixir-$IMAGE_TAG.yaml"
  if [ "$STAGING_FLAG" = "true" ]; then
    gsutil cp gs://$UPLOAD_BUCKET/elixir-$IMAGE_TAG.yaml gs://$UPLOAD_BUCKET/elixir-staging.yaml
    echo "**** Promoted runtime config gs://$UPLOAD_BUCKET/elixir-$IMAGE_TAG.yaml to gs://$UPLOAD_BUCKET/elixir-staging.yaml"
  fi
fi
