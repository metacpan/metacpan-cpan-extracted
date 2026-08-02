# WebDyne::Chain::Constant #

# NAME #

WebDyne::Chain::Constant - constant namespace for `WebDyne::Chain`

# SYNOPSIS #

```perl
use WebDyne::Chain::Constant;
```

# DESCRIPTION #

`WebDyne::Chain::Constant` exists primarily so the normal WebDyne constant-loading mechanism can import configuration for the chaining subsystem from standard WebDyne configuration files.

In the current code this module does not define any chain-specific constants of its own. It is an extension point and import target rather than a feature-bearing API.

# CONSTANTS #

This module currently defines an empty `%Constant` hash.

# NOTES #

Use this module when you want a stable configuration namespace for future `WebDyne::Chain`-specific settings in `webdyne.conf.pl`.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
