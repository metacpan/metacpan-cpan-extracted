# WebDyne::Request::PSGI #

# NAME #

WebDyne::Request::PSGI - PSGI request adapter for WebDyne

# SYNOPSIS #

```perl
use WebDyne::Request::PSGI;

my $wr = WebDyne::Request::PSGI->new(
    env => $env,
    req => Plack::Request->new($env),
    res => Plack::Response->new(200),
);
```

# DESCRIPTION #

`WebDyne::Request::PSGI` adapts PSGI request state to the normalized request API expected by WebDyne.

When no filename is supplied, the constructor derives one from the PSGI environment, document root, request path, and configured default document rules. The adapter also exposes query/body parameters, uploads, headers, and PSGI request metadata through WebDyne-friendly method names.

# METHODS #

* **new(%options)**

    Construct a PSGI-backed request adapter. The `env` hashref is required.

* **body()**

    Read and cache request body content from `psgi.input`.

* **headers_in()**

    Access request headers.

In addition, the adapter provides the normalized request surface expected by WebDyne, including methods such as `query_parameters`, `form_parameters`, `uploads`, `uri`, `scheme`, `script_name`, `request_time`, and related accessors.

# NOTES #

Most normalized methods are installed dynamically in `init()` via `WebDyne::Request::Common`. Methods not implemented locally fall back to the fake-request adapter where appropriate.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
