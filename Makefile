SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

SWIFT ?= swift
PYTHON ?= python3
SONAR_QUALITYGATE_WAIT ?= true

.PHONY: test coverage coverage-tools-test sonar sonar-scan clean

test:
	$(SWIFT) test

coverage-tools-test:
	$(PYTHON) -m unittest discover Tools/coverage

coverage: coverage-tools-test
	$(SWIFT) test --enable-code-coverage
	@coverage_report="$$($(SWIFT) test --show-codecov-path)"; \
		test -s "$$coverage_report"; \
		$(PYTHON) Tools/coverage/swift_coverage.py \
			--source-root "$(CURDIR)" \
			--exclude-prefix Sources/CNIOBoringSSL \
			--exclude-prefix Sources/CNIOBoringSSLShims \
			--lcov-output coverage.lcov \
			--sonar-output coverage.xml \
			"$$coverage_report"

sonar: coverage sonar-scan

sonar-scan:
	@test -s coverage.xml || { \
		printf 'coverage.xml is missing; run make coverage first\n' >&2; \
		exit 2; \
	}
	@test -n "$${SONAR_TOKEN:-$${SONAR_TOKEN_PERSONAL:-}}" || { \
		printf 'SONAR_TOKEN or SONAR_TOKEN_PERSONAL is required for sonar-scan\n' >&2; \
		exit 2; \
	}
	@head_version="$$(git rev-parse --verify HEAD)"; \
		project_version="$${SONAR_PROJECT_VERSION:-$$head_version}"; \
		if [[ ! "$$project_version" =~ ^[0-9a-f]{40}$$ ]]; then \
			printf 'SONAR_PROJECT_VERSION must be an exact lowercase commit SHA\n' >&2; \
			exit 2; \
		fi; \
		if [[ "$$project_version" != "$$head_version" ]]; then \
			printf 'SONAR_PROJECT_VERSION must match checked-out HEAD %s\n' "$$head_version" >&2; \
			exit 2; \
		fi; \
		SONAR_TOKEN="$${SONAR_TOKEN:-$${SONAR_TOKEN_PERSONAL:-}}" \
			sonar-scanner \
			-Dsonar.projectVersion="$$project_version" \
			-Dsonar.qualitygate.wait="$(SONAR_QUALITYGATE_WAIT)"

clean:
	rm -f coverage.lcov coverage.xml
	rm -rf .scannerwork
