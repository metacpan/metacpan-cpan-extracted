# WebDyne::Request::Fake #

# NAME #

WebDyne::Request::Fake - synthetic request/response object used for direct WebDyne rendering

# SYNOPSIS #

```perl
use WebDyne::Request::Fake;

my $r = WebDyne::Request::Fake->new(
    filename => 'page.psp',
    method   => 'GET',
);
```

# DESCRIPTION #

`WebDyne::Request::Fake` is the baseline WebDyne request adapter. It is used when rendering pages outside a real web server environment, for example through `WebDyne::html`, `WebDyne::html_sr`, `wdrender`, and related command-line tooling.

The module provides a normalized request/response API and also acts as the fallback implementation for methods not implemented by more specific request adapters.

# METHODS #

Notable methods implemented directly by this class include:

* **new(%options)**

    Construct a synthetic request object.

* **filename()**

    Get or derive the current source filename being requested.

* **uri()**

    Return a `URI` object for the current request.

* **headers_in() / headers_out()**

    Access request and response headers.

* **status() / status_line()**

    Access or update response status information.

* **print() / write()**

    Append response body output.

* **finalize()**

    Finalize the synthetic response for downstream consumers.

* **redirect($url)**

    Set redirect-style response headers and status.

* **dir_config($name)**

    Look up directory-style configuration, including values sourced from `WEBDYNE_DIR_CONFIG` and optional local `.webdyne.conf.pl` loading.

* **err_html()**

    Generate an error response using WebDyne’s HTML error facilities.

# NOTES #

`WebDyne::Request::Fake` intentionally carries both request and response responsibilities. More specialized adapters such as `WebDyne::Request::Apache`, `WebDyne::Request::PSGI`, and `WebDyne::Request::PAGI` inherit from it for missing behavior.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
