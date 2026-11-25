# practice-pha infrastructure: a thin wrapper around the CloudFormation stacks and
# cosign. Requires an AWS login with a configured region. Most is configured here but
# requires some env variables that are provided automatically when invoking via the
# root Makefile.
#
# Stacks in deploy order. Each imports only from stacks to its left, so tear down from
# right to left:  registry  secrets  network  ingress  cluster  service
#
#   make deploy-registry
#   make deploy-secrets
#   make secrets        	   pushes .$(ENV).env into Secrets Manager
#   make deploy-network
#   make deploy-ingress
#   make deploy-cluster        host changes: newer ECS AMI, instance type
#   make deploy-service        a release: new image digest
#   make $(COSIGN_PUB)         Exports public key locally
#   make sign
#   make verify
#   make $(META_ENV_PATH)      Exports key data of stacks
#   make release               Pushes application updates to prod
#
# Needs AWS CLI v2, jq and cosign.

# ----- Configuration ------------------------------------------------------------------
AWS_CLI_PATH        := .aws/
AWS_PROFILE         := practice-pha-admin
AWS_PROFILE_IAM     := practice-pha-admin

export AWS_PROFILE

REGISTRY_CF         := cf-registry.yaml
REGISTRY_STACK      := $(PROJECT)-registry

SECRETS_CF          := cf-secrets.yaml
SECRETS_STACK       := $(PROJECT)-$(APP)-$(ENV)-secrets
SECRETS_ID          := $(APP)/$(ENV)/env

ALERTS_CF           := cf-alerts.yaml
ALERTS_STACK		:= $(PROJECT)-alerts
ALERTS_PARAMS       := cf-alerts.params.json

NETWORK_CF          := cf-network.yaml
NETWORK_STACK       := $(PROJECT)-network

INGRESS_CF          := cf-ingress.yaml
INGRESS_STACK       := $(PROJECT)-ingress

CLUSTER_CF          := cf-cluster.yaml
CLUSTER_STACK       := $(PROJECT)-cluster

SERVICE_CF          := cf-service.yaml
SERVICE_STACK       := $(PROJECT)-$(APP)-$(ENV)-service

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
                            --stack-name $(SERVICE_STACK) \
                            --query "Stacks[0].Outputs[?OutputKey=='ElbTargetGroup'].OutputValue" \
                            --output text)
TASKS               ?= $(shell aws ecs list-tasks --cluster pha-cluster \
                            --query 'taskArns[]' --output text --no-cli-pager)
ELB                 ?= $(shell aws cloudformation describe-stacks \
                            --stack-name $(INGRESS_STACK) \
                            --query "Stacks[0].Outputs[?OutputKey=='LoadBalancerDnsName'].OutputValue" \
                            --output text)

SHELL               := /bin/bash
.SHELLFLAGS         := -eu -o pipefail -c
.DELETE_ON_ERROR:


# ----- Phony Targets ------------------------------------------------------------------
.PHONY: help init read login sign verify secrets \
		deploy-secrets deploy-registry deploy-alerts deploy-network deploy-ingress deploy-cluster deploy-service \
		test smoke-test smoke-test-target-group smoke-test-cluster smoke-test-elb availability-test \
		teardown-all teardown-infrastructure teardown-app \
		teardown-service teardown-cluster teardown-ingress teardown-registry teardown-network teardown-secrets teardown-alerts

init: deploy-registry deploy-secrets secrets $(META_ENV_PATH) deploy-alerts
infrastructure: deploy-network deploy-ingress deploy-cluster 
release: deploy-service

test: smoke-test availability-test
smoke-test: smoke-test-target-group smoke-test-cluster smoke-test-elb

teardown-app: teardown-service 
teardown-infrastructure: teardown-cluster teardown-ingress teardown-network
teardown-all: teardown-app teardown-infrastructure teardown-alerts teardown-registry teardown-secrets

help:
	@sed -n '1,/^$$/s/^# \{0,1\}//p' $(firstword $(MAKEFILE_LIST))


# ----- Recipes ------------------------------------------------------------------------
secrets: $(ENV_PATH)
	aws secretsmanager put-secret-value \
	    --secret-id $(SECRETS_ID) --secret-string file://$< \
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

login: $(META_ENV_PATH)
	aws ecr get-login-password \
		| docker login $(RegistryUri) --username AWS --password-stdin 


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

