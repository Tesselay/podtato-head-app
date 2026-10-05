#!/bin/bash
SCRIPT_DIR=$(dirname -- "$(readlink -e -- "$0")")
source "$SCRIPT_DIR/../../scripts/env-files.sh"

declare -r AWS_CLI_PATH="$1"
declare -r AWS_METADATA_PATH="$2"
declare -r AWS_ECR_REPO_NAME="$3"
declare -r META_ENV_VARS_PATH="$4"

# Split so the var contains the return code
declare AWS_ECR_REPO
AWS_ECR_REPO=$(docker run --rm -it -v ./${AWS_CLI_PATH}:/root/.aws public.ecr.aws/aws-cli/aws-cli ecr describe-repositories --repository-names "${AWS_ECR_REPO_NAME}" --query "repositories[0]" --output json --no-cli-pager)

if [ $? -eq 0 ]; then
    echo "INFO: Repository \"$AWS_ECR_REPO_NAME\" found upstream, writing metadata to \"$AWS_METADATA_PATH\"."
    echo $AWS_ECR_REPO > "${AWS_METADATA_PATH}"
    _TAG_MUTABILITY=$(jq -r ".imageTagMutability" <(echo "$AWS_ECR_REPO"))
    if [[ $_TAG_MUTABILITY == "IMMUTABLE" ]]; then
        echo "SUCCESS: Repository \"$AWS_ECR_REPO_NAME\" exists with tag immutability."
    else
        echo "ERROR: Repository \"$AWS_ECR_REPO_NAME\" exists but tags are mutable - fix required."
    fi
else
    echo "INFO: Repository \"$AWS_ECR_REPO_NAME\" does not exist upstream, creating..."
    docker run --rm -it \
        -v ./${AWS_CLI_PATH}:/root/.aws \
        public.ecr.aws/aws-cli/aws-cli ecr create-repository \
        --repository-name "${AWS_ECR_REPO_NAME}" --image-tag-mutability "IMMUTABLE" \
        --output json --no-cli-pager > "${AWS_METADATA_PATH}"
    echo "INFO: Command to create repository \"$AWS_ECR_REPO_NAME\" executed."
fi

declare -r AWS_ECR_REPO_URI=$(jq -r ".repository.repositoryUri" "$AWS_METADATA_PATH")
add-or-update-env-var "IMAGE_NAME" "$AWS_ECR_REPO_URI" "$META_ENV_VARS_PATH"
