# WebDyne::PAGI #

# NAME #

WebDyne::PAGI - PAGI application wrapper for WebDyne

# SYNOPSIS #

```perl
use WebDyne::PAGI;

my $app = WebDyne::PAGI->new(
    root  => '.',
    index => 1,
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

    Construct a PAGI application wrapper. Options include `root`, `index`, `test`, `filename`, and related runtime settings.

    The `filename` option is an explicit source-file override for the application. When supplied, it is passed to `WebDyne::Request::PAGI` for every HTTP request and always wins over normal filename derivation from the PAGI request scope, including path-based dispatch, document-root resolution, default document handling, and API-style fallback resolution. This is useful for helper tools or deliberate single-file PAGI applications; do not set it for normal multi-page applications that should dispatch from the request path.

* **to_app()**

    Return the PAGI application code reference.

* **handler_http()**

    Handle normal HTTP requests.

* **handler_sse()**

    Handle server-sent event requests.

* **handler_ws()**

    Handle WebSocket requests.

* **handler_lifespan()**

    Handle PAGI lifespan startup and shutdown events.

* **handler_sse_error()**

    Helper for reporting SSE-side failures.

# NOTES #

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
