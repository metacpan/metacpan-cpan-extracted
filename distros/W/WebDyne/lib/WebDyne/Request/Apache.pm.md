# WebDyne::Request::Apache #

# NAME #

WebDyne::Request::Apache - Apache mod_perl request adapter for WebDyne

# SYNOPSIS #

```perl
use WebDyne::Request::Apache;

my $wr = WebDyne::Request::Apache->new($apache_request_rec);
```

# DESCRIPTION #

`WebDyne::Request::Apache` adapts an `Apache2::RequestRec` object to the normalized request interface expected by the main WebDyne handler.

It maps Apache request data into WebDyne-style methods and provides body-handle support, environment access, header accessors, URI handling, and selected convenience wrappers over mod_perl request record methods.

# METHODS #

* **new($r, %options)**

    Wrap an Apache request record.

* **filename()**

    Return the effective filename for the request. This honors the `DOCUMENT_ROOT` environment override used by some WebDyne flows.

* **headers_in() / headers_out()**

    Access request and response headers through the adapter.

* **content_type() / content_length() / content_encoding()**

    Access common content metadata.

* **host() / server_name() / server_port()**

    Access host and server details.

* **remote_address() / remote_host() / remote_port()**

    Access client network details.

* **body() / body_handle()**

    Read request body content or return a handle-like interface for streaming reads.

* **uri()**

    Return a `URI` object for the current request.

# NOTES #

The module initializes many additional normalized methods by delegating through `WebDyne::Request::Common`. Methods not implemented directly are filled by adapter dispatch or inherited fallback behavior.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
