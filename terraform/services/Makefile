export AWS_PROFILE=sdlc
export TF_VAR_AWS_ACCESS_KEY_ID=$(shell aws configure get aws_access_key_id --profile ${AWS_PROFILE})
export TF_VAR_AWS_SECRET_ACCESS_KEY=$(shell aws configure get aws_secret_access_key --profile ${AWS_PROFILE})
export TF_VAR_AWS_DEFAULT_REGION=$(shell aws configure get region --profile ${AWS_PROFILE})


init:
	terraform14 init -force-copy -get=true -input=false -lock=true -lock-timeout=600s ../topology

get:
	terraform14 get ../topology

plan:
	$(eval Environment := $(shell terraform14 workspace show))
	terraform14 plan -var-file="$(Environment).tfvars" ../topology

# make plan-target TARGETS="target1 target2 target3"
plan-target:
	$(eval Environment := $(shell terraform14 workspace show))
	target_command=""; \
	for target in $(TARGETS); do \
	target_command+=" -target "; \
	target_command+=$$target; \
	done; \
	terraform14 plan -var-file="$(Environment).tfvars" $$target_command ../topology

destroy:
	$(eval Environment := $(shell terraform14 workspace show))
	terraform14 destroy -var-file="$(Environment).tfvars" ../topology

# make destroy-target TARGETS="module.burnell"
destroy-target:
	$(eval Environment := $(shell terraform14 workspace show))
	target_command=""; \
	for target in $(TARGETS); do \
	target_command+=" -target "; \
	target_command+=$$target; \
	done; \
	terraform14 destroy -var-file="$(Environment).tfvars" $$target_command ../topology

destroy-service:
	$(eval Service :=  $(filter-out $@,$(MAKECMDGOALS)))
	make destroy-target TARGETS="module.$(Service)"
%:
	@:

unlock:
	$(eval LOCKID :=  $(filter-out $@,$(MAKECMDGOALS)))
	terraform14 force-unlock $(LOCKID) ../topology
%:
	@:

workspace:
	terraform14 workspace show

workspace-new:
	$(eval WORKSPACE :=  $(filter-out $@,$(MAKECMDGOALS)))
	terraform14 workspace new $(WORKSPACE) ../topology
%:
	@:

workspace-select:
	$(eval WORKSPACE :=  $(filter-out $@,$(MAKECMDGOALS)))
	terraform14 workspace select $(WORKSPACE) ../topology
%:
	@:

workspace-list:
	terraform14 workspace list ../topology

apply:
	$(eval Environment := $(shell terraform14 workspace show))
	terraform14 apply -var-file="$(Environment).tfvars"  ../topology

# make apply-target TARGETS="target1 target2 target3"
apply-target:
	$(eval Environment := $(shell terraform14 workspace show))
	target_command=""; \
	for target in $(TARGETS); do \
	target_command+=" -target "; \
	target_command+=$$target; \
	done; \
	terraform14 apply -var-file="dev.tfvars" -var-file="dev-deploy.tfvars" $$target_command ../topology

apply-service:
	$(eval Service := $(filter-out $@,$(MAKECMDGOALS)))
	make apply-target TARGETS="module.$(Service)"
%:
	@:

build-services:
	aws codebuild start-build --project-name burnell-cb --profile sdlc > /dev/null
	aws codebuild start-build --project-name resnik-cb --profile sdlc > /dev/null
	aws codebuild start-build --project-name curie-cb --profile sdlc > /dev/null
	aws codebuild start-build --project-name conwell-cb --profile sdlc > /dev/null
	aws codebuild start-build --project-name meitner-cb --profile sdlc > /dev/null
%:
	@:

build-services-stop:
	aws codebuild stop-build --project-name burnell-cb --profile sdlc > /dev/null
	aws codebuild stop-build --project-name resnik-cb --profile sdlc > /dev/null
	aws codebuild stop-build --project-name curie-cb --profile sdlc > /dev/null
	aws codebuild stop-build --project-name conwell-cb --profile sdlc > /dev/null
	aws codebuild stop-build --project-name meitner-cb --profile sdlc > /dev/null
