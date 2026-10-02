# ----- Configuration ------------------------------------------------------------------
DEPLOYMENT_METHOD  := deploy/AWS
APP_ENV_VARS_PATH  := app.env
AUTH_ENV_VARS_PATH := auth.env
IMAGE_NAME         := podtato-head-app

-include $(APP_ENV_VARS_PATH)
-include $(AUTH_ENV_VARS_PATH)


# ----- Phony Targets ------------------------------------------------------------------
.PHONY: init build run

init: $(APP_ENV_VARS_PATH) $(AUTH_ENV_VARS_PATH)


# ----- Initialize ---------------------------------------------------------------------
$(APP_ENV_VARS_PATH) $(AUTH_ENV_VARS_PATH):
	$(MAKE) -C $(DEPLOYMENT_METHOD) init


# ----- Recipes ------------------------------------------------------------------------
build:
	docker buildx build --secret id=buildenv,src=$(APP_ENV_VARS_PATH) -t $(IMAGE_NAME) .

push:
	$(MAKE) -C $(DEPLOYMENT_METHOD) push IMAGE_NAME=$(IMAGE_NAME)

run:
	docker run --rm -it $(IMAGE_NAME)
