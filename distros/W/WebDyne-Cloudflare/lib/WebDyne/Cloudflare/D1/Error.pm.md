# WebDyne::Cloudflare::D1::Error

Structured host error. `new(%options)` accepts name, message, code and cause.
Accessors `name()`, `message()`, `code()` and `cause()` return those fields.
`as_string()` and string overloading produce a diagnostic including the
optional code. Service operations fail their Future with this object.
