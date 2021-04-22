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


DEFAULT_ERLANG_VERSION=22.3.4.17
DEFAULT_ELIXIR_VERSION=1.11.4-otp-22
OLD_DISTILLERY_ELIXIR_VERSION=1.8.2-otp-22
ASDF_VERSION=0.8.0
GCLOUD_VERSION=334.0.0
NODEJS_VERSION=14.16.1


set -e

DIRNAME=$(dirname $0)

OS_NAME=ubuntu18
PROJECT=
NAMESPACE=elixir
IMAGE_TAG=
BASE_IMAGE_DOCKERFILE=default
STAGING_FLAG=
UPLOAD_BUCKET=
AUTO_YES=
BUILD_TIMEOUT=60m
PREBUILT_IMAGE_TAG=latest
PREBUILT_ERLANG_VERSIONS=()
if [ -f ${DIRNAME}/erlang-versions.txt ]; then
  mapfile -t PREBUILT_ERLANG_VERSIONS < ${DIRNAME}/erlang-versions.txt
fi

show_usage() {
  echo 'Usage: ./runtime-build.sh [flags...]' >&2
  echo 'Flags:' >&2
  echo '  -b <bucket>: upload a new runtime definition to this gcs bucket (defaults to no upload)' >&2
  echo '  -e <versions>: comma separated prebuilt erlang versions (defaults to erlang-versions.txt)' >&2
  echo '  -i: use prebuilt erlang to build base image' >&2
  echo '  -n <namespace>: set the images namespace (defaults to `elixir`)' >&2
  echo '  -o <osname>: build against the given os base image (defaults to `ubuntu18`)' >&2
  echo '  -p <project>: set the images project (defaults to current gcloud config setting)' >&2
  echo '  -s: also tag new images as `staging`' >&2
  echo '  -t <tag>: set the new image tag (creates a new tag if not provided)' >&2
  echo '  -y: automatically confirm' >&2
}

OPTIND=1
while getopts ":b:e:in:p:st:yh" opt; do
  case ${opt} in
    b)
      UPLOAD_BUCKET=${OPTARG}
      ;;
    e)
      if [ "${OPTARG}" = "none" ]; then
        PREBUILT_ERLANG_VERSIONS=()
      else
        IFS=',' read -r -a PREBUILT_ERLANG_VERSIONS <<< "${OPTARG}"
      fi
      ;;
    i)
      BASE_IMAGE_DOCKERFILE="prebuilt"
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
    s)
      STAGING_FLAG="true"
      ;;
    t)
      IMAGE_TAG=${OPTARG}
      ;;
    y)
      AUTO_YES="true"
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

if [ -z "${PROJECT}" ]; then
  PROJECT=$(gcloud config get-value project)
  echo "Using project from gcloud config: ${PROJECT}" >&2
fi
if [ -z "${IMAGE_TAG}" ]; then
  IMAGE_TAG=$(date +%Y-%m-%d-%H%M%S)
  echo "Creating new IMAGE_TAG: ${IMAGE_TAG}" >&2
fi

OS_BASE_IMAGE=gcr.io/${PROJECT}/${NAMESPACE}/${OS_NAME}
ASDF_BASE_IMAGE=gcr.io/${PROJECT}/${NAMESPACE}/${OS_NAME}/asdf
ELIXIR_BASE_IMAGE=gcr.io/${PROJECT}/${NAMESPACE}/${OS_NAME}/base
BUILDER_IMAGE=gcr.io/${PROJECT}/${NAMESPACE}/${OS_NAME}/builder
GENERATE_DOCKERFILE_IMAGE=gcr.io/${PROJECT}/${NAMESPACE}/${OS_NAME}/generate-dockerfile
PREBUILT_IMAGE_PREFIX=gcr.io/${PROJECT}/${NAMESPACE}/${OS_NAME}/prebuilt/otp-

COMMA_ERLANG_VERSIONS=$( IFS=, ; echo "${PREBUILT_ERLANG_VERSIONS[*]}" )
PREBUILT_IMAGE_ARGS=
for version in "${PREBUILT_ERLANG_VERSIONS[@]}"; do
  tag=$(gcloud container images list-tags ${PREBUILT_IMAGE_PREFIX}${version} --filter=tags=${PREBUILT_IMAGE_TAG} --format="get(tags)" | sed -n 's|.*\([0-9]\{4\}-*[01][0-9]-*[0123][0-9][-_]*[0-9]\{6\}\).*|\1|p')
  if [ -z "${tag}" ]; then
    tag=${PREBUILT_IMAGE_TAG}
  fi
  echo "Tag for prebuilt erlang ${version}: ${tag}" >&2
  PREBUILT_IMAGE_ARGS="${PREBUILT_IMAGE_ARGS} '-p=${version}=${PREBUILT_IMAGE_PREFIX}${version}:${tag}',"
