#!/bin/bash

SCRIPT_DIR=$(dirname -- "$(readlink -e -- "$0")")
source "$SCRIPT_DIR/../../scripts/env-files.sh"

declare -r AWS_METADATA_PATH="$1"
declare -r AUTH_ENV_VARS_PATH="$2"

declare AWS_KEYID_COSIGN=$(jq -r ".KeyMetadata.KeyId" "${AWS_METADATA_PATH}")

add-or-update-env-var "COSIGN_KEY_PATH" "awskms:///$AWS_KEYID_COSIGN" "${AUTH_ENV_VARS_PATH}"
add-or-update-env-var "COSIGN_PASSWORD" "" "${AUTH_ENV_VARS_PATH}"
