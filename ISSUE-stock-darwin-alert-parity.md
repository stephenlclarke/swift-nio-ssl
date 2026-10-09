# Restore upstream Darwin certificate alerts

<!-- markdownlint-disable MD013 -->

The fork's internal Security.framework verifier forced the TLS `bad_certificate` alert after rejecting an untrusted peer. In the retained paired comparison, the same upstream `NIOSSLTests` are run against both libraries. Three upstream tests passed against stock and failed against the fork because they received `SSLV3_ALERT_BAD_CERTIFICATE` instead of the stock alert selection.

Keep certificate rejection and the asynchronous verifier unchanged. Remove only the fork's forced alert from the internal Darwin verifier so the same upstream certificate cases produce the same alert behavior. Do not replace the upstream test suite with the fork's permissive expectations.
