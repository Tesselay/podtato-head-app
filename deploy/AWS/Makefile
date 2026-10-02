# ----- Configuration ------------------------------------------------------------------
AWS_CLI_PATH          := .aws/
APP_ENV_VARS_PATH     := ../../app.env
AUTH_ENV_VARS_PATH    := ../../auth.env

AWS_SECRETS_META_PATH := aws-secretmanager.json
AWS_APP_SECRETS_NAME  := practice-pha-secrets

AWS_KMS_META_PATH     := aws-kms.json

AWS_ECR_META_PATH     := aws-ecr.json
AWS_ECR_REPO_NAME     := practice-pha-repository


# ----- Phony Targets ------------------------------------------------------------------
.PHONY: init export-secrets \
		push

init: $(AWS_SECRETS_META_PATH) $(APP_ENV_VARS_PATH) export-secrets $(AWS_ECR_META_PATH) $(AWS_KMS_META_PATH)
export-secrets: $(APP_ENV_VARS_PATH)


# ----- Init ---------------------------------------------------------------------------
$(AWS_SECRETS_META_PATH): $(APP_ENV_VARS_PATH)
	./create-secret.sh $(AWS_CLI_PATH) $(AWS_SECRETS_META_PATH) $(APP_ENV_VARS_PATH) $(AWS_APP_SECRETS_NAME)

$(APP_ENV_VARS_PATH):
	./export-secret.sh $(AWS_CLI_PATH) $(APP_ENV_VARS_PATH) $(AWS_APP_SECRETS_NAME)

$(AWS_KMS_META_PATH):
	./create-cosign-key.sh  $(AWS_CLI_PATH) $(AWS_KMS_META_PATH) $(AUTH_ENV_VARS_PATH)

$(AWS_ECR_META_PATH):
	./create-ecr-repository.sh $(AWS_CLI_PATH) $(AWS_ECR_META_PATH) $(AWS_ECR_REPO_NAME)


# ----- Recipes ------------------------------------------------------------------------
push:
	./upload-to-ecr.sh $(AWS_CLI_PATH) $(AWS_ECR_META_PATH) $(IMAGE_NAME)
