# WebDyne::PSGI #

# NAME #

WebDyne::PSGI - PSGI application wrapper for WebDyne

# SYNOPSIS #

```perl
use WebDyne::PSGI;

my $app = WebDyne::PSGI->new(
    root  => '.',
    index => 1,
)->to_app;

my $single_file_app = WebDyne::PSGI->new(
    root     => '.',
    filename => 'app.psp',
)->to_app;
```

# DESCRIPTION #

`WebDyne::PSGI` wraps the core WebDyne handler in a PSGI application. It translates PSGI environment data into a `WebDyne::Request::PSGI` object, dispatches to the main WebDyne handler, and converts the result back into a PSGI response.

The module also contains special handling for API-style fallback resolution when a `.psp` file is not found directly from the incoming path.

# METHODS #

* **new(%options)**

    Construct a PSGI application wrapper. Options include `root`, `index`, `test`, `filename`, and related runtime settings.

    The `filename` option is an explicit source-file override for the application. When supplied, it is passed to `WebDyne::Request::PSGI` for every request and always wins over normal filename derivation from the PSGI environment, including `PATH_INFO`, `SCRIPT_FILENAME`, `DOCUMENT_ROOT`, and default document handling. This is useful for helper tools or deliberate single-file PSGI applications; do not set it for normal multi-page applications that should dispatch from the request path.

* **to_app()**

    Return the PSGI application code reference.

* **handler($env, @param)**

    Main PSGI entry point. Builds request and response objects, dispatches to WebDyne, and returns the PSGI response.

* **psgi_error(...)**

    Helper for PSGI-side error handling and conversion.

# NOTES #

The module relies on `WebDyne::Request::PSGI` for normalized request handling and on `WebDyne::PSGI::Constant` for middleware and environment defaults.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
