# WebDyne::Request::Common #

# NAME #

WebDyne::Request::Common - helper functions for building normalized WebDyne request adapters

# SYNOPSIS #

```perl
use WebDyne::Request::Common qw(
    handler_methods_all
    handler_methods_check
    handler_methods_init
);
```

# DESCRIPTION #

`WebDyne::Request::Common` is an internal support module used by the request adapter classes such as `WebDyne::Request::Fake`, `WebDyne::Request::Apache`, `WebDyne::Request::PSGI`, and `WebDyne::Request::PAGI`.

It defines the canonical method set expected of a WebDyne request object and provides helpers for wiring adapter methods onto concrete request classes.

# FUNCTIONS #

* **handler_methods_all()**

    Return an array reference containing the full normalized request-method set expected by WebDyne.

* **handler_methods_check($class, \%methods)**

    Verify that the supplied request-adapter class defines or inherits the required normalized methods. It also warns about locally defined adapter methods that are not part of the canonical surface.

* **handler_methods_init($class, $backend_class, \%dispatch)**

    Install adapter methods into `$class` using a dispatch table. Dispatch values may be backend method names, code references, or `undef` to fall back to `WebDyne::Request::Fake`.

# NOTES #

This is an internal integration module rather than a page-facing API. It is primarily useful when adding a new WebDyne request backend.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
