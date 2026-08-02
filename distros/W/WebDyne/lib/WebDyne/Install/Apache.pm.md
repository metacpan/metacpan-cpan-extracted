# WebDyne::Install::Apache #

# NAME #

WebDyne::Install::Apache - Apache configuration installer for WebDyne

# SYNOPSIS #

```perl
use WebDyne::Install::Apache;

WebDyne::Install::Apache->install($prefix, $installbin_dn, \%options);
WebDyne::Install::Apache->uninstall($prefix, $installbin_dn, \%options);
```

# DESCRIPTION #

`WebDyne::Install::Apache` installs or removes Apache-side configuration files required for serving WebDyne pages under Apache/mod_perl.

The module builds rendered configuration files from bundled templates, merges values from `WebDyne::Constant`, `WebDyne::Install::Constant`, and `WebDyne::Install::Apache::Constant`, ensures the base WebDyne installation step has run, and writes or removes the generated Apache config and WebDyne Perl config files.

# METHODS #

* **install($prefix, $installbin_dn, \%options)**

    Run the Apache installer. This writes rendered configuration files derived from the bundled templates. If `text` is true in the options hash, the complete generated Apache/WebDyne config is printed instead of written to disk. If `dry_run` is true, planned filesystem and ownership changes are reported but not applied.

* **uninstall($prefix, $installbin_dn, \%options)**

    Run the uninstall path, removing generated Apache-side configuration files and delegating cache-directory cleanup to the base installer layer. If `dry_run` is true, planned removals are reported but not applied.

# NOTES #

The module depends on the discovery logic in `WebDyne::Install::Apache::Constant` for Apache binary detection, config directory selection, mod_perl library discovery, and SELinux-related helpers.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
