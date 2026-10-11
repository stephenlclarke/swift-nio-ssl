<!-- markdownlint-disable MD013 -->

# Darwin trust rejection alert

## Motivation

Darwin's default trust verifier rejects an untrusted peer through BoringSSL's custom verification callback. Client-side rejection must send `bad_certificate`; server-side client-certificate rejection and public custom verifiers must retain BoringSSL's existing alert behavior. The existing pull request passed BoringSSL's alert pointer into Swift verification state, and [upstream review](https://github.com/apple/swift-nio-ssl/pull/605) requested that the state return an optional alert instead.

## Required behavior

Return the verification result and optional alert from `CustomVerifyManager.process`. Write to the C callback's alert pointer only at the `SSL_set_custom_verify` boundary. Return the explicit alert only for a client connection. Preserve the current upstream BoringSSL sources and the same alert behavior for server-side failure, public failure, success, and pending verification.

## Validation and risk

The focused `CustomVerifyManagerTests` pass 7/7 and the stock `NIOSSLTests` pass 348/348 against upstream `86458a336bf0f647b080c8637515bfefd8ea08b3`. The first full run's three unchanged server-side assertions failed before the role-scoped correction; its raw log remains retained. Hosted PR checks remain outstanding.
