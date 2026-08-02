# WebDyne::Request::PSGI::Constant #

# NAME #

WebDyne::Request::PSGI::Constant - request-adapter constants for the PSGI request layer

# SYNOPSIS #

```perl
use WebDyne::Request::PSGI::Constant;
```

# DESCRIPTION #

`WebDyne::Request::PSGI::Constant` defines defaults used specifically by the PSGI request adapter layer. It overlaps with `WebDyne::PSGI::Constant`, but is scoped to request interpretation and middleware behavior when building `WebDyne::Request::PSGI` objects.

# CONSTANTS #

* **DOCUMENT_ROOT**

    Optional default document root for request resolution.

* **DOCUMENT_DEFAULT ('app.psp')**

    Default page selected when a resolved request path refers to a directory.

* **WEBDYNE_PSGI_INDEX ('index.psp')**

    Index filename used by the request-side PSGI helpers.

* **WEBDYNE_PSGI_MIDDLEWARE_STATIC**

    Regular expression controlling which static asset paths may be served directly.

* **WEBDYNE_PSGI_MIDDLEWARE**

    Request-layer middleware stack definition.

* **WEBDYNE_PSGI_ENV_KEEP / WEBDYNE_PSGI_ENV_SET**

    Environment variables preserved from or injected into PSGI request processing.

* **WEBDYNE_PSGI_WARN_ON_ERROR**

    Optional warning control flag for request-layer PSGI errors.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
