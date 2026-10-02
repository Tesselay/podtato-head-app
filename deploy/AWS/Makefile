# ----- Configuration ------------------------------------------------------------------
AWS_CLI_PATH       := .aws/
APP_ENV_VARS_PATH  := ../../app.env
AUTH_ENV_VARS_PATH := ../../auth.env

AWS_SECRETS_META   := aws-secretmanager.json
AWS_SECRET_NAME    := practice-pha-secrets

AWS_KMS_META       := aws-kms.json

AWS_ECR_META       := aws-ecr.json
AWS_ECR_REPO       := practice-pha-repository


# ----- Phony Targets ------------------------------------------------------------------
.PHONY: init export-secrets \
		upload-image

init: $(AWS_SECRETS_META) $(APP_ENV_VARS_PATH) export-secrets $(AWS_ECR_META) $(AWS_KMS_META)
export-secrets: $(APP_ENV_VARS_PATH)


# ----- Init ---------------------------------------------------------------------------
$(AWS_SECRETS_META): $(APP_ENV_VARS_PATH)
	./create-secret.sh $(AWS_CLI_PATH) $(AWS_SECRETS_META) $(APP_ENV_VARS_PATH) $(AWS_SECRET_NAME)

$(APP_ENV_VARS_PATH):
	./export-secret.sh $(AWS_CLI_PATH) $(APP_ENV_VARS_PATH) $(AWS_SECRET_NAME)

$(AWS_ECR_META):
	./create-ecr-repository.sh $(AWS_CLI_PATH) $(AWS_ECR_META) $(AWS_ECR_REPO)

$(AWS_KMS_META):
	./create-cosign-key.sh  $(AWS_CLI_PATH) $(AWS_KMS_META) $(AUTH_ENV_VARS_PATH)


# ----- Recipes ------------------------------------------------------------------------
upload-image:
	./upload-to-ecr.sh $(AWS_CLI_PATH) $(AWS_ECR_META) $(IMAGE_NAME)
