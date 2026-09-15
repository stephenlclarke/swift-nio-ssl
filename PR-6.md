# Pull request 6: add SonarQube Cloud quality reporting

## Motivation

Bring this maintained TLS fork under the same exact-commit SonarQube Cloud
policy and README reporting used by the rest of the Container family.

## Implementation

- Add a project-scoped scanner configuration and previous-version policy validation.
- Add a deterministic SwiftPM coverage converter with unit tests.
- Add local `make coverage`, `make sonar-scan`, and `make sonar` entry points.
- Add an exact-revision GitHub workflow for pull requests, `main`, and manual recovery.
- Retain coverage evidence and reject unresolved new-code issues or security hotspots.
- Add the complete standard metric badge set to the README.

## Validation

- `make coverage`
- `python3 -m unittest discover Tools/coverage`
- `actionlint .github/workflows/sonar.yml`
- `markdownlint README.md ISSUE-*.md PR-*.md`
- `git diff --check`
- Authoritative pull-request and merged-`main` SonarQube Cloud quality gates

## Compatibility

No package product, public API, dependency, runtime, integration, or release
behavior changes.

## Rollback

Revert the infrastructure commit and remove the corresponding SonarQube Cloud
project if the integration must be withdrawn. No source or data migration is
required.

## Links

- Tracks the repository-local issue document: [ISSUE-quality-add-sonarcloud.md](ISSUE-quality-add-sonarcloud.md)
- Pull request: [#6](https://github.com/stephenlclarke/swift-nio-ssl/pull/6)
