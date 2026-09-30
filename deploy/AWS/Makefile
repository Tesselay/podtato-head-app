# ----- Configuration ------------------------------------------------------------------
AWS_CLI_PATH  := .aws/
ENV_VARS_PATH := ../../server-vars.json
SECRET_NAME   := podtato-head-app


# ----- Phony Targets ------------------------------------------------------------------
.PHONY: init update-secrets


# ----- Initialize ---------------------------------------------------------------------
init:
	./create-secret.sh $(AWS_CLI_PATH) $(ENV_VARS_PATH) $(SECRET_NAME)

update-secrets: $(ENV_VARS_PATH)
	./update-secret.sh $(AWS_CLI_PATH) $(ENV_VARS_PATH) $(SECRET_NAME)
