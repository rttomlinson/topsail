# # No slash at the end, please
# REPO_PREFIX := rttomlinson
# BASE_REPO := rttomlinson
# # We want to update the build-tools container image without producing
# # extra stdout output that might spoil the data output of the consequently
# # called command. `docker run --pull always` will print the pulled image
# # hash and there is no way to silence that, hence pull in a separate command.
# BUILD_TOOLS := docker pull -q $(REPO_PREFIX)/build-tools >/dev/null 2>&1; \
#                docker run --rm -i $(REPO_PREFIX)/build-tools

# # This weird double assignment is to resolve the value instead of
# # calculating it at every call site
# GIT_COMMIT ?= $(shell git rev-parse --short=10 HEAD 2>/dev/null)
# GIT_COMMIT := $(GIT_COMMIT)
# GIT_BRANCH ?= $(shell git symbolic-ref -q HEAD |sed 's/refs\/heads\///')
# GIT_BRANCH := $(GIT_BRANCH)
# GIT_TAG ?= $(shell git describe --tags)
# GIT_TAG := $(GIT_TAG)
# CWD ?= $(shell pwd)
# BUILD_VERSION ?= $(GIT_BRANCH)-$(GIT_COMMIT)
# BUILD_VERSION := $(BUILD_VERSION)
# ghprbTargetBranch ?= local
# GIT_ENV ?= development
# GIT_COMMIT_TAG := $(GIT_COMMIT)-$(foo_STAGE)
# GHPRB_ID_TAG ?= ghprb-$(GITHUB_PR_ID)-$(BUILD_VERSION)
# GHPRB_ID_TAG := $(GHPRB_ID_TAG)
# # TODO Clean up all other tag variable uses except CONTAINER_TAG
# CONTAINER_TAG := $(GIT_COMMIT_TAG)
# GIT_BRANCH_HASH := $(shell $(BUILD_TOOLS) sha256 $(GIT_BRANCH) 8)
# GET_CLOUD_SPEC := $(BUILD_TOOLS) get_validated_spec \
# 		--token BUILD_NUMBER=${BUILD_NUMBER} \
# 		--token BUILD_VERSION=${BUILD_VERSION} \
# 		--token GIT_BRANCH=${GIT_BRANCH} \
# 		--token GIT_COMMIT=${GIT_COMMIT} \
# 		--token FEATURE_BRANCH_HOSTNAME=${FEATURE_BRANCH_HOSTNAME} \
# 		--token GITHUB_PR_ID=${GITHUB_PR_ID} \
# 		--token GHPRB_ID_TAG=${GHPRB_ID_TAG} \
# 		--token GIT_BRANCH_HASH=${GIT_BRANCH_HASH}
# GIT_CHANGELOG := git log --format='%H|%aN|%aE|%cN|%cE|%s' ${GIT_PREVIOUS_SUCCESSFUL_COMMIT}..${GIT_COMMIT}
# JSONIFY_CHANGELOG := jq -nRc '[inputs|split("|")|{hash:.[0],authorName:.[1],authorEmail:.[2],committerName:.[3],committerEmail:.[4],subject:.[5]}]'

# MOCK_SCENARIO ?= 'unit-test'

# .PHONY: echo-version
# echo-version:
# 	@echo $(BUILD_VERSION)

# .PHONY: echo-container-tag
# echo-container-tag:
# 	@echo $(CONTAINER_TAG)

# .PHONY: echo-container-image-%
# echo-container-image-%:
# 	@echo $(BASE_REPO)/$*:$(CONTAINER_TAG)

# .PHONY: echo-cloud-spec
# echo-cloud-spec:
# 	@CLOUD_SPEC=$$(${GET_CLOUD_SPEC} < ${MY_CLOUD_SPEC}) && \
# 		echo "$$CLOUD_SPEC"

# .PHONY: help build-all
# .PHONY: docker-push-all-%
# .PHONY: docker-push-commit-%
# .PHONY: docker-push-tag-%
# .PHONY: docker-rollback-push-tag-%
# .PHONY: docker-push-branch-%
# .PHONY: docker-tag-all-%
# .PHONY: docker-tag-branch-%
# .PHONY: docker-tag-gittag-%
# .PHONY: docker-rollback-tag-gittag-%
# .PHONY: docker-commit-rollback-tag-gittag-%
# .PHONY: docker-tag-last-release-%
# .PHONY: docker-push-last-release-%
# .PHONY: docker-tag-version-%
# .PHONY: docker-push-version-%
# .PHONY: docker-tag-pr-%
# .PHONY: docker-push-pr-%

# What about an infra definition?
# For shared resources?
# Or are we splitting hairs here? Like, what is infra and what is application?
# Why _cant_ we also all the load balancer part of the deployment?
# There's no reason that we can't also create the load balancer and listener on the fly?
# Now we're at certs
# Now we're at DNS - We can verify is DNS is verifiable it's basically what it was designed to do
# Basically everything can be created except for DNS which can be completely out of our control
# DNS Optional
# But also certificate validation is also optional, no?
# Is it possible to create a "valid" cert from nothing? Or a shared cert?
# Is it possible to set a self-signed cert on an ALB?
# Is it possible to upload a self-signed cert to AWS Certificate Manager?


# # Add the following 'help' target to your Makefile
# # And add help text after each target name starting with '\#\#'
# help:	## Show this help message.
# 	@echo 'usage: make [target] ...'
# 	@echo
# 	@echo 'targets:'
# 	@egrep '^(.+)\:\s##\s(.+)' $(MAKEFILE_LIST) |sed 's/^/  /' | column -t -c 2 -s ':#'

# clean:	## run all clean targets
# clean: ui-clean bar-clean

# docker-push-all-%: docker-push-commit-% docker-push-tag-% docker-push-branch-%
# 	@echo pushed all container tags

# docker-push-commit-%:
# 	docker image push $(REPO_PREFIX)/$(BASE_REPO)/$*:$(GIT_COMMIT_TAG)
# 	@echo pushed docker container $(BASE_REPO)/$*:$(GIT_COMMIT_TAG)

# docker-push-tag-%:
# 	docker image push $(REPO_PREFIX)/$(BASE_REPO)/$*:$(GIT_TAG)
# 	@echo pushed docker container $(BASE_REPO)/$*:$(GIT_TAG)

