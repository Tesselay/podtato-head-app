# ----- Configuration ------------------------------------------------------------------
AWS_CLI_PATH          := .aws/
APP_ENV_VARS_PATH     := ../../app.env
META_ENV_VARS_PATH    := ../../meta.env

AWS_SECRETS_META_PATH := aws-secretmanager.json
AWS_APP_SECRETS_NAME  := practice-pha-app-secrets

AWS_KMS_META_PATH     := aws-kms.json
# Leave empty if new one should be created or read from AWS_KMS_META_PATH
AWS_KMS_KEYID         :=

AWS_ECR_META_PATH     := aws-ecr.json

-include $(META_ENV_VARS_PATH)

# ----- Phony Targets ------------------------------------------------------------------
.PHONY: init push \
		export-secrets export-kms

init: $(AWS_SECRETS_META_PATH) $(APP_ENV_VARS_PATH) $(AWS_KMS_META_PATH) $(META_ENV_VARS_PATH) $(AWS_ECR_META_PATH)


# ----- Init ---------------------------------------------------------------------------
$(AWS_SECRETS_META_PATH): $(APP_ENV_VARS_PATH)
	./create-secret.sh $(AWS_CLI_PATH) $(AWS_SECRETS_META_PATH) $(APP_ENV_VARS_PATH) $(AWS_APP_SECRETS_NAME)

$(APP_ENV_VARS_PATH) export-secrets:
	./export-secret.sh $(AWS_CLI_PATH) $(APP_ENV_VARS_PATH) $(AWS_APP_SECRETS_NAME)

$(AWS_KMS_META_PATH):
	./create-cosign-key.sh $(AWS_CLI_PATH) $(AWS_KMS_META_PATH) $(AWS_KMS_KEYID)

$(META_ENV_VARS_PATH) export-kms:
	./export-cosign.sh $(AWS_KMS_META_PATH) $(META_ENV_VARS_PATH)

$(AWS_ECR_META_PATH): $(META_ENV_VARS_PATH)
	./create-ecr-repository.sh $(AWS_CLI_PATH) $(AWS_ECR_META_PATH) $(IMAGE_NAME) $(META_ENV_VARS_PATH)


# ----- Recipes ------------------------------------------------------------------------
login:
	docker run --rm -it \
	    -v ./$(AWS_CLI_PATH):/root/.aws \
		public.ecr.aws/aws-cli/aws-cli ecr get-login-password \
		| docker login --username AWS --password-stdin $$(echo $(IMAGE_NAME) \
		| awk 'BEGIN{ FS = "/" }; { print $$1 }')

push:
	./upload-to-ecr.sh $(AWS_CLI_PATH) $(AWS_ECR_META_PATH) $(IMAGE_NAME)
