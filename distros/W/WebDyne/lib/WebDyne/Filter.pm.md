# WebDyne::Filter #

# NAME #

WebDyne::Filter - request and response filter module for the WebDyne handler chain

# SYNOPSIS #

```perl
__PERL__
use WebDyne::Filter;
```

# DESCRIPTION #

`WebDyne::Filter` is a chaining module that intercepts WebDyne request handling so request and response filter callbacks can be run around the normal page lifecycle.

When imported from a page `__PERL__` block, it switches the page to `WebDyne::Chain` handling and adds itself to the active chain.

# METHODS #

* **request($self, $r, @param)**

    Run the request-side filter callback if one is configured. The module first checks `dir_config('WebDyneFilterRequest')`, then the global `WEBDYNE_FILTER_REQUEST_CR`.

* **response($self, $r, $html_sr)**

    Run the response-side filter callback if one is configured. The module first checks `dir_config('WebDyneFilterResponse')`, then the global `WEBDYNE_FILTER_RESPONSE_CR`.

* **handler($self, $r, @param)**

    Internal chaining handler that runs the request filter, wraps the response `print()` method, and passes control to the next handler in the chain.

# OPTIONS #

`WebDyne::Filter` does not take import-time options of its own. Configure filter callbacks through `WebDyne::Filter::Constant` or directory configuration.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
