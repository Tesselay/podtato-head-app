# practice-pha infrastructure: entry Makefile that governs infrastructure deployment.
# Actual deployment is offloaded to sub-Makefiles called from here.
#
#   make all                   Initialize baseline, build infrastructure, deploy application
#   make init				   Establish baseline for infrastructure and/or application
#   make infrastructure        Build infrastructure that the application runs on
#   make release               Pushes application updates to prod
#   make login                 Authenticate platform with Docker if applicable
#   make secrets               Pass secrets to platform if applicable
#   make sign                  Sign image using cosign in registry
#   make verify                Verify image using cosign in registry
#   make push                  Workflow: Build, push and sign image
#   make local                 Workflow: Build image, run and teardown container
# 							       (test basic functioning)
#   make test                  Workflow: Build image, run container, run smoke-test and
#                                  teardown container
#
# Needs docker, cosign and a configured deployment method

# ----- Configuration ------------------------------------------------------------------
PROJECT 	  := practice-pha
APP           := podtato-head-app
DEPLOYMENT    := deploy/AWS
ENV           := dev
ENV_PATH      := ".$(ENV).env.json"
TEST_ENV_PATH := .test.env
META_ENV_PATH := .meta.env
CONTAINER     := pha-runtime
IMAGE_TAG     := $(shell git rev-parse --short HEAD)

-include $(META_ENV_PATH)
-include $(ENV_PATH)

REPOSITORY     := prod/$(APP)
REPOSITORY_URI := $(RegistryUri)/$(REPOSITORY)

DEPLOY         := $(MAKE) -C $(DEPLOYMENT) \
				  PROJECT=$(PROJECT) APP=$(APP) IMAGE_TAG=$(IMAGE_TAG) \
				  REPOSITORY=$(REPOSITORY) REPOSITORY_URI=$(REPOSITORY_URI) \
				  ENV=$(ENV) ENV_PATH=$(abspath $(ENV_PATH)) \
				  META_ENV_PATH=$(abspath $(META_ENV_PATH))

SHELL               := /bin/bash
.SHELLFLAGS         := -eu -o pipefail -c
.DELETE_ON_ERROR:


# ----- Phony Targets ------------------------------------------------------------------
.PHONY: all init infrastructure login secrets verify teardown-stack teardown-all \
		push push-image sign release \
		test smoke-test availability-test \
		local build-local run-local teardown-local \
		local-test local-build-test local-run-test local-smoke-test local-teardown-test

all: init login push-image sign verify infrastructure release
push: push-image sign
local: build-local run-local teardown-local
local-test: build-test run-test smoke-test teardown-test

help:
	@sed -n '1,/^$$/s/^# \{0,1\}//p' $(firstword $(MAKEFILE_LIST))


# ----- Recipes ------------------------------------------------------------------------
init infrastructure release login secrets sign verify $(META_ENV_PATH) test teardown-stack teardown-all smoke-test availability-test:
	$(DEPLOY) $@

push-image: login build-local
	docker tag $(APP):$(IMAGE_TAG) $(REPOSITORY_URI):$(IMAGE_TAG)
	docker push $(REPOSITORY_URI):$(IMAGE_TAG)


# ----- Local --------------------------------------------------------------------------
build-local:
	docker buildx build -t $(APP):$(IMAGE_TAG) .

run-local: build-local
	docker run --rm -it -p $(PODTATO_PORT):$(PODTATO_PORT) --env-file $(ENV_PATH) --name $(CONTAINER) -d $(APP):$(IMAGE_TAG)

teardown-local:
	docker container kill $(CONTAINER)


# ----- Test ---------------------------------------------------------------------------
# Ideally would set `ENV=test` and re-process file
local-build-test:
	docker buildx build -t $(APP):test .

local-run-test: build-test
	docker run --rm -it --env-file $(TEST_ENV_PATH) -p 8090:8090 --name $(CONTAINER)-test -d $(APP):test

local-smoke-test: run-test
	curl -s -w "%{http_code}\n" http://127.0.0.1:8090/readyz
	curl -s -w "%{http_code}\n" http://127.0.0.1:8090/healthz

local-teardown-test:
	docker container kill $(CONTAINER)-test