done

echo
echo "Building images:"
echo "  ${OS_BASE_IMAGE}:${IMAGE_TAG}"
echo "  ${ASDF_BASE_IMAGE}:${IMAGE_TAG}"
echo "  ${ELIXIR_BASE_IMAGE}:${IMAGE_TAG}"
echo "  ${BUILDER_IMAGE}:${IMAGE_TAG}"
echo "  ${GENERATE_DOCKERFILE_IMAGE}:${IMAGE_TAG}"
if [ "${STAGING_FLAG}" = "true" ]; then
  echo "and tagging them as staging."
else
  echo "but NOT tagging them as staging."
fi
echo "Base image uses ${BASE_IMAGE_DOCKERFILE} installation of Erlang."
if [ "${#PREBUILT_ERLANG_VERSIONS[@]}" = "0" ]; then
  echo "Dockerfile generator does not use any prebuilt Erlang images."
else
  echo "Dockerfile generator uses prebuilt Erlang images for versions:"
  echo "  ${COMMA_ERLANG_VERSIONS}"
  echo "with tag ${PREBUILT_IMAGE_TAG}"
fi
if [ -n "${UPLOAD_BUCKET}" ]; then
  echo "Also creating and uploading a new runtime config:"
  echo "  gs://${UPLOAD_BUCKET}/elixir-${IMAGE_TAG}.yaml"
  if [ "${STAGING_FLAG}" = "true" ]; then
    echo "  gs://${UPLOAD_BUCKET}/elixir-staging.yaml"
  else
    echo "but NOT promoting it to staging."
  fi
fi
if [ -z "${AUTO_YES}" ]; then
  read -r -p "Ok to build? [Y/n] " response
  response=${response,,}  # tolower
  if [[ "${response}" =~ ^(no|n)$ ]]; then
    echo "Aborting."
    exit 1
  fi
fi
echo

gcloud builds submit ${DIRNAME}/elixir-${OS_NAME} \
  --config ${DIRNAME}/elixir-${OS_NAME}/cloudbuild.yaml --project ${PROJECT} --timeout ${BUILD_TIMEOUT} \
  --substitutions _TAG=${IMAGE_TAG},_IMAGE=${OS_BASE_IMAGE}
echo "**** Built image: ${OS_BASE_IMAGE}:${IMAGE_TAG}"
if [ "${STAGING_FLAG}" = "true" ]; then
  gcloud container images add-tag --project ${PROJECT} \
    ${OS_BASE_IMAGE}:${IMAGE_TAG} ${OS_BASE_IMAGE}:staging -q
  echo "**** Tagged image as ${OS_BASE_IMAGE}:staging"
fi

gcloud builds submit ${DIRNAME}/elixir-asdf \
  --config ${DIRNAME}/elixir-asdf/cloudbuild.yaml --project ${PROJECT} --timeout ${BUILD_TIMEOUT} \
  --substitutions _TAG=${IMAGE_TAG},_OS_BASE_IMAGE=${OS_BASE_IMAGE},_IMAGE=${ASDF_BASE_IMAGE},_ASDF_VERSION=${ASDF_VERSION}
echo "**** Built image: ${ASDF_BASE_IMAGE}:${IMAGE_TAG}"
if [ "${STAGING_FLAG}" = "true" ]; then
  gcloud container images add-tag --project ${PROJECT} \
    ${ASDF_BASE_IMAGE}:$IMAGE_TAG ${ASDF_BASE_IMAGE}:staging -q
  echo "**** Tagged image as ${ASDF_BASE_IMAGE}:staging"
fi

sed -e "s|@@PREBUILT_ERLANG_IMAGE@@|${PREBUILT_IMAGE_PREFIX}${DEFAULT_ERLANG_VERSION}:latest|g" \
  < ${DIRNAME}/elixir-base/Dockerfile-${BASE_IMAGE_DOCKERFILE}.in > ${DIRNAME}/elixir-base/Dockerfile
gcloud builds submit ${DIRNAME}/elixir-base \
  --config ${DIRNAME}/elixir-base/cloudbuild.yaml --project ${PROJECT} --timeout ${BUILD_TIMEOUT} \
  --substitutions _TAG=${IMAGE_TAG},_ASDF_BASE_IMAGE=${ASDF_BASE_IMAGE},_IMAGE=${ELIXIR_BASE_IMAGE},_ERLANG_VERSION=${DEFAULT_ERLANG_VERSION},_ELIXIR_VERSION=${DEFAULT_ELIXIR_VERSION}
