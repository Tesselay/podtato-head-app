#!/bin/bash

SCRIPT_DIR=$(dirname -- "$(readlink -e -- "$0")")
source "$SCRIPT_DIR/../../scripts/env-files.sh"
source "$SCRIPT_DIR/aws.sh"

declare -r AWS_CLI_PATH="$1"
declare -r AWS_METADATA_PATH="$2"
declare -r AUTH_ENV_VARS_PATH="$3"

declare AWS_KEYID_COSIGN=$(jq -r ".KeyMetadata.KeyId" "${AWS_METADATA_PATH}")

if ! verify-aws-key "$AWS_KEYID_COSIGN" "$AWS_CLI_PATH"; then
    docker run --rm -it -v ./${AWS_CLI_PATH}:/root/.aws public.ecr.aws/aws-cli/aws-cli kms create-key \
        --key-spec RSA_4096 \
        --key-usage SIGN_VERIFY \
        --description "practice-pha Cosign Signature Key Pair" \
        --output json --no-cli-pager > "${AWS_METADATA_PATH}"
    AWS_KEYID_COSIGN=$(jq -r ".KeyMetadata.KeyId" "${AWS_METADATA_PATH}")
fi

add-or-update-env-var "COSIGN_KEY_PATH" "awskms:///$AWS_KEYID_COSIGN" "${AUTH_ENV_VARS_PATH}"
add-or-update-env-var "COSIGN_PASSWORD" '""' "${AUTH_ENV_VARS_PATH}"
