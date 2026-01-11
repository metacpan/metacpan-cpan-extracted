
# NAME

wdapacheinit - Install or uninstall WebDyne Apache configuration files

# SYNOPSIS

`wdapacheinit [--option]`

`wdapacheinit --cache /var/www/cache`

# DESCRIPTION

`wdapacheinit` will install or uninstall the WebDyne Apache configuration files. 
It will create the necessary configuration files and directories for Apache to serve WebDyne pages. 
The script will also attempt to set the correct permissions on the cache directory.

NOTE: Apache must be restarted after running this script !

# OPTIONS

- `--help | -?`
  Display a brief help message and exit.

- `--man`
  Display the full manual.

- `--apache_uname | --uname`
  Specify the Apache user name.

- `--apache_gname | --gname`
  Specify the Apache group name.

- `--httpd_bin | --httpd`
  Specify the path to the httpd binary.

- `--dir_apache_conf | --apache_conf | --conf`
  Specify the directory for Apache configuration files.

- `--dir_apache_modules | --apache_modules | --modules`
  Specify the directory for Apache modules.

- `--file_mod_perl_lib | --mod_perl_lib | --mod_perl`
  Specify the path to the mod_perl library.

- `--mp2`
  Use mod_perl 2.

- `--webdyne_cache_dn | --webdyne_cache | --cache_dn | --cache | --dir_webdyne_cache`
  Specify the directory for WebDyne cache.

- `--silent`
  Run the script in silent mode.

- `--setcontext`
  Set the context for the script.

- `--uninstall`
  Uninstall the WebDyne Apache configuration.

- `--text | --print`
  Print the configuration.

- `--version`
  Display the script version and exit.


# EXAMPLES

The script will attempt to automatically detect the correct settings for your system, so in most cases you will not need to specify any options. However, you can override the defaults by specifying the options on the command line.

`wdapacheinit`

`wdapacheinit --cache /var/www/cache`

# NOTES

Apache installation of WebDyne is split into two components. The first is the installation of the WebDyne Apache configuration files, which is done by this script. The second is the installation of the configuration files for the WebDyne framework to enable renderings
of WebDyne pages. 

The second component is of configuration variables that can be set to change behaviour of the WebdDyne system, 

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>