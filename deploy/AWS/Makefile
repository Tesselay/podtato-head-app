# ----- Configuration ------------------------------------------------------------------
AWS_CLI_PATH  := .aws/
ENV_VARS_PATH := ../../app.env
AWS_VARS_PATH := aws-vars.json
SECRET_NAME   := podtato-head-app-secrets


# ----- Phony Targets ------------------------------------------------------------------
.PHONY: init export-env

init: $(AWS_VARS_PATH) export-env


# ----- Recipes ------------------------------------------------------------------------
$(AWS_VARS_PATH): $(ENV_VARS_PATH)
	./create-secret.sh $(AWS_CLI_PATH) $(ENV_VARS_PATH) $(AWS_VARS_PATH) $(SECRET_NAME)

export-env:
	./export-secret.sh $(AWS_CLI_PATH) $(ENV_VARS_PATH) $(SECRET_NAME)
