#!/bin/bash
SCRIPT_DIR=$(dirname -- "$(readlink -e -- "$0")")

declare -r AWS_CLI_PATH="$1"
declare -r AWS_METADATA_PATH="$2"
declare -r AWS_ECR_REPO="$3"

docker run --rm -it \
    -v ./${AWS_CLI_PATH}:/root/.aws \
    public.ecr.aws/aws-cli/aws-cli ecr create-repository \
    --repository-name "${AWS_ECR_REPO}" --image-tag-mutability "IMMUTABLE" \
    --output json --no-cli-pager > "${AWS_METADATA_PATH}"
