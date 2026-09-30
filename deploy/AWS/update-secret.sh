#!/bin/bash

declare -r AWS_CLI_PATH="$1"
declare -r ENV_VARS_PATH="$2"
declare -r SECRET_NAME="$3"

docker run --rm -it -v ./${AWS_CLI_PATH}:/root/.aws -v ./${ENV_VARS_PATH}:/root/vars.json public.ecr.aws/aws-cli/aws-cli secretsmanager update-secret --secret-id "${SECRET_NAME}" --secret-string file://~/vars.json
echo "INFO: Secret with name '${SECRET_NAME}' already exists, skipping creation."
