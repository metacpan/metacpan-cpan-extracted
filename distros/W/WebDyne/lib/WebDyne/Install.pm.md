# WebDyne::Install #

# NAME #

WebDyne::Install - base installation helper for WebDyne cache setup

# SYNOPSIS #

```perl
use WebDyne::Install qw(message);

WebDyne::Install->install($prefix);
WebDyne::Install->uninstall($prefix);
```

# DESCRIPTION #

`WebDyne::Install` provides the base installation and uninstall routines used by the WebDyne installer scripts and higher-level installer modules.

Its main job is to determine the appropriate cache directory, create it during installation, and remove WebDyne-managed cache artifacts during uninstall.

# METHODS #

* **install($prefix)**

    Create the cache directory if required and report progress through `message()`. If `DRY_RUN` is set in the environment, report the action without creating the directory.

* **uninstall($prefix)**

    Remove cached compile artifacts from the resolved cache directory and attempt to remove the directory if appropriate. Cache cleanup is limited to files whose names match a 32-character word name, optionally followed by `.html`.

* **cache_dn($prefix)**

    Resolve the cache directory path from `WEBDYNE_CACHE_DN`, an installation prefix, or `DIR_CACHE_DEFAULT`.

* **message(@args)**

    Print installer progress messages unless `SILENT` is set in the environment.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
