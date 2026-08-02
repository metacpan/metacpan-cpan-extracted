# WebDyne::Request::PSGI::Static #

# NAME #

WebDyne::Request::PSGI::Static - simple static-file responder for WebDyne PSGI request flows

# SYNOPSIS #

```perl
use WebDyne::Request::PSGI::Static;

my $status = WebDyne::Request::PSGI::Static->run($child_request);
```

# DESCRIPTION #

`WebDyne::Request::PSGI::Static` is a small helper subclass used when a PSGI request should serve a static asset rather than a `.psp` page.

It reads the nominated file, sets `Content-Length`, selects a content type from `WEBDYNE_MIME_TYPE_HR` with a plain-text fallback, emits headers, streams the file to the parent response object, and returns an HTTP status code.

# METHODS #

* **run($child_request)**

    Serve the file named by the child request object. Returns `HTTP_NOT_FOUND` if the file does not exist, `HTTP_INTERNAL_SERVER_ERROR` if it cannot be opened, or `HTTP_OK` after streaming the asset.

# NOTES #

Despite the package name, the same helper is also used from fake-request and non-Apache execution paths, so it returns runtime-neutral HTTP status codes.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
