# Issue: add SonarQube Cloud quality reporting

## Problem

This maintained Container-family Swift repository has no SonarQube Cloud
analysis, coverage evidence, or README quality badges. That leaves reliability,
security, maintainability, duplication, and coverage changes without the
family-wide quality authority.

## Required outcome

- Create a public `stephenlclarke_swift-nio-ssl` project.
- Apply the project-level `Previous version` new-code definition.
- Analyze exact Git commits and reject unresolved new-code issues and security hotspots.
- Generate retained first-party Swift coverage reports.
- Add the standard Container-family SonarQube badge set to `README.md`.

## Compatibility and risk

The change is development infrastructure only. It does not modify package
products, public API, runtime behavior, dependency pins, or upstream source
semantics. The vendored BoringSSL implementation remains upstream-controlled
and is excluded from fork-maintained source and coverage metrics.
