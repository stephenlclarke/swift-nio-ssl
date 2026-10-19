SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

SWIFT ?= swift
PYTHON ?= python3
LLVM_COV ?= $(shell xcrun --find llvm-cov 2>/dev/null || command -v llvm-cov)
SONAR_QUALITYGATE_WAIT ?= true

.PHONY: test coverage coverage-tools-test sonar sonar-scan clean

test:
	$(SWIFT) test

coverage-tools-test:
	$(PYTHON) -m unittest discover Tools/coverage

coverage: coverage-tools-test
	@git diff --quiet HEAD -- || { printf 'coverage requires clean tracked source\n' >&2; exit 2; }
	@git rev-parse --verify HEAD > coverage.source-revision
	rm -f coverage.xml.sha256
	$(SWIFT) test --enable-code-coverage
	@coverage_report="$$($(SWIFT) test --show-codecov-path)"; \
		test -s "$$coverage_report"; \
		profile="$${coverage_report%/*}/default.profdata"; \
		test -s "$$profile"; \
		test -x "$(LLVM_COV)"; \
		bin_path="$$($(SWIFT) build --show-bin-path)"; \
		test_binaries=(); \
		while IFS= read -r binary; do test_binaries+=("$$binary"); done < <( \
			find "$$bin_path" -type f -perm -111 \
			\( -name '*.xctest' -o -path '*.xctest/Contents/MacOS/*' \) \
			-print | sort \
		); \
		test "$${#test_binaries[@]}" -gt 0; \
		coverage_command=("$(LLVM_COV)" export -format=lcov \
			-instr-profile="$$profile" "$${test_binaries[0]}"); \
		for ((index = 1; index < $${#test_binaries[@]}; index++)); do \
			coverage_command+=(-object "$${test_binaries[$$index]}"); \
		done; \
		"$${coverage_command[@]}" --sources Sources > coverage.lcov; \
		$(PYTHON) Tools/coverage/swift_coverage.py \
			--source-root "$(CURDIR)" \
			--exclude-prefix Sources/CNIOBoringSSL \
			--exclude-prefix Sources/CNIOBoringSSLShims \
			--sonar-output coverage.xml \
			coverage.lcov; \
		test "$$(cat coverage.source-revision)" = "$$(git rev-parse --verify HEAD)"; \
		git diff --quiet HEAD --; \
		shasum -a 256 coverage.xml > coverage.xml.sha256

sonar: coverage sonar-scan

sonar-scan:
	@test -s coverage.xml || { \
		printf 'coverage.xml is missing; run make coverage first\n' >&2; \
		exit 2; \
	}
	@test -s coverage.source-revision -a -s coverage.xml.sha256 || { \
		printf 'coverage provenance is missing; run make coverage first\n' >&2; exit 2; \
	}
	@test "$$(cat coverage.source-revision)" = "$$(git rev-parse --verify HEAD)" || { \
		printf 'coverage belongs to another revision; run make coverage again\n' >&2; exit 2; \
	}
	@git diff --quiet HEAD -- || { printf 'scan requires clean tracked source\n' >&2; exit 2; }
	@shasum -a 256 -c coverage.xml.sha256 >/dev/null
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
		scanner_context=(); \
		if [[ "$${GITHUB_ACTIONS:-false}" != true ]]; then \
			branch="$$(git symbolic-ref --quiet --short HEAD)" || { \
				printf 'local scans require a named branch\n' >&2; exit 2; \
			}; \
			scanner_context=("-Dsonar.branch.name=$$branch"); \
		fi; \
		SONAR_TOKEN="$${SONAR_TOKEN:-$${SONAR_TOKEN_PERSONAL:-}}" \
			sonar-scanner \
			-Dsonar.projectVersion="$$project_version" \
			-Dsonar.qualitygate.wait="$(SONAR_QUALITYGATE_WAIT)" \
			$${scanner_context[@]+"$${scanner_context[@]}"}

clean:
	rm -f coverage.lcov coverage.xml coverage.source-revision coverage.xml.sha256
	rm -rf .scannerwork
