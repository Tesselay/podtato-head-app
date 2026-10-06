# ----- Configuration ------------------------------------------------------------------
DEPLOYMENT_METHOD  := deploy/AWS
APP_ENV_VARS_PATH  := app.env
META_ENV_VARS_PATH := meta.env
CONTAINER_NAME     := pha-runtime

-include $(APP_ENV_VARS_PATH)
-include $(META_ENV_VARS_PATH)


# ----- Phony Targets ------------------------------------------------------------------
.PHONY: init login \
		build digest sign push run \
		build-test run-test


# ----- Initialize ---------------------------------------------------------------------
$(APP_ENV_VARS_PATH) $(META_ENV_VARS_PATH) init:
	$(MAKE) -C $(DEPLOYMENT_METHOD) init

login:
	$(MAKE) -C $(DEPLOYMENT_METHOD) login


# ----- Recipes ------------------------------------------------------------------------
build:
	docker buildx build -t $(IMAGE_NAME):$(IMAGE_TAG) .

$(META_ENV_VARS_PATH) digest:
	./scripts/create-digest.sh $(IMAGE_NAME) $(IMAGE_TAG) $(META_ENV_VARS_PATH)

sign:
	cosign sign --key $(COSIGN_KEY_PATH) $(IMAGE_DIGEST)

push: login
	docker push $(IMAGE_NAME):$(IMAGE_TAG)

run: build
	docker run --rm -it -p $(PODTATO_PORT):$(PODTATO_PORT) $(IMAGE_NAME)
