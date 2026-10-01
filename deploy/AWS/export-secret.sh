#!/bin/bash
SCRIPT_DIR=$(dirname -- "$(readlink -e -- "$0")")
source "$SCRIPT_DIR/../../env-files.sh"

declare -r AWS_CLI_PATH="$1"
declare -r ENV_VARS_PATH="$2"
declare -r SECRET_NAME="$3"

while read -r env_var; do
    add-or-update-env-var $(echo $env_var | sed 's/=/ /g') "${ENV_VARS_PATH}"
done < <(docker run --rm -it \
                -v ./${AWS_CLI_PATH}:/root/.aws \
                public.ecr.aws/aws-cli/aws-cli secretsmanager get-secret-value \
                --secret-id "${SECRET_NAME}" --query "SecretString" --output text --no-cli-pager | grep "\S"
    )
