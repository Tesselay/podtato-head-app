# practice-pha infrastructure: a thin wrapper around two CloudFormation stacks and
# cosign. Requires a SSO authenticated AWS profile (`aws sso`) as cosign works better
# with it than the newer `aws login`. Most is configured here but requires some env
# variables that are provided automatically when invoking via the root Makefile.
#
#   make deploy-registry
#   make deploy-secrets
#   make secrets        	   pushes .$(ENV).env into Secrets Manager
#   make $(COSIGN_PUB)         Exports public key locally
#   make sign
#   make verify
#   make $(META_ENV_PATH)      Exports key data of stacks
#
# Needs AWS CLI v2, jq and cosign.

# ----- Configuration ------------------------------------------------------------------
AWS_CLI_PATH        := .aws/
AWS_PROFILE         := practice-pha
AWS_PROFILE_IAM     := practice-pha-admin

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

export AWS_PROFILE


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
	AWS_PROFILE=$(AWS_PROFILE_IAM) aws cloudformation deploy \
		--template-file $(SECRETS_CF) \
		--stack-name $(SECRETS_STACK) \
		--capabilities CAPABILITY_IAM \
		--no-fail-on-empty-changeset \
		--parameter-overrides AppName=$(APP) Environment=$(ENV) \
		--tags project=$(PROJECT) app=$(APP) env=$(ENV)

deploy-registry:
	AWS_PROFILE=$(AWS_PROFILE_IAM) aws cloudformation deploy \
		--template-file $(REGISTRY_CF) \
		--stack-name $(REGISTRY_STACK) \
		--capabilities CAPABILITY_IAM \
		--no-fail-on-empty-changeset \
		--parameter-overrides ProjectName=$(PROJECT) \
		--tags project=$(PROJECT)

secrets: $(ENV_PATH)
	set -o pipefail; \
	jq -c -Rn -f env-to-json.jq < $< \
	  | aws secretsmanager put-secret-value \
	    --secret-id $(SECRETS_ID) --secret-string file:///dev/stdin \
		> /dev/null
	@echo "Updated $(SECRETS_ID) from $<"

$(META_ENV_PATH):
	aws cloudformation describe-stacks \
	    --stack-name $(REGISTRY_STACK) \
		--query 'Stacks[0].Outputs[].[OutputKey,OutputValue]' \
		--output text | tr '\t' '=' > $@


# ----- Recipes ------------------------------------------------------------------------
read:
	aws cloudformation describe-stacks \
		--stack-name $(REGISTRY_STACK) --query 'Stacks[0].Outputs' --output table
	aws cloudformation describe-stacks \
		--stack-name $(SECRETS_STACK) --query 'Stacks[0].Outputs' --output table

login:
	aws ecr get-login-password \
		| docker login --username AWS --password-stdin $(RegistryUri)


# ----- Signing ------------------------------------------------------------------------
$(COSIGN_PUB):
	cosign public-key --key $(COSIGN_KEY) > $@

sign:
	digest=$$(aws ecr describe-images \
	    --repository-name $(REPOSITORY) --image-ids imageTag=$(IMAGE_TAG) \
		--query 'imageDetails[0].imageDigest' --output text) && \
	cosign sign --yes --key $(COSIGN_KEY) $(REPOSITORY_URI)@$$digest

verify:
	digest=$$(aws ecr describe-images \
	    --repository-name $(REPOSITORY) --image-ids imageTag=$(IMAGE_TAG) \
		--query 'imageDetails[0].imageDigest' --output text) && \
	cosign verify --key $(COSIGN_KEY) $(REPOSITORY_URI)@$$digest
