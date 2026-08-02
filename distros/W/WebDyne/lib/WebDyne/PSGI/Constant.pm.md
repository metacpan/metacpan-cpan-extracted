# WebDyne::PSGI::Constant #

# NAME #

WebDyne::PSGI::Constant - PSGI runtime constants for WebDyne

# SYNOPSIS #

```perl
use WebDyne::PSGI::Constant;
```

# DESCRIPTION #

`WebDyne::PSGI::Constant` defines defaults used by the WebDyne PSGI stack. These constants control default document selection, static-file middleware behavior, and which environment variables are preserved into PSGI request handling.

# CONSTANTS #

* **DOCUMENT_ROOT**

    Optional default document root for PSGI execution.

* **DOCUMENT_DEFAULT ('app.psp')**

    Default WebDyne page served when a request resolves to a directory and no explicit `.psp` file is selected.

* **WEBDYNE_PSGI_INDEX ('index.psp')**

    Default index filename used by the wrapper layer.

* **WEBDYNE_PSGI_MIDDLEWARE_STATIC**

    Regular expression used by the default static middleware to decide which non-`.psp` assets may be served directly.

* **WEBDYNE_PSGI_STATIC (1)**

    Enable static-file middleware by default.

* **WEBDYNE_PSGI_MIDDLEWARE**

    Default PSGI middleware stack wrapped around the WebDyne PSGI application.

* **WEBDYNE_PSGI_ENV_KEEP / WEBDYNE_PSGI_ENV_SET**

    Environment variables preserved from or injected into the PSGI runtime.

* **WEBDYNE_PSGI_WARN_ON_ERROR**

    Optional flag controlling warning behavior on PSGI-side errors.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
