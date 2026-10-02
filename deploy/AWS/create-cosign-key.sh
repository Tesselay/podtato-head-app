#!/bin/bash

SCRIPT_DIR=$(dirname -- "$(readlink -e -- "$0")")
source "$SCRIPT_DIR/aws.sh"

declare -r AWS_CLI_PATH="$1"
declare -r AWS_METADATA_PATH="$2"
declare -r AWS_KEYID_COSIGN="$3"

if [[ -z $AWS_KEYID_COSIGN ]]; then
    declare AWS_KEYID_COSIGN=$(jq -r ".KeyMetadata.KeyId" "${AWS_METADATA_PATH}")
fi

if ! verify-aws-key "$AWS_KEYID_COSIGN" "$AWS_CLI_PATH"; then
    docker run --rm -it -v ./${AWS_CLI_PATH}:/root/.aws public.ecr.aws/aws-cli/aws-cli kms create-key \
        --key-spec RSA_4096 \
        --key-usage SIGN_VERIFY \
        --description "practice-pha Cosign Signature Key Pair" \
        --output json --no-cli-pager > "${AWS_METADATA_PATH}"
fi

if [[ ! -e $AWS_METADATA_PATH ]]; then
    docker run --rm -it -v ./${AWS_CLI_PATH}:/root/.aws public.ecr.aws/aws-cli/aws-cli kms describe-key \
        --key-id "${AWS_KEYID_COSIGN}" --output json > "${AWS_METADATA_PATH}"
fi
