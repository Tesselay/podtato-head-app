#!/bin/bash

declare -r AWS_CLI_PATH="$1"
declare -r ENV_VARS_PATH="$2"
declare -r AWS_VARS_PATH="$3"
declare -r SECRET_NAME="$4"

if docker run --rm -it -v ./${AWS_CLI_PATH}:/root/.aws public.ecr.aws/aws-cli/aws-cli secretsmanager describe-secret --secret-id "${SECRET_NAME}" &> /dev/null; then
    docker run --rm -it \
        -v ./${AWS_CLI_PATH}:/root/.aws \
        -v ./${ENV_VARS_PATH}:/root/vars.json \
        public.ecr.aws/aws-cli/aws-cli secretsmanager update-secret \
        --secret-id "${SECRET_NAME}" --secret-string file://~/vars.json \
        --output json --no-cli-pager > "${AWS_VARS_PATH}"
    echo "SUCCESS: Secret with name '${SECRET_NAME}' updated."
else
    docker run --rm -it \
        -v ./${AWS_CLI_PATH}:/root/.aws \
        -v ./${ENV_VARS_PATH}:/root/vars.json \
        public.ecr.aws/aws-cli/aws-cli secretsmanager create-secret \
        --name "${SECRET_NAME}" --secret-string "file://~/vars.json" \
        --output json --no-cli-pager > "${AWS_VARS_PATH}"
    echo "SUCCESS: Secret with name '${SECRET_NAME}' created."
fi
