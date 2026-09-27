# Synchronize the container dependency fork

## Motivation

The container-only dependency fork is missing commits from apple/swift-nio-ssl. Include upstream main 322f3c2a4a21df31c84ca416bf65ee5e9059e440 while retaining required fork changes. Unrelated repositories are outside this task.

## Acceptance

Preserve the previous refs, merge upstream without rewriting history, and pass the affected dependency tests before publishing to the Stephen-owned fork.