# docker-rollback-push-tag-%:
# 	docker image push $(REPO_PREFIX)/$(BASE_REPO)/$*:$(GIT_ENV)-live
# 	@echo pushed docker container $(BASE_REPO)/$*:$(GIT_ENV)-live	

# docker-push-branch-%:
# 	docker image push $(REPO_PREFIX)/$(BASE_REPO)/$*:$(GIT_BRANCH)
# 	@echo pushed docker container $(BASE_REPO)/$*:$(GIT_BRANCH)

# docker-push-latest-%:
# 	docker image push $(REPO_PREFIX)/$(BASE_REPO)/$*:latest
# 	@echo pushed docker container $(BASE_REPO)/$*:latest

# docker-tag-all-%:
# 	@echo tagged docker container with all tags

# docker-tag-branch-%:
# 	-docker image pull $(REPO_PREFIX)/$(BASE_REPO)/$*:$(GIT_COMMIT_TAG)
# 	docker image tag $(REPO_PREFIX)/$(BASE_REPO)/$*:$(GIT_COMMIT_TAG) $(REPO_PREFIX)/$(BASE_REPO)/$*:$(GIT_BRANCH)
# 	@echo tagged docker container $(BASE_REPO)$*:$(GIT_COMMIT_TAG) as $(BASE_REPO)/$*:$(GIT_BRANCH)

# docker-tag-gittag-%:
# 	-docker image pull $(REPO_PREFIX)/$(BASE_REPO)/$*:$(GIT_COMMIT_TAG)
# 	docker image tag $(REPO_PREFIX)/$(BASE_REPO)/$*:$(GIT_COMMIT_TAG) $(REPO_PREFIX)/$(BASE_REPO)/$*:$(GIT_TAG)
# 	@echo tagged docker container $(BASE_REPO)$*:$(GIT_COMMIT_TAG) as $(BASE_REPO)/$*:$(GIT_TAG)

# docker-rollback-tag-gittag-%:
# 	-docker image pull $(REPO_PREFIX)/$(BASE_REPO)/$*:$(GIT_ENV)-last-stable
# 	docker image tag $(REPO_PREFIX)/$(BASE_REPO)/$*:$(GIT_ENV)-last-stable $(REPO_PREFIX)/$(BASE_REPO)/$*:$(GIT_ENV)-live
# 	@echo tagged docker container $(BASE_REPO)$*:$(GIT_ENV)-last-stable as $(BASE_REPO)/$*:$(GIT_ENV)-live

# docker-commit-rollback-tag-gittag-%:
# 	-docker image pull $(REPO_PREFIX)/$(BASE_REPO)/$*:$(GIT_COMMIT_TAG)
# 	docker image tag $(REPO_PREFIX)/$(BASE_REPO)/$*:$(GIT_COMMIT_TAG) $(REPO_PREFIX)/$(BASE_REPO)/$*:$(GIT_ENV)-live
# 	@echo tagged docker container $(BASE_REPO)$*:$(GIT_COMMIT_TAG) as $(BASE_REPO)/$*:$(GIT_ENV)-live

# docker-tag-latest-%:
# 	-docker image pull $(REPO_PREFIX)/$(BASE_REPO)/$*:$(GIT_COMMIT_TAG)
# 	docker image tag $(REPO_PREFIX)/$(BASE_REPO)/$*:$(GIT_COMMIT_TAG) $(REPO_PREFIX)/$(BASE_REPO)/$*:latest
# 	@echo tagged docker container $(BASE_REPO)$*:$(GIT_COMMIT_TAG) as $(BASE_REPO)/$*:latest

# docker-tag-last-release-%:
# 	-docker image pull $(REPO_PREFIX)/$(BASE_REPO)/$*:$(GIT_ENV)-live
# 	docker image tag $(REPO_PREFIX)/$(BASE_REPO)/$*:$(GIT_ENV)-live $(REPO_PREFIX)/$(BASE_REPO)/$*:$(GIT_ENV)-last-stable
# 	@echo tagged docker container $(BASE_REPO)$*:$(GIT_ENV)-live as $(BASE_REPO)/$*:$(GIT_ENV)-last-stable

# docker-push-last-release-%:
# 	docker image push $(REPO_PREFIX)/$(BASE_REPO)/$*:$(GIT_ENV)-last-stable
# 	@echo pushed docker container $(BASE_REPO)/$*:$(GIT_ENV)-last-stable

# docker-tag-version-%:
# 	-docker image pull $(REPO_PREFIX)/$(BASE_REPO)/$*:$(GIT_COMMIT_TAG)
# 	docker image tag $(REPO_PREFIX)/$(BASE_REPO)/$*:$(GIT_COMMIT_TAG) $(REPO_PREFIX)/$(BASE_REPO)/$*:$(BUILD_VERSION)
# 	@echo tagged docker container $(BASE_REPO)/$*:$(GIT_COMMIT_TAG) as $(BASE_REPO)/$*:$(BUILD_VERSION)

# docker-push-version-%:
# 	docker image push $(REPO_PREFIX)/$(BASE_REPO)/$*:$(BUILD_VERSION)
# 	@echo pushed docker container $(BASE_REPO)/$*:$(BUILD_VERSION)

# docker-tag-pr-%:
# 	-docker image pull $(REPO_PREFIX)/$(BASE_REPO)/$*:$(GIT_COMMIT_TAG)
# 	docker image tag $(REPO_PREFIX)/$(BASE_REPO)/$*:$(GIT_COMMIT_TAG) $(REPO_PREFIX)/$(BASE_REPO)/$*:$(GHPRB_ID_TAG)
# 	@echo tagged docker container $(BASE_REPO)/$*:$(GIT_COMMIT_TAG) as $(BASE_REPO)/$*:$(GHPRB_ID_TAG)

# docker-push-pr-%:
# 	docker image push $(REPO_PREFIX)/$(BASE_REPO)/$*:$(GHPRB_ID_TAG)
# 	@echo pushed docker container $(BASE_REPO)/$*:$(GHPRB_ID_TAG)

# docker-prune:
# 	docker network prune -f
# 	docker volume prune -f

# unittest: ui-unit-test bar-unit-test

# datadog-upload-sourcemap:
# 	@docker container run \
# 			--env "DATADOG_API_KEY=$(DATADOG_API_KEY)" \
# 			--entrypoint '' \
# 			--rm \
# 			$(REPO_PREFIX)/$(BASE_REPO)/$(BASE_REPO)-foo-build:$(GIT_COMMIT_TAG) \
# 				npx --no-install @datadog/datadog-ci \
# 					sourcemaps upload ./build/output/static \
# 					--service=web \
# 					--release-version=$(BUILD_VERSION) \
# 					--minified-path-prefix=/static

