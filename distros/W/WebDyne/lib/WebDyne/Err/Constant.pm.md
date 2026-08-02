# WebDyne::Err::Constant #

# NAME #

WebDyne::Err::Constant - error-template and low-level error-mode constants for WebDyne

# SYNOPSIS #

```perl
use WebDyne::Err::Constant;
```

# DESCRIPTION #

`WebDyne::Err::Constant` defines constants used by the WebDyne error subsystem. It is a small companion module for locating the bundled error template and controlling whether low-level error output should be rendered as HTML or plain text.

# CONSTANTS #

* **WEBDYNE_ERR_TEMPLATE**

    Absolute path to the bundled `error.psp` template used for HTML error rendering.

* **WEBDYNE_ERROR_TEXT (0)**

    When true, render errors as `text/plain` instead of HTML.

* **WEBDYNE_ERROR_EXIT (0)**

    When true, signal that error handling should terminate the child/request flow after output.

# METHODS #

* **class_dn($class)**

    Internal helper that resolves the installed directory for a package name by consulting `%INC`.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
