# WebDyne::Cloudflare::SecretsStore::Error

Structured, sanitized Secrets Store failure. `get()` fails its Future with this
object when the host call, protocol, capability, binding or retrieval fails.

`new(name => $name)` accepts one of these stable classifications:

- `SECRETS_STORE_ERROR`: unclassified failure.
- `SECRETS_STORE_HOST_ERROR`: host invocation failed or adapter is unavailable.
- `SECRETS_STORE_PROTOCOL_ERROR`: unsupported or malformed request/response.
- `SECRETS_STORE_CAPABILITY_ERROR`: missing or expired request capability.
- `SECRETS_STORE_BINDING_ERROR`: binding unavailable to this request.
- `SECRETS_STORE_READ_ERROR`: native binding retrieval failed.

Unknown names map to `SECRETS_STORE_ERROR`. `name()` and `message()` return
the classification and a fixed diagnostic. `as_string()` and string overloading
return `NAME: message`. Caller-supplied messages, codes and causes are ignored
to prevent accidental disclosure of values contained in provider diagnostics.