%:
	@:

build-service:
	$(eval ARGS := $(filter-out $@,$(MAKECMDGOALS)))
	$(eval Environment := $(word 1, $(ARGS)))
	$(eval Service := $(word 2, $(ARGS)))
	aws codebuild start-build --project-name ${Service}-cb --Environment-variables-override name=Environment,value=${Environment} --profile sdlc
%:
	@:

refresh-service:
	$(eval ARGS := $(filter-out $@,$(MAKECMDGOALS)))
	$(eval Environment := $(word 1, $(ARGS)))
	$(eval Service := $(word 2, $(ARGS)))
	./scripts/refresh-service.sh "${Environment}" "${Service}"
%:
	@:

refresh-services:
	$(eval ENV := $(filter-out $@,$(MAKECMDGOALS)))
	./scripts/refresh-service.sh "${Environment}" conwell \
	./scripts/refresh-service.sh "${Environment}" meitner \
	./scripts/refresh-service.sh "${ENVIRONMENT}" curie \
	./scripts/refresh-service.sh "${ENVIRONMENT}" burnell \
	./scripts/refresh-service.sh "${ENVIRONMENT}" resnik
%:
	@:


cancel-refresh-service:
	$(eval ARGS := $(filter-out $@,$(MAKECMDGOALS)))
	$(eval ENVIRONMENT := $(word 1, $(ARGS)))
	$(eval Service := $(word 2, $(ARGS)))
	./scripts/cancel-refresh-service.sh "${ENVIRONMENT}" "${Service}"
%:
	@:

cancel-refresh-services:
	$(eval ENV := $(filter-out $@,$(MAKECMDGOALS)))
	./scripts/cancel-refresh-service.sh "${ENVIRONMENT}" conwell; \
	./scripts/cancel-refresh-service.sh "${ENVIRONMENT}" meitner; \
	./scripts/cancel-refresh-service.sh "${ENVIRONMENT}" curie; \
	./scripts/cancel-refresh-service.sh "${ENVIRONMENT}" burnell; \
	./scripts/cancel-refresh-service.sh "${ENVIRONMENT}" resnik
%:
	@:

remove-tag:
	$(eval TAG := $(filter-out $@,$(MAKECMDGOALS)))
	git fetch;
	git push origin :refs/tags/"${TAG}"; \
	git tag -d "${TAG}";

create-service-secret:
	$(eval ARGS := $(filter-out $@,$(MAKECMDGOALS)))
	$(eval ENVIRONMENT := $(word 1, $(ARGS)))
	$(eval Service := $(word 2, $(ARGS)))
	$(eval SECRET_FILE := $(word 3, $(ARGS)))
	aws secretsmanager create-secret --name "systemd-${ENVIRONMENT}-${Service}" --secret-string "$(cat ${SECRET_FILE})"

get-service-secret:
	$(eval ARGS := $(filter-out $@,$(MAKECMDGOALS)))
	$(eval ENVIRONMENT := $(word 1, $(ARGS)))
	$(eval Service := $(word 2, $(ARGS)))
	@aws secretsmanager get-secret-value --secret-id "systemd-${ENVIRONMENT}-${Service}" | jq -r '.SecretString' | tee ${ENVIRONMENT}.${Service}.service

update-service-secret:
	$(eval ARGS := $(filter-out $@,$(MAKECMDGOALS)))
	$(eval ENVIRONMENT := $(word 1, $(ARGS)))
	$(eval Service := $(word 2, $(ARGS)))
	echo 'aws secretsmanager update-secret --secret-id "systemd-${ENVIRONMENT}-${Service}" --secret-string $$(cat "${ENVIRONMENT}.${Service}.service")'