# run-dev: docker-network-setup
# 	docker run -p 80:80 -p 443:443 --rm \
# 		--name foo-dev.$(BASE_REPO).com \
# 		--network foo \
# 		-e CLOUD_ENV="development" \
# 		-e GATEWAY_ENDPOINT="gateway-steelix.$(BASE_REPO).com" \
# 		-e APP_ENDPOINT="foo-dev.$(BASE_REPO).com" \
# 		-e bar_ENDPOINT="http://bar:4000" \
# 		-e SEGMENT_KEY="" \
# 		$(REPO_PREFIX)/$(BASE_REPO)/$(BASE_REPO)-foo:$(GIT_COMMIT_TAG)

# build-and-run: ui-build-dev ui-build-final run-dev

# devbranch:
# 	git checkout develop
# 	git pull
# 	git checkout -b $(GIT_BRANCH)-develop
# 	git merge origin/$(GIT_BRANCH)
# 	git push origin $(GIT_BRANCH)-develop

# bar-clean:
# 	rm -rf ./build/bar ./build/bar-output

# bar-prep:
# 	mkdir -p ./build/bar

# .PHONY: bar-build-dev
# bar-build-dev: bar-clean bar-prep
# 	rsync -a --exclude='/bar/node_modules/**' \
# 		./bar/Dockerfile* \
# 		./bar/package.json \
# 		./bar/yarn.lock \
# 		./bar/.babelrc.cjs \
# 		./bar/eslint.config.cjs \
# 		./bar/*.js \
# 		./bar/mock \
# 		./bar/packages \
# 		./bar/src \
# 		./bar/test\
# 			./build/bar
# 	MAKEFILE=$$(cat Makefile) && \
# 	docker image build --pull \
# 		-f ./build/bar/Dockerfile.dev \
# 		-t $(REPO_PREFIX)/$(BASE_REPO)/$(BASE_REPO)-bar-build:$(GIT_COMMIT_TAG) \
# 			--label Makefile="$$MAKEFILE" \
# 			--build-arg BUILD_VERSION=$(BUILD_VERSION) \
# 				./build/bar	

# .PHONY: bar-build-mock
# bar-build-mock: bar-clean bar-prep
# 	rsync -a ./bar/Dockerfile.mock ./build/bar
# 	CLOUD_SPEC=$$(${GET_CLOUD_SPEC} < ${bar_CLOUD_SPEC}) && \
# 	docker image build \
# 		-f ./build/bar/Dockerfile.mock \
# 		-t $(REPO_PREFIX)/$(BASE_REPO)/$(BASE_REPO)-bar-mock:$(GIT_COMMIT_TAG) \
# 			--label git_repository="$(BASE_REPO)/frontend" \
# 			--label git_branch=$(GIT_BRANCH) \
# 			--label feature_branch_hostname=$(FEATURE_BRANCH_HOSTNAME) \
# 			--label github_pr_id=$(GITHUB_PR_ID) \
# 			--label cloud_spec="$$CLOUD_SPEC" \
# 			--build-arg git_commit_tag=$(GIT_COMMIT_TAG) \
# 			--build-arg mock_scenario=$(MOCK_SCENARIO) \
# 			./build/bar	

# .PHONY: bar-output
# bar-output: bar-clean
# 	mkdir -p ./build/bar-output
# 	docker container run --rm --entrypoint '' \
# 		--volume ${PWD}/build/bar-output:/build-output \
# 		$(REPO_PREFIX)/$(BASE_REPO)/$(BASE_REPO)-bar-build:$(GIT_COMMIT_TAG) \
# 			rsync -av \
# 				--exclude='/node_modules/**' \
# 				--exclude='/mock/**' \
# 				--exclude='/test/**' \
# 				--exclude='/.babelrc.cjs' \
# 				--exclude='/eslint.config.cjs' \
# 				--exclude='/jest-setup.js' \
# 				/app/ /build-output

# .PHONY: bar-build-final
# bar-build-final: bar-clean bar-prep bar-output
# 	CLOUD_SPEC=$$(${GET_CLOUD_SPEC} < ${bar_CLOUD_SPEC}) && \
# 	docker image build --pull \
# 		-f ./build/bar-output/Dockerfile.prod \
# 		-t $(REPO_PREFIX)/$(BASE_REPO)/$(BASE_REPO)-bar:$(GIT_COMMIT_TAG) \
# 			--label git_branch=$(GIT_BRANCH) \
# 			--label feature_branch_hostname=$(FEATURE_BRANCH_HOSTNAME) \
# 			--label github_pr_id=$(GITHUB_PR_ID) \
# 			--label cloud_spec="$$CLOUD_SPEC" \
# 			--label build_number="$(BUILD_NUMBER)" \
# 			--label build_job_url="$(BUILD_URL)" \
# 			--build-arg BUILD_VERSION=$(BUILD_VERSION) \
# 					./build/bar-output

# .PHONY: bar-lint
# bar-lint:
# 	mkdir -p ./build/bar/testreports
# 	docker container run --rm \
# 		--volume ${PWD}/build/bar/testreports:/app/testreports \
# 		$(REPO_PREFIX)/$(BASE_REPO)/$(BASE_REPO)-bar-build:$(GIT_COMMIT_TAG) \
# 			yarn lint-ci

# .PHONY: bar-unit-test
# bar-unit-test:
# 	mkdir -p ./build/bar/testreports
# 	docker container run --entrypoint '' --rm \
# 		--volume ${PWD}/build/bar/testreports:/app/testreports \
# 		$(REPO_PREFIX)/$(BASE_REPO)/$(BASE_REPO)-bar-build:$(GIT_COMMIT_TAG) \
# 			yarn test-ci
		
# # Just an alias
# .PHONY: bar-test
# bar-test: bar-unit-test

# .PHONY: bar-run-dev
# bar-run-dev: docker-network-setup
# 	docker run -p 4000:4000 --rm \
# 		--network foo \
# 		--name bar \
# 		-e STAGE=dev \
# 		-e GATEWAY_HOST="gateway-steelix.$(BASE_REPO).com" \
# 		-e HTTP_CLIENT_TIMEOUT=120000 \
# 		$(REPO_PREFIX)/$(BASE_REPO)/$(BASE_REPO)-bar:$(GIT_COMMIT_TAG)

