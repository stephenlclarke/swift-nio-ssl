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
			coverage.lcov

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
