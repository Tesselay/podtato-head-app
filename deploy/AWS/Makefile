# ----- Configuration ------------------------------------------------------------------
AWS_CLI_PATH     := .aws/
ENV_VARS_PATH    := ../../app.env

AWS_SECRETS_META := aws-secretmanager.json
AWS_SECRET_NAME  := practice-pha-secrets

AWS_ECR_META     := aws-ecr.json
AWS_ECR_REPO     := practice-pha-repository


# ----- Phony Targets ------------------------------------------------------------------
.PHONY: init-secrets export-secrets init-ecr

init-secrets: $(AWS_SECRETS_META) $(ENV_VARS_PATH)
export-secrets: $(ENV_VARS_PATH)
init-ecr: $(AWS_ECR_META)

# ----- Recipes ------------------------------------------------------------------------
$(AWS_SECRETS_META): $(ENV_VARS_PATH)
	./create-secret.sh $(AWS_CLI_PATH) $(AWS_SECRETS_META) $(ENV_VARS_PATH) $(AWS_SECRET_NAME)

export-secrets $(ENV_VARS_PATH):
	./export-secret.sh $(AWS_CLI_PATH) $(ENV_VARS_PATH) $(AWS_SECRET_NAME)

$(AWS_ECR_META):
	./create-ecr-repository.sh $(AWS_CLI_PATH) $(AWS_ECR_META) $(AWS_ECR_REPO)
