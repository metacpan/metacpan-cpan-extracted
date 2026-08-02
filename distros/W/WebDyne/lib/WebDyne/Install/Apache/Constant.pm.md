# WebDyne::Install::Apache::Constant #

# NAME #

WebDyne::Install::Apache::Constant - Apache-install discovery and template constants for WebDyne

# SYNOPSIS #

```perl
use WebDyne::Install::Apache::Constant;
```

# DESCRIPTION #

`WebDyne::Install::Apache::Constant` discovers Apache-related paths and defaults used by the Apache installer. It resolves the Apache binary, configuration directories, module directories, mod_perl library path, Apache runtime user/group, SELinux helpers, and template filenames used by `WebDyne::Install::Apache`.

# CONSTANTS #

Commonly used constants include:

* **MP2_INSTALLED**

    Boolean indicating whether mod_perl 2 appears to be installed.

* **HTTPD_BIN**

    Resolved path to the Apache `httpd` binary.

* **APACHECTL_BIN**

    Resolved path to `apachectl` or `apache2ctl`, used as a fallback source for Apache `-V` configuration output.

* **APXS_BIN**

    Resolved path to `apxs`, `apxs2`, or `apxs2.4`, used to query Apache development installation paths when available.

* **DIR_APACHE_CONF**

    Resolved Apache configuration directory.

* **DIR_APACHE_CONF_ENABLED**

    Resolved Debian-style enabled configuration directory when `conf-available` and `conf-enabled` are detected.

* **DIR_APACHE_MODULES**

    Resolved Apache modules directory.

* **FILE_MOD_PERL_LIB**

    Resolved mod_perl shared library path.

* **APACHE_UNAME / APACHE_GNAME**

    Detected Apache user and group names.

* **APACHE_UID / APACHE_GID**

    Detected Apache user and group numeric identifiers.

* **FILE_WEBDYNE_CONF_TEMPLATE / FILE_WEBDYNE_CONF**

    Input template filename and rendered Apache config filename.

* **FILE_WEBDYNE_CONF_PL_TEMPLATE / FILE_WEBDYNE_CONF_PL**

    Input template filename and rendered WebDyne Perl config filename.

* **SELINUX_CONTEXT_HTTPD / SELINUX_CONTEXT_LIB**

    SELinux context names used during installation checks and setup.

* **SELINUX_ENABLED_BIN / SELINUX_CHCON_BIN / SELINUX_SEMANAGE_BIN**

    Discovered helper binaries used for SELinux detection and context changes.

# METHODS #

This module also exposes helper routines used internally by the installer:

* **httpd_bin()**

    Locate the Apache executable.

* **apachectl_bin()**

    Locate the Apache control executable.

* **apxs_bin() / apxs_config()**

    Locate APXS and query Apache development installation paths.

* **httpd_config()**

    Inspect Apache configuration and derive path details.

* **dir_apache_conf()**

    Resolve the Apache configuration directory.

* **dir_apache_modules()**

    Resolve the Apache modules directory.

* **file_mod_perl_lib()**

    Locate the mod_perl shared library.

* **mp2_installed()**

    Determine whether mod_perl 2 support is available.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
