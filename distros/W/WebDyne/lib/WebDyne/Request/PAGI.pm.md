# WebDyne::Request::PAGI #

# NAME #

WebDyne::Request::PAGI - PAGI request adapter for WebDyne

# SYNOPSIS #

```perl
use WebDyne::Request::PAGI;

my $wr = WebDyne::Request::PAGI->new(
    scope => $scope,
    req   => $pagi_request,
    res   => $pagi_response,
);
```

# DESCRIPTION #

`WebDyne::Request::PAGI` adapts PAGI request state to the normalized request API expected by WebDyne.

Like the PSGI adapter, it can derive a target filename from the request path, configured document root, and default document settings. It also exposes PAGI-specific request information such as scope-based protocol details, body access, form/query parameters, and request timing through the common WebDyne request surface.

# METHODS #

* **new(%options)**

    Construct a PAGI-backed request adapter.

* **env()**

    Return the normalized environment view used by the adapter.

* **id()**

    Return the request identifier if present.

* **https() / secure()**

    Return HTTPS/security state derived from the PAGI request.

* **server_name() / server_port()**

    Return server identity details.

* **body() / body_handle()**

    Read or stream the request body.

* **headers_in() / headers_out()**

    Access request and response headers.

* **header_only()**

    Return whether the current request should emit headers only.

* **request_time()**

    Return request start timing metadata when available.

* **base() / base_url()**

    Return URI base information for the current request.

# NOTES #

This adapter also supports WebDyne’s SSE and WebSocket-aware PAGI flows because the parent PAGI runtime passes through `sse` and `ws` helper objects when present.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
