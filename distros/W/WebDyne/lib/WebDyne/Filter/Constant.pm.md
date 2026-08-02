# WebDyne::Filter::Constant #

# NAME #

WebDyne::Filter::Constant - request and response filter callback constants for WebDyne

# SYNOPSIS #

```perl
use WebDyne::Filter::Constant;
```

# DESCRIPTION #

`WebDyne::Filter::Constant` defines the callback slots used by the `WebDyne::Filter` subsystem. These constants allow configuration files to nominate global request and response filter code references.

# CONSTANTS #

* **WEBDYNE_FILTER_REQUEST_CR**

    Optional code reference run against request-side data before normal page handling.

* **WEBDYNE_FILTER_RESPONSE_CR**

    Optional code reference run against response-side data before output is finalized.

# NOTES #

The callbacks default to `undef`. They are intended to be populated from configuration rather than hard-coded in the module itself.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
