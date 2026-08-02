# WebDyne::Util #

# NAME #

WebDyne::Util - debugging and error-stack utility functions for WebDyne

# SYNOPSIS #

```perl
use WebDyne::Util;

debug('message: %s', $value);
err('something failed');
my $msg = errstr();
```

# DESCRIPTION #

`WebDyne::Util` provides the common debugging, error-stack, and error-formatting functions used throughout the WebDyne codebase.

It exports the standard utility functions by default and uses environment variables such as `WEBDYNE_DEBUG`, `WEBDYNE_DEBUG_FILE`, `WEBDYNE_DEBUG_FILTER`, and related settings to control runtime debug output.

`perl_inc_dn` is exported by default and can also be requested explicitly. `apache_startup` and `apache_shutdown` are available on request, or through the `:all` export tag.

# FUNCTIONS #

* **debug($message, @args)**

    Emit a formatted debug message if debugging is enabled for the calling package or environment.

* **err($message, @args)**

    Push an error message onto the WebDyne error stack.

* **errstr()**

    Return the current error string.

* **errclr()**

    Clear the current error state.

* **errsubst(...)**

    Apply error-text substitutions and formatting helpers.

* **errdump(...)**

    Produce a formatted dump of the current error stack and related diagnostics.

* **errstack()**

    Return the current error stack.

* **errnofatal($bool)**

    Control whether errors are treated as fatal by the utility layer.

* **perl_inc_dn()**

    Return non-default library directories from `@INC`.

* **apache_startup(\%options)**

    Start an Apache::Test runner instance with a caller-supplied postamble.

* **apache_shutdown($runner)**

    Stop an Apache::Test runner instance if it is active.

# NOTES #

This module is foundational to the rest of WebDyne. Most other modules import it for debug and error handling.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