# .PHONY: bar-run-mock
# bar-run-mock: docker-network-setup bar-build-mock
# 	docker run -p 4000:4000 --rm \
# 		--network foo \
# 		--name bar \
# 		-e STAGE=dev \
# 		-e GATEWAY_HOST="gateway-steelix.$(BASE_REPO).com" \
# 		-e HTTP_CLIENT_TIMEOUT=120000 \
# 		$(REPO_PREFIX)/$(BASE_REPO)/$(BASE_REPO)-bar-mock:$(GIT_COMMIT_TAG)

# .PHONY: ui-clean
# ui-clean:
# 	rm -rf ./build/ui

# .PHONY: ui-prep
# ui-prep:
# 	mkdir -p ./build/ui/cache ./build/ui/testreports

# .PHONY: ui-build-dev
# ui-build-dev: ui-clean ui-prep
# 	rsync -a --exclude='/bar/node_modules/**' \
# 		./package.json \
# 		./yarn.lock \
# 		./babel.config.js \
# 		./eslint.config.js \
# 		./webpack.config.js \
# 		./Dockerfile \
# 		./packages \
# 		./__mocks__ \
# 		./scripts \
# 		./bar \
# 		./tsconfig.json \
# 			./build/ui/cache
# 	MAKEFILE=$$(cat Makefile) && \
# 	docker image build --pull \
# 		-t $(REPO_PREFIX)/$(BASE_REPO)/$(BASE_REPO)-foo-build:$(GIT_COMMIT_TAG) \
# 			--label Makefile="$$MAKEFILE" \
# 			--build-arg BUILD_VERSION=$(BUILD_VERSION) \
# 			--build-arg GITHUB_TOKEN=$(GITHUB_TOKEN) \
# 			./build/ui/cache
# 	make ui-clean

# .PHONY: ui-lint
# ui-lint: ui-prep
# 	docker container run --entrypoint '' --rm \
# 		--volume ${PWD}/build/ui/testreports:/app/testreports \
# 		$(REPO_PREFIX)/$(BASE_REPO)/$(BASE_REPO)-foo-build:$(GIT_COMMIT_TAG) \
# 			yarn lint-ci

# .PHONY: ui-unit-test
# ui-unit-test: ui-prep
# 	docker container run --entrypoint '' --rm \
# 	--volume ${PWD}/build/ui/testreports:/app/testreports \
# 	$(REPO_PREFIX)/$(BASE_REPO)/$(BASE_REPO)-foo-build:$(GIT_COMMIT_TAG) \
# 		yarn test-ci
	
# # Just an alias
# .PHONY: ui-test
# ui-test: ui-unit-test

# .PHONY: ui-output
# ui-output:
# 	mkdir -p ./build/ui/output/cache
# 	docker container run --rm --entrypoint '' \
# 		--volume $(CWD)/build/ui/output/cache:/build \
# 		$(REPO_PREFIX)/$(BASE_REPO)/$(BASE_REPO)-foo-build:$(GIT_COMMIT_TAG) \
# 			rsync -av ./build/output/ /build/

# .PHONY: ui-build-final
# ui-build-final: ui-output
# 	rsync -av ./buildfiles/$(BASE_REPO)-foo/ ./build/ui/output/
# 	CHANGELOG=$$(${GIT_CHANGELOG} | ${JSONIFY_CHANGELOG}) \
# 	CLOUD_SPEC=$$(${GET_CLOUD_SPEC} < ${foo_CLOUD_SPEC}) && \
# 	MSG_1=$$(cat ${APPROVAL_MSG_1}) && \
# 	MSG_2=$$(cat ${APPROVAL_MSG_2}) && \
# 	MSG_3=$$(cat ${RELEASE_NOTIFICATION_MSG}) && \
# 	docker image build --pull \
# 		-t $(REPO_PREFIX)/$(BASE_REPO)/$(BASE_REPO)-foo:$(GIT_COMMIT_TAG) \
# 			--label git_repository="$(BASE_REPO)/frontend" \
# 			--label git_branch=$(GIT_BRANCH) \
# 			--label feature_branch_hostname=$(FEATURE_BRANCH_HOSTNAME) \
# 			--label github_pr_id=$(GITHUB_PR_ID) \
# 			--label cloud_spec="$$CLOUD_SPEC" \
# 			--label changelog="$$CHANGELOG" \
# 			--label build_number="$(BUILD_NUMBER)" \
# 			--label build_job_url="$(BUILD_URL)" \
# 			--label approval_msg_1="$$MSG_1" \
# 			--label approval_msg_2="$$MSG_2" \
# 			--label release_notification_msg="$$MSG_3" \
# 			--build-arg BUILD_VERSION=$(BUILD_VERSION) \
# 			--build-arg GITHUB_TOKEN=$(GITHUB_TOKEN) \
# 			--build-arg REPO_PREFIX=$(REPO_PREFIX) \
# 				./build/ui/output

# .PHONY: ui-run-dev
# ui-run-dev:
# 	docker run -p 443:443 -v $(CWD)/certificates:/app/certs --rm \
# 		--name foo-dev.$(BASE_REPO).com \
# 		-e CERT_NAME="server" \
# 		-e CLOUD_ENV="steelix" \
# 		-e ENABLE_NGINX_OVERRIDES=1 \
# 		-e GATEWAY_ENDPOINT="foo-dev.$(BASE_REPO).com/gateway" \
# 		-e APP_ENDPOINT="foo-dev.$(BASE_REPO).com" \
# 		-e bar_ENDPOINT="https://app.prestaging.$(BASE_REPO).com" \
# 		-e SEGMENT_KEY="" \
# 		$(REPO_PREFIX)/$(BASE_REPO)/$(BASE_REPO)-foo:$(GIT_COMMIT_TAG)

# .PHONY: ui-run-local-bar
# ui-run-local-bar: docker-network-setup
# 	docker run -p 443:443 -v $(CWD)/certificates:/app/certs --rm \
# 		--name foo-dev.$(BASE_REPO).com \
# 		--network foo \
# 		-e CERT_NAME="server" \
# 		-e CLOUD_ENV="steelix" \
# 		-e ENABLE_NGINX_OVERRIDES=1 \
# 		-e GATEWAY_ENDPOINT="foo-dev.$(BASE_REPO).com/gateway" \
# 		-e APP_ENDPOINT="foo-dev.$(BASE_REPO).com" \
# 		-e bar_ENDPOINT="http://bar:4000" \
# 		-e SEGMENT_KEY="" \
# 		$(REPO_PREFIX)/$(BASE_REPO)/$(BASE_REPO)-foo:$(GIT_COMMIT_TAG)

