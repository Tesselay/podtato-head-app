# practice-pha infrastructure: a thin wrapper around two CloudFormation stacks and
# cosign. Requies an AWS login with a configured region. Most is configured here but
# requires some env variables that are provided automatically when invoking via the
# root Makefile.
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
AWS_PROFILE         := practice-pha-admin
AWS_PROFILE_IAM     := practice-pha-admin

export AWS_PROFILE

REGISTRY_CF         := cf-ecr-repository.json
REGISTRY_STACK      := $(PROJECT)-registry

SECRETS_CF          := cf-secrets.json
SECRETS_STACK       := $(PROJECT)-$(APP)-$(ENV)-secrets
SECRETS_ID          := $(APP)/$(ENV)/env

NETWORK_CF          := cf-vpc.json
NETWORK_STACK       := $(PROJECT)-network

ECS_CF              := cf-ecs.json
ECS_STACK           := $(PROJECT)-ecs

COSIGN_PUB          := cosign.pub
COSIGN_KEY          := awskms:///alias/$(PROJECT)-cosign

-include $(META_ENV_PATH)

REPOSITORY          := prod/$(APP)
REPOSITORY_URI      := $(RegistryUri)/$(REPOSITORY)

IMAGE_DIGEST        ?= $(shell aws ecr describe-images \
                            --repository-name $(REPOSITORY) \
                            --image-ids imageTag=$(IMAGE_TAG) \
                            --query "imageDetails[0].imageDigest" --output text)
TARGETGROUP         ?= $(shell aws cloudformation describe-stacks \
                            --stack-name $(NETWORK_STACK) \
                            --query "Stacks[0].Outputs[?OutputKey=='ElbTargetGroup'].OutputValue" \
                            --output text)
TASKS               ?= $(shell aws ecs list-tasks --cluster pha-cluster \
                            --query 'taskArns[]' --output text --no-cli-pager)
ELB                 ?= $(shell aws cloudformation describe-stacks \
                            --stack-name $(NETWORK_STACK) \
                            --query "Stacks[0].Outputs[?OutputKey=='LoadBalancerDnsName'].OutputValue" \
                            --output text)

SHELL               := /bin/bash
.SHELLFLAGS         := -eu -o pipefail -c
.DELETE_ON_ERROR:




# ----- Phony Targets ------------------------------------------------------------------
.PHONY: help init read login sign verify \
		deploy-secrets deploy-registry deploy-network deploy-ecs secrets \
		test smoke-test smoke-test-target-group smoke-test-cluster smoke-test-elb availability-test \
		teardown-stack teardown-stack-all teardown-ecs teardown-registy teardown-network teardown-secrets \

init: deploy-registry deploy-secrets secrets deploy-network deploy-ecs $(META_ENV_PATH)
test: smoke-test-target-group smoke-test-cluster smoke-test-elb availability-test
smoke-test: smoke-test-target-group smoke-test-cluster smoke-test-elb
teardown-stack: teardown-ecs teardown-network
teardown-stack-all: teardown-stack teardown-registry teardown-secrets

help:
	@sed -n '1,/^$$/s/^# \{0,1\}//p' $(firstword $(MAKEFILE_LIST))


# ----- Recipes ------------------------------------------------------------------------
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

read:
	aws cloudformation describe-stacks \
		--stack-name $(REGISTRY_STACK) --query 'Stacks[0].Outputs' --output table
	aws cloudformation describe-stacks \
		--stack-name $(SECRETS_STACK) --query 'Stacks[0].Outputs' --output table

login:
	aws ecr get-login-password \
		| docker login --username AWS --password-stdin $(RegistryUri)


# ----- Deploy -------------------------------------------------------------------------
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

deploy-network:
	AWS_PROFILE=$(AWS_PROFILE_IAM) aws cloudformation deploy \
		--template-file $(NETWORK_CF) \
		--stack-name $(NETWORK_STACK) \
		--capabilities CAPABILITY_IAM \
		--no-fail-on-empty-changeset \
		--parameter-overrides ProjectName=$(PROJECT) \
		--tags project=$(PROJECT)

deploy-ecs:
	AWS_PROFILE=$(AWS_PROFILE_IAM) aws cloudformation deploy \
		--template-file $(ECS_CF) \
		--stack-name $(ECS_STACK) \
		--capabilities CAPABILITY_IAM \
		--no-fail-on-empty-changeset \
		--parameter-overrides ProjectName=$(PROJECT) NetworkStackName=$(NETWORK_STACK) SecretsStackName=$(SECRETS_STACK) RepositoryUri=$(REPOSITORY_URI) ImageDigest=$(IMAGE_DIGEST) \
		--tags project=$(PROJECT)


# ----- Teardown -----------------------------------------------------------------------
teardown-secrets:
	AWS_PROFILE=$(AWS_PROFILE_IAM) aws cloudformation delete-stack \
		--stack-name $(SECRETS_STACK)
	AWS_PROFILE=$(AWS_PROFILE_IAM) aws cloudformation wait stack-delete-complete \
		--stack-name $(SECRETS_STACK) \

teardown-registry:
	AWS_PROFILE=$(AWS_PROFILE_IAM) aws cloudformation delete-stack \
		--stack-name $(REGISTRY_STACK)
	AWS_PROFILE=$(AWS_PROFILE_IAM) aws cloudformation wait stack-delete-complete \
		--stack-name $(REGISTRY_STACK)

teardown-network:
	AWS_PROFILE=$(AWS_PROFILE_IAM) aws cloudformation delete-stack \
		--stack-name $(NETWORK_STACK)
	AWS_PROFILE=$(AWS_PROFILE_IAM) aws cloudformation wait stack-delete-complete \
		--stack-name $(NETWORK_STACK)

teardown-ecs:
	AWS_PROFILE=$(AWS_PROFILE_IAM) aws cloudformation delete-stack \
		--stack-name $(ECS_STACK)
	AWS_PROFILE=$(AWS_PROFILE_IAM) aws cloudformation wait stack-delete-complete \
		--stack-name $(ECS_STACK)


# ----- Testing ------------------------------------------------------------------------
smoke-test-target-group:
	aws elbv2 describe-target-health --target-group-arn "$(TARGETGROUP)" \
        --query 'TargetHealthDescriptions[].[Target.Id,TargetHealth.State]' --output table

smoke-test-cluster:
	aws ecs describe-tasks --cluster pha-cluster \
        --tasks $(TASKS) \
        --query 'tasks[].[availabilityZone,lastStatus]' --output table

smoke-test-elb:
	curl -o /dev/null -s -w "HTTP Return Code: %{http_code}\n" http://$(ELB)/

availability-test:
	source ../../scripts/availability-test.sh "http://$(ELB)" "pha-cluster" "$(TASKS)"


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
