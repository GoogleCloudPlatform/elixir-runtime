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
PREBUILT_ERLANG_VERSIONS=()
if [ -f ${DIRNAME}/erlang-versions.txt ]; then
  mapfile -t PREBUILT_ERLANG_VERSIONS < ${DIRNAME}/erlang-versions.txt
fi
DEFAULT_ERLANG_VERSION=20.1
DEFAULT_ELIXIR_VERSION=1.5.2-otp-20
BASE_IMAGE_DOCKERFILE=default
STAGING_FLAG=
UPLOAD_BUCKET=
AUTO_YES=

show_usage() {
  echo 'Usage: ./build.sh [flags...]' >&2
  echo 'Flags:' >&2
  echo '  -b <bucket>: upload a new runtime definition to this gcs bucket (defaults to no upload)' >&2
  echo '  -e <versions>: comma separated prebuilt erlang versions (defaults to erlang-versions.txt)' >&2
  echo '  -i: use prebuilt erlang to build base image' >&2
  echo '  -n <namespace>: set the images namespace (defaults to `elixir`)' >&2
  echo '  -p <project>: set the images project (defaults to current gcloud config setting)' >&2
  echo '  -s: also tag new images as `staging`' >&2
  echo '  -t <tag>: set the new image tag (creates a new tag if not provided)' >&2
  echo '  -y: automatically confirm' >&2
}

OPTIND=1
while getopts ":b:e:in:p:st:yh" opt; do
  case $opt in
    b)
      UPLOAD_BUCKET=$OPTARG
      ;;
    e)
      if [ "$OPTARG" = "none" ]; then
        PREBUILT_ERLANG_VERSIONS=()
      else
        IFS=',' read -r -a PREBUILT_ERLANG_VERSIONS <<< "$OPTARG"
      fi
      ;;
    i)
      BASE_IMAGE_DOCKERFILE="prebuilt"
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
COMMA_ERLANG_VERSIONS=$( IFS=, ; echo "${PREBUILT_ERLANG_VERSIONS[*]}" )

echo
echo "Building images:"
echo "  gcr.io/$PROJECT/$NAMESPACE/debian:$IMAGE_TAG"
echo "  gcr.io/$PROJECT/$NAMESPACE/asdf:$IMAGE_TAG"
echo "  gcr.io/$PROJECT/$NAMESPACE/base:$IMAGE_TAG"
echo "  gcr.io/$PROJECT/$NAMESPACE/builder:$IMAGE_TAG"
echo "  gcr.io/$PROJECT/$NAMESPACE/generate-dockerfile:$IMAGE_TAG"
if [ "$STAGING_FLAG" = "true" ]; then
  echo "and tagging them as staging."
else
  echo "but NOT tagging them as staging."
fi
echo "Base image uses $BASE_IMAGE_DOCKERFILE installation of Erlang."
if [ "${#PREBUILT_ERLANG_VERSIONS[@]}" = "0" ]; then
  echo "Dockerfile generator does not use any prebuilt Erlang images."
else
  echo "Dockerfile generator uses prebuilt Erlang images for versions:"
  echo "  $COMMA_ERLANG_VERSIONS"
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
echo

gcloud container builds submit $DIRNAME/elixir-debian \
  --config $DIRNAME/elixir-debian/cloudbuild.yaml --project $PROJECT \
  --substitutions _TAG=$IMAGE_TAG,_NAMESPACE=$NAMESPACE
echo "**** Built image: gcr.io/$PROJECT/$NAMESPACE/debian:$IMAGE_TAG"
if [ "$STAGING_FLAG" = "true" ]; then
  gcloud container images add-tag --project $PROJECT \
    gcr.io/$PROJECT/$NAMESPACE/debian:$IMAGE_TAG \
    gcr.io/$PROJECT/$NAMESPACE/debian:staging -q
  echo "**** Tagged image as gcr.io/$PROJECT/$NAMESPACE/debian:staging"
fi

gcloud container builds submit $DIRNAME/elixir-asdf \
  --config $DIRNAME/elixir-asdf/cloudbuild.yaml --project $PROJECT \
  --substitutions _TAG=$IMAGE_TAG,_NAMESPACE=$NAMESPACE
echo "**** Built image: gcr.io/$PROJECT/$NAMESPACE/asdf:$IMAGE_TAG"
if [ "$STAGING_FLAG" = "true" ]; then
  gcloud container images add-tag --project $PROJECT \
    gcr.io/$PROJECT/$NAMESPACE/asdf:$IMAGE_TAG \
    gcr.io/$PROJECT/$NAMESPACE/asdf:staging -q
  echo "**** Tagged image as gcr.io/$PROJECT/$NAMESPACE/asdf:staging"