echo "**** Built image: ${ELIXIR_BASE_IMAGE}:${IMAGE_TAG}"
if [ "${STAGING_FLAG}" = "true" ]; then
  gcloud container images add-tag --project ${PROJECT} \
    ${ELIXIR_BASE_IMAGE}:${IMAGE_TAG} ${ELIXIR_BASE_IMAGE}:staging -q
  echo "**** Tagged image as ${ELIXIR_BASE_IMAGE}:staging"
fi

gcloud builds submit ${DIRNAME}/elixir-builder \
  --config ${DIRNAME}/elixir-builder/cloudbuild.yaml --project ${PROJECT} --timeout ${BUILD_TIMEOUT} \
  --substitutions _TAG=${IMAGE_TAG},_ASDF_BASE_IMAGE=${ASDF_BASE_IMAGE},_IMAGE=${BUILDER_IMAGE},_NODEJS_VERSION=${NODEJS_VERSION},_GCLOUD_VERSION=${GCLOUD_VERSION}
echo "**** Built image: ${BUILDER_IMAGE}:${IMAGE_TAG}"
if [ "${STAGING_FLAG}" = "true" ]; then
  gcloud container images add-tag --project ${PROJECT} \
    ${BUILDER_IMAGE}:${IMAGE_TAG} ${BUILDER_IMAGE}:staging -q
  echo "**** Tagged image as ${BUILDER_IMAGE}:staging"
fi

gcloud builds submit ${DIRNAME}/elixir-generate-dockerfile \
  --config ${DIRNAME}/elixir-generate-dockerfile/cloudbuild.yaml --project ${PROJECT} --timeout ${BUILD_TIMEOUT} \
  --substitutions _TAG=${IMAGE_TAG},_ELIXIR_BASE_IMAGE=${ELIXIR_BASE_IMAGE},_IMAGE=${GENERATE_DOCKERFILE_IMAGE}
echo "**** Built image: ${GENERATE_DOCKERFILE_IMAGE}:${IMAGE_TAG}"
if [ "${STAGING_FLAG}" = "true" ]; then
  gcloud container images add-tag --project ${PROJECT} \
    ${GENERATE_DOCKERFILE_IMAGE}:${IMAGE_TAG} ${GENERATE_DOCKERFILE_IMAGE}:staging -q
  echo "**** Tagged image as ${GENERATE_DOCKERFILE_IMAGE}:staging"
fi

mkdir -p ${DIRNAME}/tmp
sed -e "s|@@GENERATE_DOCKERFILE_IMAGE@@|${GENERATE_DOCKERFILE_IMAGE}|g;\
        s|@@OS_BASE_IMAGE@@|${OS_BASE_IMAGE}|g;\
        s|@@ASDF_BASE_IMAGE@@|${ASDF_BASE_IMAGE}|g;\
        s|@@BUILDER_IMAGE@@|${BUILDER_IMAGE}|g;\
        s|@@DEFAULT_ERLANG_VERSION@@|${DEFAULT_ERLANG_VERSION}|g;\
        s|@@DEFAULT_ELIXIR_VERSION@@|${DEFAULT_ELIXIR_VERSION}|g;\
        s|@@OLD_DISTILLERY_ELIXIR_VERSION@@|${OLD_DISTILLERY_ELIXIR_VERSION}|g;\
        s|@@TAG@@|${IMAGE_TAG}|g;\
        s|@@PREBUILT_IMAGE_ARGS@@|${PREBUILT_IMAGE_ARGS}|g" \
  < ${DIRNAME}/elixir-pipeline/elixir.yaml.in > ${DIRNAME}/tmp/elixir-${IMAGE_TAG}.yaml
echo "**** Created runtime config: ${DIRNAME}/tmp/elixir-${IMAGE_TAG}.yaml"

if [ -n "${UPLOAD_BUCKET}" ]; then
  gsutil cp ${DIRNAME}/tmp/elixir-${IMAGE_TAG}.yaml gs://${UPLOAD_BUCKET}/elixir-${IMAGE_TAG}.yaml
  echo "**** Uploaded runtime config to gs://${UPLOAD_BUCKET}/elixir-${IMAGE_TAG}.yaml"
  if [ "${STAGING_FLAG}" = "true" ]; then
    gsutil cp gs://${UPLOAD_BUCKET}/elixir-${IMAGE_TAG}.yaml gs://${UPLOAD_BUCKET}/elixir-staging.yaml
    echo "**** Also promoted runtime config to gs://${UPLOAD_BUCKET}/elixir-staging.yaml"
  fi
fi
