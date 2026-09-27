# WebDyne::Cloudflare::DurableObject::Handler

Internal finite-invocation adapter used by the JavaScript Durable Object host.
`application($scope, $receive, $send)` loads the configured Perl package, constructs
an invocation context, invokes the configured method, awaits an optional Future,
and sends one `invocation.result` envelope. It is not a public HTTP/PAGI endpoint.
Only the host's explicit method allowlist may select RPC methods. Applications
should implement the package methods documented in [Context.pm.md](Context.pm.md).