fi

sed -e "s|\$PREBUILT_ERLANG_IMAGE|gcr.io/$PROJECT/$NAMESPACE/prebuilt/debian8/otp-${DEFAULT_ERLANG_VERSION}:latest|g" \
  < $DIRNAME/elixir-base/Dockerfile-${BASE_IMAGE_DOCKERFILE}.in > $DIRNAME/elixir-base/Dockerfile
gcloud container builds submit $DIRNAME/elixir-base \
  --config $DIRNAME/elixir-base/cloudbuild.yaml --project $PROJECT \
  --substitutions _TAG=$IMAGE_TAG,_NAMESPACE=$NAMESPACE,_ERLANG_VERSION=$DEFAULT_ERLANG_VERSION,_ELIXIR_VERSION=$DEFAULT_ELIXIR_VERSION
echo "**** Built image: gcr.io/$PROJECT/$NAMESPACE/base:$IMAGE_TAG"
if [ "$STAGING_FLAG" = "true" ]; then
  gcloud container images add-tag --project $PROJECT \
    gcr.io/$PROJECT/$NAMESPACE/base:$IMAGE_TAG \
    gcr.io/$PROJECT/$NAMESPACE/base:staging -q
  echo "**** Tagged image as gcr.io/$PROJECT/$NAMESPACE/base:staging"
fi

gcloud container builds submit $DIRNAME/elixir-builder \
  --config $DIRNAME/elixir-builder/cloudbuild.yaml --project $PROJECT \
  --substitutions _TAG=$IMAGE_TAG,_NAMESPACE=$NAMESPACE
echo "**** Built image: gcr.io/$PROJECT/$NAMESPACE/builder:$IMAGE_TAG"
if [ "$STAGING_FLAG" = "true" ]; then
  gcloud container images add-tag --project $PROJECT \
    gcr.io/$PROJECT/$NAMESPACE/builder:$IMAGE_TAG \
    gcr.io/$PROJECT/$NAMESPACE/builder:staging -q
  echo "**** Tagged image as gcr.io/$PROJECT/$NAMESPACE/builder:staging"
fi

gcloud container builds submit $DIRNAME/elixir-generate-dockerfile \
  --config $DIRNAME/elixir-generate-dockerfile/cloudbuild.yaml --project $PROJECT \
  --substitutions ^+^_TAG=$IMAGE_TAG+_NAMESPACE=$NAMESPACE+_PREBUILT_ERLANG_VERSIONS=$COMMA_ERLANG_VERSIONS+_DEFAULT_ERLANG_VERSION=$DEFAULT_ERLANG_VERSION+_DEFAULT_ELIXIR_VERSION=$DEFAULT_ELIXIR_VERSION
echo "**** Built image: gcr.io/$PROJECT/$NAMESPACE/generate-dockerfile:$IMAGE_TAG"
if [ "$STAGING_FLAG" = "true" ]; then
  gcloud container images add-tag --project $PROJECT \
    gcr.io/$PROJECT/$NAMESPACE/generate-dockerfile:$IMAGE_TAG \
    gcr.io/$PROJECT/$NAMESPACE/generate-dockerfile:staging -q
  echo "**** Tagged image as gcr.io/$PROJECT/$NAMESPACE/generate-dockerfile:staging"
fi

mkdir -p $DIRNAME/tmp
sed -e "s|\$PROJECT|${PROJECT}|g; s|\$NAMESPACE|${NAMESPACE}|g; s|\$TAG|${IMAGE_TAG}|g" \
  < $DIRNAME/elixir-pipeline/elixir.yaml.in > $DIRNAME/tmp/elixir-$IMAGE_TAG.yaml
echo "**** Created runtime config: $DIRNAME/tmp/elixir-$IMAGE_TAG.yaml"

if [ -n "$UPLOAD_BUCKET" ]; then
  gsutil cp $DIRNAME/tmp/elixir-$IMAGE_TAG.yaml gs://$UPLOAD_BUCKET/elixir-$IMAGE_TAG.yaml
  echo "**** Uploaded runtime config to gs://$UPLOAD_BUCKET/elixir-$IMAGE_TAG.yaml"
  if [ "$STAGING_FLAG" = "true" ]; then
    gsutil cp gs://$UPLOAD_BUCKET/elixir-$IMAGE_TAG.yaml gs://$UPLOAD_BUCKET/elixir-staging.yaml
    echo "**** Also promoted runtime config to gs://$UPLOAD_BUCKET/elixir-staging.yaml"
  fi
fi
