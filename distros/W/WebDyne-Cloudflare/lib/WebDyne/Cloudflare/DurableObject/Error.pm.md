# WebDyne::Cloudflare::DurableObject::Error

Structured Durable Object host or RPC error. `new(name => ..., message => ...,
code => ..., cause => ...)` creates an error. Accessors are `name()`, `message()`,
`code()`, and `cause()`; stringification produces a readable diagnostic. The RPC
contract preserves name, message and optional code, not remote stack traces.
A failed operation is never automatically retried, and may have already written
state. Applications may throw this class to return an explicit error code.
