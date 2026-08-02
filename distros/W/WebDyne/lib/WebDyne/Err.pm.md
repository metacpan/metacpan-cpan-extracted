# WebDyne::Err #

# NAME #

WebDyne::Err - error rendering and eval-error support for WebDyne

# SYNOPSIS #

```perl
use WebDyne::Err;

my $status = $self->err_html('something went wrong');
```

# DESCRIPTION #

`WebDyne::Err` provides the runtime error handlers used by the WebDyne framework. It can render errors either as plain text or through the bundled WebDyne HTML error template, log them against the active request object, and translate eval failures into user-facing error output.

# METHODS #

* **err_html($self, $message, @args)**

    Main error-rendering routine. Logs the error, ensures an error HTTP status is set, and emits either text or HTML error output depending on configuration and runtime conditions.

* **err_eval(...)**

    Helper used for formatting and presenting eval-related failures.

# NOTES #

Behavior is influenced by constants in `WebDyne::Constant` and `WebDyne::Err::Constant`, especially:

* `WEBDYNE_ERROR_TEXT`
* `WEBDYNE_ERROR_EXIT`
* `WEBDYNE_ERR_TEMPLATE`
* the various `WEBDYNE_ERROR_*` display controls

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
