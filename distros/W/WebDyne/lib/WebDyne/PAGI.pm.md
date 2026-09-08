# WebDyne::PAGI #

# NAME #

WebDyne::PAGI - PAGI application wrapper for WebDyne

# SYNOPSIS #

```perl
use WebDyne::PAGI;

my $app = WebDyne::PAGI->new(
    root   => '.',
    index  => 1,
    static => 1,
    conf   => 1,
)->to_app;

my $single_file_app = WebDyne::PAGI->new(
    root     => '.',
    filename => 'app.psp',
)->to_app;
```

# DESCRIPTION #

`WebDyne::PAGI` wraps the core WebDyne handler in a PAGI application. It supports multiple PAGI scope types, including normal HTTP requests, server-sent events, WebSocket connections, and lifespan startup or shutdown events.

# METHODS #

* **new(%options)**

    Construct a PAGI application wrapper. Options include `root`, `index`, `test`, `filename`, `static`, `conf`, `startup`, `shutdown`, and related runtime settings.

    The `filename` option is an explicit source-file override for the application. When supplied, it is passed to `WebDyne::Request::PAGI` for every HTTP request and always wins over normal filename derivation from the PAGI request scope, including path-based dispatch, document-root resolution, default document handling, and API-style fallback resolution. This is useful for helper tools or deliberate single-file PAGI applications; do not set it for normal multi-page applications that should dispatch from the request path.

    The `static` option enables or disables the configured PAGI static-file middleware for this app instance. Static middleware is disabled by the package default, but wrapper scripts such as `webdyne.pagi` may pass `static => 1`.

    The `conf` option loads local WebDyne constants during app construction. A true value of `1` loads `$root/.webdyne.conf.pl`; any other true value is treated as an explicit config filename, relative to `root` unless already absolute.

    The optional `startup` and `shutdown` options are coderefs (or `undef` to disable). Each receives `($app_or, $scope_hr)`: this application object and the lifespan scope. A normal return, including a false value, succeeds; a returned `Future` is awaited. WebDyne owns the receive/send protocol and sends the completion acknowledgement only after the callback succeeds. An exception or failed Future sends `lifespan.startup.failed` or `lifespan.shutdown.failed` with the diagnostic, then ends the lifespan session. Failures while sending protocol events propagate to the server. Missing callbacks preserve the default acknowledgements.

    Callbacks run when the server delivers the corresponding event, not during construction. A lifespan scope is not an HTTP request and has no PSP request object. Startup is per application lifespan/interpreter, not once per deployment. Shutdown requires a server that delivers shutdown; it cannot be relied upon after a crash or forced termination.

    ```perl
    use My::App;
    my $app_cr=WebDyne::PAGI->new(
        root     => '.',
        startup  => \&My::App::startup,
        shutdown => \&My::App::shutdown,
    )->to_app();
    ```

* **to_app()**

    Return the PAGI application code reference, wrapped in configured PAGI middleware.

* **handler_http()**

    Handle normal HTTP requests. Outgoing response header names are normalized to lowercase for PAGI, preserving values, order, and duplicates without changing the stored header collections.

* **handler_sse()**

    Handle server-sent event requests. URL-encoded form bodies are buffered before CGI parameter setup, subject to `WEBDYNE_CGI_POST_MAX`. Oversized forms receive status 413 through SSE HTTP denial events; disconnects during buffering skip page execution. Normal EventSource GETs do not wait for body data. Multipart SSE form submissions are outside this handler's supported scope. When page setup returns an HTTP error status instead of a stream callback, send a plain-text SSE HTTP denial response with that status. Other results without a valid callback produce status 500. Custom error headers and redirects are not forwarded by this fallback.

* **handler_ws()**

    Handle WebSocket requests. If page setup does not provide a valid WebSocket callback, reject the handshake with `websocket.close`. This uses the standard HTTP 403 rejection without requiring the optional HTTP denial-response extension.

* **handler_lifespan()**

    Handle PAGI lifespan startup and shutdown events.

* **lifespan_callback($phase, $scope_hr)**

    Invoke the configured `startup` or `shutdown` callback and return a Future resolving without values when its work completes. An absent callback completes immediately. Unknown phases and callback errors fail the Future. `handler_lifespan()` uses this method before acknowledging the event; callers normally configure callbacks through the constructor instead of calling it directly.

* **handler_sse_error()**

    Helper for reporting SSE-side failures.

# NOTES #

HTTP, SSE and WebSocket handlers clear WebDyne's shared diagnostic stack before synchronous page setup. HTTP and SSE body buffering completes before this reset, so errors from another request processed during buffering do not contaminate the resumed render. Diagnostics raised during page setup remain available to its error-response handling.

This is a synchronous request boundary, not per-session diagnostic storage. Asynchronous callbacks must not rely on `errstr()` or `errdump()` retaining their diagnostics across an `await`; use exceptions or Future failures to propagate asynchronous errors. Caught exceptions within one render can still populate the shared stack.

The module relies on `WebDyne::Request::PAGI` for normalized request handling and on `WebDyne::PAGI::Constant` for middleware and environment defaults.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
