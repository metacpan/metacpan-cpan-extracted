# TODOs

List of code things that need adding to Thunderhorse core.

- [ ] PAGI lifespan hooks need to be forwarded to nested PAGI apps: https://github.com/jjn1056/pagi/issues/22
- [ ] Router should be sealed when application starts, to prevent adding more routes at runtime and invalidating cache
- [ ] Modules should be able to provide a list of modules they depend on, and be loaded after them
- [ ] Modules should allow adding methods to more than just controllers (request, response, sse and websocket at least)
- [ ] Thunderhorse::API, minimal JSON Schema-powered, OpenAPI-aware overlay for Thunderhorse (in core or separate module)

