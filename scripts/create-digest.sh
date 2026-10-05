#!/bin/bash
SCRIPT_DIR=$(dirname -- "$(readlink -e -- "$0")")
source "${SCRIPT_DIR}/env-files.sh"

declare -r IMAGE_NAME="$1"
declare -r IMAGE_TAG="$2"
declare -r META_ENV_VARS_PATH="$3"

DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' ${IMAGE_NAME}:${IMAGE_TAG})
add-or-update-env-var "IMAGE_DIGEST" "${DIGEST}" "${META_ENV_VARS_PATH}"
