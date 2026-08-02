# wdapacheinit #

# NAME #

wdapacheinit - Install or uninstall WebDyne Apache configuration files

# SYNOPSIS

`wdapacheinit [--option]`

`wdapacheinit --cache /var/www/cache`

`wdapacheinit --print`

`wdapacheinit --uninstall`

# DESCRIPTION

`wdapacheinit` will install or uninstall the WebDyne Apache configuration files. 
It will create the necessary configuration files and directories for Apache to serve WebDyne pages. 
The script will also attempt to set the correct ownership and permissions on the cache directory.

Command-line options are copied into uppercase environment variables before the Apache discovery constants are loaded, so supplied options override the detected values.

NOTE: Apache must be restarted after running this script !

# OPTIONS

* **--help**

    Display a brief help message and exit.

* **--man**

    Display the full manual.

* **--apache_uname=USER**

    Specify the Apache user name.

* **--apache_gname=GROUP**

    Specify the Apache group name.

* **--httpd_bin=PATH**

    Specify the path to the httpd binary.

* **--apachectl_bin=PATH**

    Specify the path to the apachectl or apache2ctl binary.

* **--apxs_bin=PATH**

    Specify the path to the apxs binary.

* **--dir_apache_conf=DIR**

    Specify the directory for Apache configuration files.

* **--dir_apache_modules=DIR**

    Specify the directory for Apache modules.

* **--file_mod_perl_lib=PATH**

    Specify the path to the mod_perl library.

* **--mp2**

    Use mod_perl 2.

* **--webdyne_cache_dn=DIR**

    Specify the directory for WebDyne cache.

* **--silent**

    Suppress installer status messages.

* **--setcontext**

    When SELinux is detected, change the context of module library files that would otherwise only generate a warning. Cache directory context handling is attempted independently when SELinux support is available.

* **--uninstall**

    Uninstall the WebDyne Apache configuration.

* **--text**

    Print the complete generated Apache/WebDyne configuration fragments and exit without writing files, creating directories, changing ownership, or enabling Apache configuration.

* **--dry_run**

    Report install or uninstall actions without writing, removing, linking, changing ownership, or changing SELinux context.

* **--dump_opt**

    Dump the processed option hash and exit.

* **--dump_config**

    Dump the resolved Apache/WebDyne installation configuration after discovery and exit.

* **--version**

    Display the script version and exit.


# EXAMPLES

The script will attempt to automatically detect the correct settings for your system, so in most cases you will not need to specify any options. However, you can override the defaults by specifying the options on the command line.

`wdapacheinit`

`wdapacheinit --cache /var/www/cache`

`wdapacheinit --print`

`wdapacheinit --uninstall`

# NOTES

Apache installation of WebDyne is split into two components. The first is the installation of the WebDyne Apache configuration files, which is done by this script. The second is the installation of the configuration files for the WebDyne framework to enable rendering of WebDyne pages.

The generated WebDyne Perl configuration contains variables that can be set to change the behaviour of the WebDyne system.

Where Apache uses a conf.d-style include directory, the generated WebDyne Apache include is written there and the main Apache configuration file is not changed. Where no such include directory is detected, the script updates the main Apache configuration between WebDyne delimiter markers.

During uninstall, cache cleanup is limited to files in the resolved WebDyne cache directory whose names match WebDyne's compiled cache pattern: a 32-character word name, optionally followed by `.html`. The cache directory itself is removed only if it is empty afterwards and is not the system temporary directory.

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
