# No slash at the end please
REPO_PREFIX ?= rttomlinson
DOCKER ?= docker

.PHONY: build
build:
	$(DOCKER) build --pull \
		--build-arg BUILD_OPTIONS="$$BUILD_OPTIONS" \
		--build-arg REPO_PREFIX="$$REPO_PREFIX/" \
		-t $(REPO_PREFIX)/topsail \
			.

.PHONY: quick
quick:
	BUILD_OPTIONS='--notest' make -s build

.PHONY: push
push:
	$(DOCKER) push $(REPO_PREFIX)/topsail

.PHONY: local-quick
local-quick:
	$(DOCKER) build --pull --build-arg BUILD_OPTIONS='--notest' -t topsail .


.PHONY: local-quick-lambda
local-quick-lambda:
	$(DOCKER) build --pull --build-arg BUILD_OPTIONS='--notest' -f Dockerfile.lambda -t topsail-lambda .

.PHONY: local-quick-build
local-quick-build:
	docker build --build-arg IMAGE_BASE='mast-lambda' --build-arg BUILD_OPTIONS='--notest' -f Dockerfile.lambda -t topsail-lambda .

.PHONY: local-quick-build-decider
local-quick-build-decider:
	docker build --build-arg BUILD_OPTIONS='--notest' -f Dockerfile.decider-lambda -t topsail-decider-lambda .
