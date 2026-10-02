#!/bin/bash
SCRIPT_DIR=$(dirname -- "$(readlink -e -- "$0")")

declare -r AWS_CLI_PATH="$1"
declare -r AWS_METADATA_PATH="$2"
declare -r IMAGE_NAME="$3"

declare -r IMAGE_ID=$(docker images "${IMAGE_NAME}:latest" --format "{{.ID}}")
declare -r AWS_ECR_REPO_URI=$(jq -r ".repository.repositoryUri" "$AWS_METADATA_PATH")

docker run --rm -it \
    -v ./${AWS_CLI_PATH}:/root/.aws \
    public.ecr.aws/aws-cli/aws-cli ecr get-login-password | docker login --username AWS --password-stdin $(echo "$AWS_ECR_REPO_URI" | awk 'BEGIN{ FS = "/" }; { print $1 }')

docker tag "$IMAGE_ID" "${AWS_ECR_REPO_URI}:${IMAGE_NAME}"
docker push "${AWS_ECR_REPO_URI}:${IMAGE_NAME}"
