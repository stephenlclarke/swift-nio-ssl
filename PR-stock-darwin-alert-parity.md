# Restore upstream Darwin certificate alerts

<!-- markdownlint-disable MD013 -->

The internal Darwin trust verifier now leaves alert selection to BoringSSL after rejecting an untrusted peer. The three fork test assertions again match the upstream suite exactly. A fork-only regression asserts that the default verifier does not prescribe an alert; its separate tests for explicitly configured alerts remain. Certificate trust decisions, public custom verification callbacks, and the asynchronous completion path are unchanged.

Validation: the unchanged upstream `NIOSSLTests` passed all 341 cases against the patched fork, including the three previously failing certificate cases. With the fork-only verifier regressions added, the suite passed all 347 cases. The original fork failure at `17ab11cd2dac5cfc4760a37cb2e0f955d7629439` and the intermediate expected regression failure remain retained. These focused results do not replace the full paired comparison at a final source revision.
