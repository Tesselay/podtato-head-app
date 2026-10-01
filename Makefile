# ----- Configuration ------------------------------------------------------------------
DEPLOYMENT_METHOD := deploy/AWS
ENV_VARS_PATH     := app.env
IMAGE_NAME        := podtato-head-app

-include $(ENV_VARS_PATH)

# ----- Phony Targets ------------------------------------------------------------------
.PHONY: init build run


# ----- Initialize ---------------------------------------------------------------------
init:
	$(MAKE) -C $(DEPLOYMENT_METHOD) init

$(ENV_VARS_PATH):
	$(MAKE) -C $(DEPLOYMENT_METHOD) export-env


# ----- Recipes ------------------------------------------------------------------------
build:
	docker buildx build --secret id=buildenv,src=$(ENV_VARS_PATH) -t $(IMAGE_NAME) .

run:
	docker run --rm -it $(IMAGE_NAME)