deploy-alerts:
	AWS_PROFILE=$(AWS_PROFILE_IAM) aws cloudformation deploy \
		--template-file $(ALERTS_CF) \
		--stack-name $(ALERTS_STACK) \
		--capabilities CAPABILITY_IAM \
		--no-fail-on-empty-changeset \
		--parameter-overrides ProjectName=$(PROJECT) \
		--parameter-overrides file://$(ALERTS_PARAMS) \
		--tags project=$(PROJECT)

deploy-network:
	AWS_PROFILE=$(AWS_PROFILE_IAM) aws cloudformation deploy \
		--template-file $(NETWORK_CF) \
		--stack-name $(NETWORK_STACK) \
		--capabilities CAPABILITY_IAM \
		--no-fail-on-empty-changeset \
		--parameter-overrides ProjectName=$(PROJECT) \
		--tags project=$(PROJECT)

deploy-ingress:
	AWS_PROFILE=$(AWS_PROFILE_IAM) aws cloudformation deploy \
		--template-file $(INGRESS_CF) \
		--stack-name $(INGRESS_STACK) \
		--capabilities CAPABILITY_IAM \
		--no-fail-on-empty-changeset \
		--parameter-overrides ProjectName=$(PROJECT) NetworkStackName=$(NETWORK_STACK) AlertsStackName=$(ALERTS_STACK) \
		--tags project=$(PROJECT)

deploy-cluster:
	AWS_PROFILE=$(AWS_PROFILE_IAM) aws cloudformation deploy \
		--template-file $(CLUSTER_CF) \
		--stack-name $(CLUSTER_STACK) \
		--capabilities CAPABILITY_IAM \
		--no-fail-on-empty-changeset \
		--parameter-overrides ProjectName=$(PROJECT) NetworkStackName=$(NETWORK_STACK) AlertsStackName=$(ALERTS_STACK) \
		--tags project=$(PROJECT)

deploy-service:
	@AZs="$$(aws cloudformation list-exports --output text --query "Exports[?Name=='$(NETWORK_STACK)-AvailabilityZones'].Value")"; \
	AWS_PROFILE=$(AWS_PROFILE_IAM) aws cloudformation deploy \
		--template-file $(SERVICE_CF) \
		--stack-name $(SERVICE_STACK) \
		--capabilities CAPABILITY_IAM \
		--no-fail-on-empty-changeset \
		--parameter-overrides ProjectName=$(PROJECT) NetworkStackName=$(NETWORK_STACK) IngressStackName=$(INGRESS_STACK) ClusterStackName=$(CLUSTER_STACK) SecretsStackName=$(SECRETS_STACK) AlertsStackName=$(ALERTS_STACK) RepositoryURI=$(REPOSITORY_URI) ImageDigest=$(IMAGE_DIGEST) "AvailabilityZones=$$AZs" \
		--tags project=$(PROJECT) app=$(APP) env=$(ENV)


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

teardown-alerts:
	AWS_PROFILE=$(AWS_PROFILE_IAM) aws cloudformation delete-stack \
		--stack-name $(ALERTS_STACK)
	AWS_PROFILE=$(AWS_PROFILE_IAM) aws cloudformation wait stack-delete-complete \
		--stack-name $(ALERTS_STACK)

teardown-network:
	AWS_PROFILE=$(AWS_PROFILE_IAM) aws cloudformation delete-stack \
		--stack-name $(NETWORK_STACK)
	AWS_PROFILE=$(AWS_PROFILE_IAM) aws cloudformation wait stack-delete-complete \
		--stack-name $(NETWORK_STACK)

teardown-service:
	AWS_PROFILE=$(AWS_PROFILE_IAM) aws cloudformation delete-stack \
		--stack-name $(SERVICE_STACK)
	AWS_PROFILE=$(AWS_PROFILE_IAM) aws cloudformation wait stack-delete-complete \
		--stack-name $(SERVICE_STACK)

teardown-cluster:
	AWS_PROFILE=$(AWS_PROFILE_IAM) aws cloudformation delete-stack \
		--stack-name $(CLUSTER_STACK)
	AWS_PROFILE=$(AWS_PROFILE_IAM) aws cloudformation wait stack-delete-complete \
		--stack-name $(CLUSTER_STACK)

teardown-ingress:
	AWS_PROFILE=$(AWS_PROFILE_IAM) aws cloudformation delete-stack \
		--stack-name $(INGRESS_STACK)
	AWS_PROFILE=$(AWS_PROFILE_IAM) aws cloudformation wait stack-delete-complete \
		--stack-name $(INGRESS_STACK)


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

# acceptance-test:

availability-test:
	source ./availability-test.sh "http://$(ELB)" "pha-cluster" "$(TASKS)"


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
