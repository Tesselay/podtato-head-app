#!/bin/bash

declare -r AWS_CLI_PATH="$1"
declare -r ENV_VARS_PATH="$2"
declare -r SECRET_NAME="$3"

if docker run --rm -it -v ./${AWS_CLI_PATH}:/root/.aws public.ecr.aws/aws-cli/aws-cli secretsmanager describe-secret --secret-id "${SECRET_NAME}" &> /dev/null; then
    echo "INFO: Secret with name '${SECRET_NAME}' already exists, skipping creation."
else
    docker run --rm -it -v ./${AWS_CLI_PATH}:/root/.aws -v ./${ENV_VARS_PATH}:/root/vars.json public.ecr.aws/aws-cli/aws-cli secretsmanager create-secret --name "${SECRET_NAME}" --secret-string "file://~/vars.json"
    echo "SUCCESS: Secret with name '${SECRET_NAME}' created."
fi
