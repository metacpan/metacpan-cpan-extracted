# WebDyne::PAGI::Constant #

# NAME #

WebDyne::PAGI::Constant - PAGI runtime constants for WebDyne

# SYNOPSIS #

```perl
use WebDyne::PAGI::Constant;
```

# DESCRIPTION #

`WebDyne::PAGI::Constant` defines defaults used by the WebDyne PAGI stack. These values control document-root defaults, default document selection, static-file middleware behavior, environment propagation, and PAGI-specific eval preparation.

# CONSTANTS #

* **DOCUMENT_ROOT**

    Optional default document root for PAGI execution.

* **DOCUMENT_DEFAULT ('app.psp')**

    Default WebDyne page served when a request resolves to a directory and no explicit `.psp` file is selected.

* **WEBDYNE_PAGI_MIDDLEWARE_STATIC**

    Regular expression used by the default static middleware to decide which non-`.psp` assets may be served directly.

* **WEBDYNE_PAGI_STATIC (1)**

    Enable static-file middleware by default.

* **WEBDYNE_PAGI_MIDDLEWARE**

    Default PAGI middleware stack wrapped around the WebDyne PAGI application.

* **WEBDYNE_PAGI_ENV_KEEP / WEBDYNE_PAGI_ENV_SET**

    Environment variables preserved from or injected into the runtime environment.

* **WEBDYNE_PAGI_WARN_ON_ERROR**

    Optional flag controlling warning behavior on PAGI-side errors.

* **WEBDYNE_PAGI_EVAL_PREPEND**

    Perl source prepended for PAGI eval contexts. In the current code this loads `Future::AsyncAwait`.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
