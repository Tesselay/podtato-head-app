# ----- Configuration ------------------------------------------------------------------
PROJECT 	  := practice-pha
APP           := podtato-head-app
DEPLOYMENT    := deploy/AWS
ENV           := dev
ENV_PATH      := .$(ENV).env
META_ENV_PATH := .meta.env
CONTAINER     := pha-runtime
IMAGE_TAG     := $(shell git rev-parse --short HEAD)

DEPLOY        := $(MAKE) -C $(DEPLOYMENT) \
				 PROJECT=$(PROJECT) APP=$(APP) ENV=$(ENV) ENV_PATH=$(abspath $(ENV_PATH)) META_ENV_PATH=$(abspath $(META_ENV_PATH)) IMAGE_TAG=$(IMAGE_TAG)

-include $(META_ENV_PATH)


# ----- Phony Targets ------------------------------------------------------------------
.PHONY: init login \
		build digest sign push run \
		build-test run-test


# ----- Recipes ------------------------------------------------------------------------
init login secrets push sign verify $(META_ENV_PATH):
	$(DEPLOY) $@

build:
	docker buildx build -t $(APP):$(IMAGE_TAG) .

run: build
	docker run --rm -it -p $(PODTATO_PORT):$(PODTATO_PORT) --env-file $(ENV_PATH) --name $(CONTAINER_NAME) -d $(APP):$(IMAGE_TAG)


# ----- Test ---------------------------------------------------------------------------
build-test:
	docker buildx build -t $(APP):test .

run-test: build-test
	docker run --rm -it --env-file test.env -p 8090:8090 --name $(CONTAINER_NAME)-test -d $(IMAGE_NAME):test

test:
	curl -o /dev/null -s -w "%{http_code}\n" http://127.0.0.1:8090/readyz
	curl -o /dev/null -s -w "%{http_code}\n" http://127.0.0.1:8090/healthz
