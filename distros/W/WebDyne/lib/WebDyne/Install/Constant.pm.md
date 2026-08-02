# WebDyne::Install::Constant #

# NAME #

WebDyne::Install::Constant - installer defaults used by WebDyne installation helpers

# SYNOPSIS #

```perl
use WebDyne::Install::Constant;
```

# DESCRIPTION #

`WebDyne::Install::Constant` defines shared defaults used by the installer modules. In the current code this is limited to the default cache directory path chosen when no explicit cache directory is supplied.

# CONSTANTS #

* **DIR_CACHE_DEFAULT**

    Default cache directory path used by the installer layer.
    
    On Unix-like systems this defaults to `/var/cache/webdyne`.
    
    On Windows it defaults under `%SYSTEMROOT%/TEMP/webdyne`.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