# .PHONY: docker-network-setup
# docker-network-setup:
# 	docker network inspect foo &>/dev/null \
# 		|| docker network create foo &>/dev/null

# .PHONY: cypress-clean
# cypress-clean:
# 	rm -rf ./build/cypress

# .PHONY: cypress-prep
# cypress-prep:
# 	mkdir -p ./build/cypress

# .PHONY: cypress-build
# cypress-build: cypress-clean cypress-prep
# 	rsync -a \
# 		./cypress.config.js \
# 		./cypress \
# 		./cypress/Dockerfile \
# 			./build/cypress
# 	mv ./build/cypress/cypress/*.sh ./build/cypress/
# 	docker image build --pull \
# 		-t $(REPO_PREFIX)/$(BASE_REPO)/cypress-tests:$(GIT_COMMIT_TAG) \
# 			./build/cypress
# 	make cypress-clean

YAML_SPEC_INPUT_FILENAME?=green_cloud_spec.yaml
JSON_SPEC_OUTPUT_FILENAME?=green_cloud_spec.json
.PHONY: convert
convert:
	yq -o=json -I=2 ${YAML_SPEC_INPUT_FILENAME} > ${JSON_SPEC_OUTPUT_FILENAME}

.PHONY: prepare
prepare: convert
	jq -c 'del(.variables,.environments)' ${JSON_SPEC_OUTPUT_FILENAME} > temp-${JSON_SPEC_OUTPUT_FILENAME} && mv temp-${JSON_SPEC_OUTPUT_FILENAME} ${JSON_SPEC_OUTPUT_FILENAME}

.PHONY: output
output: prepare
	jq -Rsa . ${JSON_SPEC_OUTPUT_FILENAME}
# curl -XPOST "http://localhost:9001/2015-03-31/functions/function/invocations" -d "$(jq -c . example_step.json)"
.PHONY: pprepare
pprepare:
	yq -o=json -I=2 ${YAML_SPEC_INPUT_FILENAME} > /tmp/ppare.json
	jq -c 'del(.variables,.environments)' /tmp/ppare.json > /tmp/temp-ppare.json && mv /tmp/temp-ppare.json /tmp/ppare.json
	jq -Rsa . /tmp/ppare.json

YAML_MANIFEST_SPEC_INPUT_FILENAME?=service_manifest.yaml
.PHONY: test_service_manifest
test_service_manifest:
	yq -o=json -I=2 ${YAML_MANIFEST_SPEC_INPUT_FILENAME} | jq '{"input": {"execution_state": {}, "deployment_spec": .deployment_spec, "state": {"cloud_spec_json": (.cloud_spec|tostring) }}}'

.PHONY: step_service_manifest
step_service_manifest:
	yq -o=json -I=2 ${YAML_MANIFEST_SPEC_INPUT_FILENAME} > /tmp/ppare.json
	jq -c 'del(.cloud_spec.variables,.cloud_spec.environments)' /tmp/ppare.json > /tmp/temp-ppare.json && mv /tmp/temp-ppare.json /tmp/ppare.json	
	jq '{"execution_state": {}, "deployment_spec": .deployment_spec, "state": {"cloud_spec_json": (.cloud_spec|tostring) }}' /tmp/ppare.json > /tmp/big.json

.PHONY: simp_step_service_manifest
simp_step_service_manifest:
	yq -o=json -I=2 ${YAML_MANIFEST_SPEC_INPUT_FILENAME} > /tmp/ppare.json
	jq -c 'del(.cloud_spec)' /tmp/ppare.json > /tmp/temp-ppare.json && mv /tmp/temp-ppare.json /tmp/ppare.json	
	jq '.' /tmp/ppare.json > /tmp/big.json

.PHONY: local_step_service_manifest
local_step_service_manifest:
	yq -o=json -I=2 ${YAML_MANIFEST_SPEC_INPUT_FILENAME} > /tmp/ppare.json
	jq -c 'del(.cloud_spec)' /tmp/ppare.json > /tmp/temp-ppare.json && mv /tmp/temp-ppare.json /tmp/ppare.json	
	jq '.' /tmp/ppare.json > /tmp/big.json

.PHONY: bucket
bucket:
ifndef TEMPLATES_BUCKET_NAME
	@echo "You need to set the bucket name for the templates as the TEMPLATES_BUCKET_NAME environment variable. Exiting."
	@echo "use \`export TEMPLATES_BUCKET_NAME=<>\` since we'll use this variable again."
	exit 1
endif
	echo "Do something"
	aws s3api create-bucket --bucket ${TEMPLATES_BUCKET_NAME}
	aws s3 sync ./ s3://${TEMPLATES_BUCKET_NAME}/
