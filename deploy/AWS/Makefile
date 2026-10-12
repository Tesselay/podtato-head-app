# practice-pha infrastructure: a thin wrapper around two CloudFormation stacks,
# plus the two steps that deliberately stay outside CloudFormation
# (secret values and cosign signing).
#
#   make deploy-registry PUSH_PULL_PRINCIPAL=arn:aws:iam::<account-id>:user/<you>
#   make deploy-secrets
#   make secrets        	   pushes .$(ENV).env into Secrets Manager
#   make cosign.pub
#   make sign IMAGE=<repository>@sha256:<digest>
#   make verify IMAGE=<repository>@sha256:<digest>
#   make outputs ENV=dev       shows what both stacks produced
#
# Needs AWS CLI v2, jq and cosign.

# ----- Configuration ------------------------------------------------------------------
AWS_CLI_PATH        := .aws/
ENV           	    := dev
ENV_PATH            := ../../.$(ENV).env
META_ENV_PATH 		:= ../../.meta.env
PROJECT 		    := practice-pha
APP                 := podtato-head-app
IMAGE_TAG           := $(shell git rev-parse --short HEAD)

PUSH_PULL_PRINCIPAL := arn:aws:iam::285150348793:user/ecr_practice_project

REGISTRY_CF         := cf-ecr-repository.json
REGISTRY_STACK      := $(PROJECT)-registry

SECRETS_CF          := cf-secrets.json
SECRETS_STACK       := $(PROJECT)-$(APP)-$(ENV)-secrets
SECRETS_ID          := $(APP)/$(ENV)/env

COSIGN_PUB          := cosign.pub
COSIGN_KEY          := awskms:///alias/$(PROJECT)-cosign

-include $(META_ENV_PATH)

REPOSITORY          := prod/$(APP)
REPOSITORY_URI      := $(RegistryUri)/$(REPOSITORY)

SHELL               := /bin/bash
.SHELLFLAGS         := -eu -o pipefail -c
.DELETE_ON_ERROR:


# ----- Phony Targets ------------------------------------------------------------------
.PHONY: help init \
		deploy-secrets deploy-registry secrets \
		read login \
		sign verify \

init: deploy-registry deploy-secrets secrets $(META_ENV_PATH)

help:
	@sed -n '1,/^$$/s/^# \{0,1\}//p' $(firstword $(MAKEFILE_LIST))


# ----- Init ---------------------------------------------------------------------------
deploy-secrets:
	docker run --rm -i \
	    --mount type=bind,src=./$(AWS_CLI_PATH),dst=/root/.aws,ro \
		--mount type=bind,src=./$(SECRETS_CF),dst=/root/$(SECRETS_CF),ro \
		public.ecr.aws/aws-cli/aws-cli cloudformation deploy \
		--template-file /root/$(SECRETS_CF) \
		--stack-name $(SECRETS_STACK) \
		--capabilities CAPABILITY_IAM \
		--no-fail-on-empty-changeset \
		--parameter-overrides AppName=$(APP) Environment=$(ENV) \
		--tags project=$(PROJECT) app=$(APP) env=$(ENV)

deploy-registry:
	@test -n "$(PUSH_PULL_PRINCIPAL)" || { echo "Set PUSH_PULL_PRINCIPAL to the ARN of the user or role that pushes and pulls images." >&2; exit 1; }
	docker run --rm -i \
	    --mount type=bind,src=./$(AWS_CLI_PATH),dst=/root/.aws,ro \
	    --mount type=bind,src=./$(REGISTRY_CF),dst=/root/$(REGISTRY_CF),ro \
		public.ecr.aws/aws-cli/aws-cli cloudformation deploy \
		--template-file /root/$(REGISTRY_CF) \
		--stack-name $(REGISTRY_STACK) \
		--capabilities CAPABILITY_IAM \
		--no-fail-on-empty-changeset \
		--parameter-overrides ProjectName=$(PROJECT) PushPullPrincipalArn=$(PUSH_PULL_PRINCIPAL) \
		--tags project=$(PROJECT)

secrets: $(ENV_PATH)
	set -o pipefail; \
	jq -c -Rn -f env-to-json.jq < $< \
	  | docker run --rm -i \
		--mount type=bind,src=./$(AWS_CLI_PATH),dst=/root/.aws,ro \
		public.ecr.aws/aws-cli/aws-cli secretsmanager put-secret-value \
	    --secret-id $(SECRETS_ID) --secret-string file:///dev/stdin \
		> /dev/null
	@echo "Updated $(SECRETS_ID) from $<"

$(META_ENV_PATH):
	docker run --rm -i \
	    --mount type=bind,src=./$(AWS_CLI_PATH),dst=/root/.aws,ro \
		public.ecr.aws/aws-cli/aws-cli cloudformation describe-stacks \
	    --stack-name $(REGISTRY_STACK) \
		--query 'Stacks[0].Outputs[].[OutputKey,OutputValue]' \
		--output text | tr '\t' '=' > $@


# ----- Recipes ------------------------------------------------------------------------
read:
	docker run --rm -i \
	    --mount type=bind,src=./$(AWS_CLI_PATH),dst=/root/.aws,ro \
		public.ecr.aws/aws-cli/aws-cli cloudformation describe-stacks \
		--stack-name $(REGISTRY_STACK) --query 'Stacks[0].Outputs' --output table
	docker run --rm -i \
	    --mount type=bind,src=./$(AWS_CLI_PATH),dst=/root/.aws,ro \
		public.ecr.aws/aws-cli/aws-cli cloudformation describe-stacks \
		--stack-name $(SECRETS_STACK) --query 'Stacks[0].Outputs' --output table

login:
	docker run --rm -it \
	    --mount type=bind,src=./$(AWS_CLI_PATH),dst=/root/.aws,ro \
		public.ecr.aws/aws-cli/aws-cli ecr get-login-password \
		| docker login --username AWS --password-stdin $(RegistryUri)

push: login
	docker tag $(APP):$(IMAGE_TAG) $(REPOSITORY_URI):$(IMAGE_TAG)
	docker push $(REPOSITORY_URI):$(IMAGE_TAG)


# ----- Signing ------------------------------------------------------------------------
$(COSIGN_PUB):
	cosign public-key --key $(COSIGN_KEY) > $@

sign:
	digest=$$(docker run --rm -i \
	    --mount type=bind,src=./$(AWS_CLI_PATH),dst=/root/.aws,ro \
		public.ecr.aws/aws-cli/aws-cli ecr describe-images \
	    --repository-name $(REPOSITORY) --image-ids imageTag=$(IMAGE_TAG) \
		--query 'imageDetails[0].imageDigest' --output text) && \
	cosign sign --yes --key $(COSIGN_KEY) $(REPOSITORY_URI)@$$digest

verify:
	digest=$$(docker run --rm -i \
	    --mount type=bind,src=./$(AWS_CLI_PATH),dst=/root/.aws,ro \
		public.ecr.aws/aws-cli/aws-cli ecr describe-images \
	    --repository-name $(REPOSITORY) --image-ids imageTag=$(IMAGE_TAG) \
		--query 'imageDetails[0].imageDigest' --output text) && \
	cosign verify --yes --key $(COSIGN_KEY) $(REPOSITORY_URI)@$$digest
