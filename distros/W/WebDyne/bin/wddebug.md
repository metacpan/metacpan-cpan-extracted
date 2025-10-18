
# NAME

wddebug - This script is used to enable or disable debugging in the WebDyne packages.

# SYNOPSIS

`wddebug [--option]`

`wddebug --directory /opt/perl5`

# DESCRIPTION

By default debugging is optimized out of the WebDyne modules. This script can be used to enable or disable debugging in those modules for troubleshooting purposes.
Debugging can be turned on or off in the WebDyne modules by running this script with the appropriate options. With no options the script will return the current status
of debugging in the WebDyne modules.

#  METHODOLOGY

Debugging is enabled in all soucre modules in the form of debug('message') calls. These calls are optimized out of the code during installation via a PM_FILTER in MakeMaker
unless the WEBDYNE_DEBUG environment variable is set. Once optimised out the debug calls are not available for use as they are converted in the code to the form `0 && debug('message')`,
which is optimised away by the perl compilers.  This script will enable or disable the debug calls in already installed moduled by adding or removing the `0 &&` prefix from the code. 

As this edits installed modules it is not recommended for use in a production environment. If debugging is neccessary it is better to install WebDyne on a test system with the command

```sh
#  Install WebDyne with debugging enabled via MakeMaker
perl Makefile.PL WEBDYNE_DEBUG=1
make install
```

```sh
#  Install WebDyne with debugging enabled via cpanm
WEBDYNE_DEBUG=1 cpanm WebDyne
```

# OPTIONS

- `--status`
  Display the current debug status of the WebDyne modules. The default if no option given

- `--enable`
  Enable debugging in the WebDyne modules.

- `--disable`
  Disable debugging in the WebDyne modules.

- `--directory`
  Specify the directory containing the WebDyne modules.

- `--yes`
  Automatically confirm the prompt to proceed with enabling or disabling debugging.

- `--help | -?`
  Display a brief help message and exit.

- `--man`
  Display the full manual.

- `--version`
  Display the script version and exit.


# EXAMPLES

```sh
# Turn on debugging in the WebDyne modules:
wddebug --enable
````

```sh
# Turn off debugging in the WebDyne modules in /opt/perl5:
wddebug --disable --directory /opt/perl5
```

# DEBUGGING

Actual debugging output is controlled by enviornment variables. See the WebDyne documentation for more information but 
in brief, setting the `WEBDYNE_DEBUG` environment variable to a value of 1 will enable all debugging output. Setting it
to a string value that corresponds to a module or method will filter the debugging output to that module or method.

```sh
# Debug compilation of a file
WEBDYNE_DEBUG=1 wdcompile time.psp
```

```sh
# Debug render of a file
WEBDYNE_DEBUG=1 wdrender time.psp
```

```sh
# Debug a specific method
WEBDYNE_DEBUG=render wdrender time.psp
```

```sh
# Multiple methods can be debugged
WEBDYNE_DEBUG=render,compile wdrender time.psp
```

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2025 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>