# TEMP_AWS_ACCOUNT_ID := $(shell aws sts get-caller-identity | jq -r .Account)
# commands to help run demos
.PHONY: init
init: bucket

	command_output=$$(aws cloudformation create-stack --stack-name DefaultStack --template-url https://${TEMPLATES_BUCKET_NAME}.s3.amazonaws.com/EXAMPLE_ENVIRONMENT.yaml --parameters ParameterKey=EnvironmentName,ParameterValue=dev ParameterKey=TemplateBucketName,ParameterValue=${TEMPLATES_BUCKET_NAME} --capabilities CAPABILITY_NAMED_IAM 2>&1); \
	command_exit_code=$$?; \
	if [[ "$$command_exit_code" -ne 0 ]]; then \
		if [[ "$${command_output}" =~ "An error occurred (AlreadyExistsException)" ]]; then \
			echo "Stack already found. Updating instead"; \
			aws cloudformation update-stack --stack-name DefaultStack --template-url https://${TEMPLATES_BUCKET_NAME}.s3.amazonaws.com/EXAMPLE_ENVIRONMENT.yaml --parameters ParameterKey=EnvironmentName,ParameterValue=dev ParameterKey=TemplateBucketName,ParameterValue=${TEMPLATES_BUCKET_NAME} --capabilities CAPABILITY_NAMED_IAM; \
		else \
			echo "$${command_output}"; \
			exit 3; \
		fi \
	else \
		echo "Continuing"; \
	fi
	until [ $$(aws cloudformation describe-stacks --stack-name DefaultStack | jq -r .Stacks[0].StackStatus) == "CREATE_COMPLETE" ] || [ $$(aws cloudformation describe-stacks --stack-name DefaultStack | jq -r .Stacks[0].StackStatus) == "UPDATE_COMPLETE" ] ; do \
        if [ $$(aws cloudformation describe-stacks --stack-name DefaultStack | jq -r .Stacks[0].StackStatus) == "ROLLBACK_COMPLETE" ] ; then \
			echo "Status reached ROLLBACK_COMPLETE. Deleting stack..." ; \
			$$(aws cloudformation delete-stack --stack-name DefaultStack) \
		 	exit 1; \
		fi; \
		echo "Waiting for STACK_COMPLETE or UPDATE_COMPLETE status of DefaultStack..."; \
        sleep 5 ; \
    done
	echo "DefaultStack has reached STACK_COMPLETE or UPDATE_COMPLETE status"

	ECR_LOGIN_COMMAND=$$(aws cloudformation describe-stacks --stack-name DefaultStack | jq -r '.Stacks[0].Outputs[] | select(.OutputKey=="PrivateECRLoginCommand") | .OutputValue'); \
	echo "$$ECR_LOGIN_COMMAND";

	ECR_PULLTHROUGH_COMMAND=$$(aws cloudformation describe-stacks --stack-name DefaultStack | jq -r '.Stacks[0].Outputs[] | select(.OutputKey=="PrivateECRPullthrough") | .OutputValue'); \
	echo "docker pull $$ECR_PULLTHROUGH_COMMAND"

EMAIL?="rtomlinson@foo.com"
.PHONY: workflows
workflows: bucket

	# Deploy MastLambda
	command_output=$$(aws cloudformation create-stack --stack-name MastLambda --template-url https://${TEMPLATES_BUCKET_NAME}.s3.amazonaws.com/MAST_LAMBDA.yaml --capabilities CAPABILITY_NAMED_IAM 2>&1); \
	command_exit_code=$$?; \
	if [[ "$$command_exit_code" -ne 0 ]]; then \
		if [[ "$${command_output}" =~ "An error occurred (AlreadyExistsException)" ]]; then \
			echo "Stack already found. Updating instead"; \
			update_output=$$(aws cloudformation update-stack --stack-name MastLambda --template-url https://${TEMPLATES_BUCKET_NAME}.s3.amazonaws.com/MAST_LAMBDA.yaml --capabilities CAPABILITY_NAMED_IAM 2>&1); \
			update_exit_code=$$?; \
		else \
			echo "$${command_output}"; \
			exit 3; \
		fi \
	else \
		echo "Continuing"; \
	fi
	until [ $$(aws cloudformation describe-stacks --stack-name MastLambda | jq -r .Stacks[0].StackStatus) == "CREATE_COMPLETE" ] || [ $$(aws cloudformation describe-stacks --stack-name MastLambda | jq -r .Stacks[0].StackStatus) == "UPDATE_COMPLETE" ] ; do \
        if [ $$(aws cloudformation describe-stacks --stack-name MastLambda | jq -r .Stacks[0].StackStatus) == "ROLLBACK_COMPLETE" ] ; then \
			echo "Status reached ROLLBACK_COMPLETE. Deleting stack..." ; \
			$$(aws cloudformation delete-stack --stack-name MastLambda) \
		 	exit 1; \
		fi; \
		echo "Waiting for STACK_COMPLETE or UPDATE_COMPLETE status of MastLambda..."; \
        sleep 5 ; \
    done
	echo "MastLambda has reached STACK_COMPLETE or UPDATE_COMPLETE status"

	# Deploy TopsailLambda
	command_output=$$(aws cloudformation create-stack --stack-name TopsailLambda --template-url https://${TEMPLATES_BUCKET_NAME}.s3.amazonaws.com/TOPSAIL_LAMBDA.yaml --capabilities CAPABILITY_NAMED_IAM 2>&1); \
	command_exit_code=$$?; \
	if [[ "$$command_exit_code" -ne 0 ]]; then \
		if [[ "$${command_output}" =~ "An error occurred (AlreadyExistsException)" ]]; then \
			echo "Stack already found. Updating instead"; \
			update_output=$$(aws cloudformation update-stack --stack-name TopsailLambda --template-url https://${TEMPLATES_BUCKET_NAME}.s3.amazonaws.com/TOPSAIL_LAMBDA.yaml --capabilities CAPABILITY_NAMED_IAM 2>&1); \
			update_exit_code=$$?; \
		else \
			echo "$${command_output}"; \
			exit 3; \
		fi \
	else \
		echo "Continuing"; \
	fi
	until [ $$(aws cloudformation describe-stacks --stack-name TopsailLambda | jq -r .Stacks[0].StackStatus) == "CREATE_COMPLETE" ] || [ $$(aws cloudformation describe-stacks --stack-name TopsailLambda | jq -r .Stacks[0].StackStatus) == "UPDATE_COMPLETE" ] ; do \
        if [ $$(aws cloudformation describe-stacks --stack-name TopsailLambda | jq -r .Stacks[0].StackStatus) == "ROLLBACK_COMPLETE" ] ; then \
			echo "Status reached ROLLBACK_COMPLETE. Deleting stack..." ; \
			$$(aws cloudformation delete-stack --stack-name TopsailLambda) \
		 	exit 1; \
		fi; \
		echo "Waiting for STACK_COMPLETE or UPDATE_COMPLETE status of TopsailLambda..."; \
        sleep 5 ; \
    done
	echo "TopsailLambda has reached STACK_COMPLETE or UPDATE_COMPLETE status"

	# Deploy Executor
	command_output=$$(aws cloudformation create-stack --stack-name Workflows --template-url https://${TEMPLATES_BUCKET_NAME}.s3.amazonaws.com/WORKFLOWS.yaml --parameters ParameterKey=TemplateBucketName,ParameterValue=${TEMPLATES_BUCKET_NAME} ParameterKey=Email,ParameterValue=${EMAIL} --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND 2>&1); \
	command_exit_code=$$?; \
	if [[ "$$command_exit_code" -ne 0 ]]; then \
		if [[ "$${command_output}" =~ "An error occurred (AlreadyExistsException)" ]]; then \
			echo "Stack already found. Updating instead"; \
			aws cloudformation update-stack --stack-name Workflows --template-url https://${TEMPLATES_BUCKET_NAME}.s3.amazonaws.com/WORKFLOWS.yaml --parameters ParameterKey=TemplateBucketName,ParameterValue=${TEMPLATES_BUCKET_NAME} ParameterKey=Email,ParameterValue=${EMAIL} --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND; \
		else \
			echo "$${command_output}"; \
			exit 3; \
		fi \
	else \
		echo "Continuing"; \
	fi
	until [ $$(aws cloudformation describe-stacks --stack-name Workflows | jq -r .Stacks[0].StackStatus) == "CREATE_COMPLETE" ] || [ $$(aws cloudformation describe-stacks --stack-name Workflows | jq -r .Stacks[0].StackStatus) == "UPDATE_COMPLETE" ] ; do \
        if [ $$(aws cloudformation describe-stacks --stack-name Workflows | jq -r .Stacks[0].StackStatus) == "ROLLBACK_COMPLETE" ] ; then \
			echo "Status reached ROLLBACK_COMPLETE. Deleting stack..." ; \
			$$(aws cloudformation delete-stack --stack-name Workflows) \
		 	exit 1; \
		fi; \
		echo "Waiting for STACK_COMPLETE or UPDATE_COMPLETE status of Workflows..."; \
        sleep 5 ; \
    done
	echo "Workflows has reached STACK_COMPLETE or UPDATE_COMPLETE status"

.PHONY: codedeploy
codedeploy: bucket
	command_output=$$(aws cloudformation create-stack --stack-name CodeDeployTutorial --template-url https://${TEMPLATES_BUCKET_NAME}.s3.amazonaws.com/AWS_CODE_DEPLOY_RESOURCES.yaml --parameters ParameterKey=EnvironmentName,ParameterValue=dev ParameterKey=TemplateBucketName,ParameterValue=${TEMPLATES_BUCKET_NAME} --capabilities CAPABILITY_NAMED_IAM 2>&1); \
	command_exit_code=$$?; \
	if [[ "$$command_exit_code" -ne 0 ]]; then \
		if [[ "$${command_output}" =~ "An error occurred (AlreadyExistsException)" ]]; then \
			echo "Stack already found. Updating instead"; \
			aws cloudformation update-stack --stack-name CodeDeployTutorial --template-url https://${TEMPLATES_BUCKET_NAME}.s3.amazonaws.com/AWS_CODE_DEPLOY_RESOURCES.yaml --parameters ParameterKey=EnvironmentName,ParameterValue=dev ParameterKey=TemplateBucketName,ParameterValue=${TEMPLATES_BUCKET_NAME} --capabilities CAPABILITY_NAMED_IAM; \
		else \
			echo "$${command_output}"; \
			exit 3; \
		fi \
	else \
		echo "Continuing"; \
	fi
	until [ $$(aws cloudformation describe-stacks --stack-name CodeDeployTutorial | jq -r .Stacks[0].StackStatus) == "CREATE_COMPLETE" ] || [ $$(aws cloudformation describe-stacks --stack-name CodeDeployTutorial | jq -r .Stacks[0].StackStatus) == "UPDATE_COMPLETE" ] ; do \
        if [ $$(aws cloudformation describe-stacks --stack-name CodeDeployTutorial | jq -r .Stacks[0].StackStatus) == "ROLLBACK_COMPLETE" ] ; then \
			echo "Status reached ROLLBACK_COMPLETE. Deleting stack..." ; \
			$$(aws cloudformation delete-stack --stack-name CodeDeployTutorial) \
		 	exit 1; \
		fi; \
		echo "Waiting for STACK_COMPLETE or UPDATE_COMPLETE status of CodeDeployTutorial..."; \
        sleep 5 ; \
    done
	echo "CodeDeployTutorial has reached STACK_COMPLETE or UPDATE_COMPLETE status"

.PHONY: codepipeline
codepipeline: bucket

	command_output=$$(aws cloudformation create-stack --stack-name CodePipelineTutorial --template-url https://${TEMPLATES_BUCKET_NAME}.s3.amazonaws.com/AWS_CODE_PIPELINE_RESOURCES.yaml --parameters ParameterKey=EnvironmentName,ParameterValue=dev ParameterKey=TemplateBucketName,ParameterValue=${TEMPLATES_BUCKET_NAME} --capabilities CAPABILITY_NAMED_IAM 2>&1); \
	command_exit_code=$$?; \
	if [[ "$$command_exit_code" -ne 0 ]]; then \
		if [[ "$${command_output}" =~ "An error occurred (AlreadyExistsException)" ]]; then \
			echo "Stack already found. Updating instead"; \
			aws cloudformation update-stack --stack-name CodePipelineTutorial --template-url https://${TEMPLATES_BUCKET_NAME}.s3.amazonaws.com/AWS_CODE_PIPELINE_RESOURCES.yaml --parameters ParameterKey=EnvironmentName,ParameterValue=dev ParameterKey=TemplateBucketName,ParameterValue=${TEMPLATES_BUCKET_NAME} --capabilities CAPABILITY_NAMED_IAM; \
		else \
			echo "$${command_output}"; \
			exit 3; \
		fi \
	else \
		echo "Continuing"; \
	fi
	until [ $$(aws cloudformation describe-stacks --stack-name CodePipelineTutorial | jq -r .Stacks[0].StackStatus) == "CREATE_COMPLETE" ] || [ $$(aws cloudformation describe-stacks --stack-name CodePipelineTutorial | jq -r .Stacks[0].StackStatus) == "UPDATE_COMPLETE" ] ; do \
        if [ $$(aws cloudformation describe-stacks --stack-name CodePipelineTutorial | jq -r .Stacks[0].StackStatus) == "ROLLBACK_COMPLETE" ] ; then \
			echo "Status reached ROLLBACK_COMPLETE. Deleting stack..." ; \
			$$(aws cloudformation delete-stack --stack-name CodePipelineTutorial) \
		 	exit 1; \
		fi; \
		echo "Waiting for STACK_COMPLETE or UPDATE_COMPLETE status of CodePipelineTutorial..."; \
        sleep 5 ; \
    done
	echo "CodePipelineTutorial has reached STACK_COMPLETE or UPDATE_COMPLETE status"

# command_output=$$(aws cloudformation create-stack --stack-name HumanApprovalTutorial --template-url https://${TEMPLATES_BUCKET_NAME}.s3.amazonaws.com/EXAMPLE_HUMAN_APPROVAL.yaml --parameters ParameterKey=EnvironmentName,ParameterValue=dev ParameterKey=TemplateBucketName,ParameterValue=${TEMPLATES_BUCKET_NAME} --capabilities CAPABILITY_NAMED_IAM 2>&1); \
# aws cloudformation update-stack --stack-name HumanApprovalTutorial --template-url https://${TEMPLATES_BUCKET_NAME}.s3.amazonaws.com/EXAMPLE_HUMAN_APPROVAL.yaml --parameters ParameterKey=EnvironmentName,ParameterValue=dev ParameterKey=TemplateBucketName,ParameterValue=${TEMPLATES_BUCKET_NAME} --capabilities CAPABILITY_NAMED_IAM; \

.PHONY: humanapproval
humanapproval: bucket
	command_output=$$(aws cloudformation create-stack --stack-name HumanApprovalTutorial --template-url https://${TEMPLATES_BUCKET_NAME}.s3.amazonaws.com/EXAMPLE_HUMAN_APPROVAL.yaml --parameters ParameterKey=Email,ParameterValue=rtomlinson@foo.com --capabilities CAPABILITY_NAMED_IAM 2>&1); \
	command_exit_code=$$?; \
	if [[ "$$command_exit_code" -ne 0 ]]; then \
		if [[ "$${command_output}" =~ "An error occurred (AlreadyExistsException)" ]]; then \
			echo "Stack already found. Updating instead"; \
			aws cloudformation update-stack --stack-name HumanApprovalTutorial --template-url https://${TEMPLATES_BUCKET_NAME}.s3.amazonaws.com/EXAMPLE_HUMAN_APPROVAL.yaml --parameters ParameterKey=Email,ParameterValue=rtomlinson@foo.com --capabilities CAPABILITY_NAMED_IAM; \
		else \
			echo "$${command_output}"; \
			exit 3; \
		fi \
	else \
		echo "Continuing"; \
	fi
	until [ $$(aws cloudformation describe-stacks --stack-name HumanApprovalTutorial | jq -r .Stacks[0].StackStatus) == "CREATE_COMPLETE" ] || [ $$(aws cloudformation describe-stacks --stack-name HumanApprovalTutorial | jq -r .Stacks[0].StackStatus) == "UPDATE_COMPLETE" ] ; do \
        if [ $$(aws cloudformation describe-stacks --stack-name HumanApprovalTutorial | jq -r .Stacks[0].StackStatus) == "ROLLBACK_COMPLETE" ] ; then \
			echo "Status reached ROLLBACK_COMPLETE. Deleting stack..." ; \
			$$(aws cloudformation delete-stack --stack-name HumanApprovalTutorial) \
		 	exit 1; \
		fi; \
		echo "Waiting for STACK_COMPLETE or UPDATE_COMPLETE status of HumanApprovalTutorial..."; \
        sleep 5 ; \
    done
	echo "HumanApprovalTutorial has reached STACK_COMPLETE or UPDATE_COMPLETE status"

.PHONY: stub
stub:
	command_output=$$(aws cloudformation create-stack --stack-name CodeDeployTutorial --template-url https://${TEMPLATES_BUCKET_NAME}.s3.amazonaws.com/AWS_CODE_DEPLOY_RESOURCES.yaml --parameters ParameterKey=EnvironmentName,ParameterValue=dev ParameterKey=TemplateBucketName,ParameterValue=${TEMPLATES_BUCKET_NAME} --capabilities CAPABILITY_NAMED_IAM 2>&1); \
	command_exit_code=$$?; \
	if [[ "$$command_exit_code" -ne 0 ]]; then \
		if [[ "$${command_output}" =~ "An error occurred (AlreadyExistsException)" ]]; then \
			echo "Stack already found. Updating instead"; \
		else \
			echo "$${command_output}"; \
			exit 3; \
		fi \
	else \
		echo "Continuing"; \
	fi


.PHONY: put-activity
put-activity: local_step_service_manifest # simp_step_service_manifest
	# create the spec with contexts
	# call the start step function with the input
	echo starting-step-function
	DEPLOYMENT_SPEC_JSON=$$(jq -n --argjson data "$$contexts" --argfile dspec /tmp/big.json '{"contexts": $$data, "deployment_spec": $$dspec.deployment_spec}'); \
	STATE_MACHINE_ARN="arn:aws:states:us-east-1:428589721254:stateMachine:ActivityWorkflowExecutor"; \
	aws stepfunctions start-execution --state-machine-arn $$STATE_MACHINE_ARN --input "$$DEPLOYMENT_SPEC_JSON";

.PHONY: deploy-delegate
deploy-delegate:
	echo "deploy-delegate"

.PHONY: list-executions
list-executions:
	echo "list-executions"

.PHONY: get-execution
get-execution:
	echo "get-execution"

.PHONY: tail-execution-logs
tail-execution-logs:
	echo "arn:aws:states:us-east-1:174822970548:execution:ActivityWorkflowExecutor:299168b8-57f3-440c-b10f-6e8cba50ffd6"
	echo "which log group? TopsailLogGroup"
	ehco "which log stream? 299168b8-57f3-440c-b10f-6e8cba50ffd6"

.PHONY: get-worker-by-execution-id
get-worker-by-execution-id:
	WORKER_ID=$(aws stepfunctions get-execution-history --execution-arn "${execution-id}" --output json | jq -r '.events[] | select(.type | contains("ActivityStarted")) | .activityStartedEventDetails.workerName'); \
	WORKER_START_TIME=$(aws stepfunctions get-execution-history --execution-arn "${execution-id}" --output json | jq -r '.events[] | select(.type | contains("ActivityStarted")) | .timestamp'); \
	WORKER_START_TIME_EPOCH=$(date -d "${WORKER_START_TIME}" +'%s%3N'); \
	aws logs filter-log-events --log-group-name TopsailLogGroup --log-stream-names bob1 --start-time "${WORKER_START_TIME_EPOCH}" | jq

	# basically we want to loop here
	# check execution history for a finish time, else increment however long the timeout is to get more logs

	# wait for user to exit viewing the logs
	# start-query?
	# get-log-events?
