# wddebug(1) #

# NAME #

wddebug - enable or disable debugging in the WebDyne packages

# SYNOPSIS #

`wddebug [--OPTION]`

`wddebug --enable`

`wddebug --enable --directory /opt/perl5`

# Description #

By default debugging is optimized out of the WebDyne modules to increase performance. This script can be used to enable or disable debugging for troubleshooting purposes. Debugging can be turned on or off in the WebDyne modules by running this script with the appropriate option. With no options the script will return the current status of debugging in the WebDyne
 modules.

# Options #

* **--status**

    Display the current debug status of the WebDyne modules. The default if no option given.

* **--enable**

    Enable debugging in the WebDyne modules.

* **--disable**

    Disable debugging in the WebDyne modules.

* **--directory**

    Specify the directory containing the WebDyne modules.

* **--yes**

    Automatically confirm the prompt to proceed with enabling or disabling debugging.

* **--help|?**

    Display a brief help message and exit.

* **--man**

     Display the full manual page.

* **--version**

    Display the script version and exit.

# Examples #

```sh
# Show current status
#
$ wddebug
debug location: /opt/perl5/lib/perl5/
debug  enabled: WebDyne.pm
debug disabled: WebDyne/Handler.pm
...

# Turn on debugging for WebDyne modules 
#
$ wddebug --enable

# Turn off debugging
#
$ wddebug --disable

# Install modules from source with debugging enabled
#
$ WEBDYNE_DEBUG=1 perl Makefile.PL
$ make install
```

# Notes #

Debugging is enabled in all source modules in the form of debug(&#39;message&#39;) calls. These calls are optimized out of the code during installation via a PM_FILTER in MakeMaker unless the WEBDYNE_DEBUG environment variable is set. Once optimised out the debug calls are not available for use as they are converted in the code to the form \` `0 &&
    debug('message')` , which is optimised away by the Perl compiler. This script will enable or disable the debug calls in already installed modules by adding or removing the  `0
    &&`  prefix from the code.  **As this edits installed modules it is not recommended for use in a production environment** . If debugging is necessary it is better to install WebDyne on a test system with the command:

```
$ WEBDYNE_DEBUG=1 perl Makefile.PL && make install
```

# Debugging #

Actual debugging output is controlled by environment variables. See the WebDyne documentation for more information but in brief, setting the  WEBDYNE_DEBUG  environment variable to a value of 1 will enable all debugging output. Setting it to a string value that corresponds to a module or method will filter the debugging output to that module or
 method.

```
# Debug compilation of a file
#
WEBDYNE_DEBUG=1 wdcompile time.psp

# Debug render of a file
#
WEBDYNE_DEBUG=1 wdrender time.psp

# Debug a specific method
#
WEBDYNE_DEBUG=render wdrender time.psp

# Multiple methods can be debugged
#
WEBDYNE_DEBUG=render,compile wdrender time.psp

```

# Author #

Written by Andrew Speer,  <andrew@webdyne.org>

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright \(c) 2025 by Andrew Speer &lt;andrew.speer@isolutions.com.au&gt;.

This is free software; you can redistribute it and/or modify it underthe same terms as the Perl 5 programming language system itself.

Full license text is available at:

&lt;http://dev.perl.org/licenses/&gt;