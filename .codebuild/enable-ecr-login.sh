#!/usr/bin/env bash

set -e

# Needed for ARM_CONTAINER types until the following code change is released:
# https://github.com/aws/aws-codebuild-docker-images/pull/483
if ! type docker-credential-ecr-login >/dev/null 2>&1; then

  printf "\nAmazon ECR Docker Credential Helper not found!\n\n"

  # Because CodeBuild AL2 images default to Python3 you need to
  # set Python2 when calling `amazon-linux-extras`.
  PYTHON=python2 /usr/bin/amazon-linux-extras enable docker
  yum install amazon-ecr-credential-helper -y
fi

DOCKER_CONFIG_DIR="${HOME}/.docker"
DOCKER_CONFIG_FILE="${DOCKER_CONFIG_DIR}/config.json"

mkdir -p "${DOCKER_CONFIG_DIR}"
if [[ ! -s "${DOCKER_CONFIG_FILE}" ]]; then
  jq -n '{}' > "${DOCKER_CONFIG_FILE}"
fi

ECR_REGISTRY_URIS=("public.ecr.aws")

if [[ "${REGISTRY_URI}" =~ ^[0-9]+\.dkr\.ecr\.[a-z]{2}-[a-z]+-[0-9]\.amazonaws\.com$ ]]; then
  ECR_REGISTRY_URIS+=("${REGISTRY_URI}")
fi

for registry in "${ECR_REGISTRY_URIS[@]}"; do
  jq -e --arg registry "${registry}" '.credHelpers |= . + {"\($registry)":"ecr-login"}' \
    "${DOCKER_CONFIG_FILE}" > "${DOCKER_CONFIG_FILE}.tmp"
  mv "${DOCKER_CONFIG_FILE}.tmp" "${DOCKER_CONFIG_FILE}"
done
