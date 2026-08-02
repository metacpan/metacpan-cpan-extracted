# wddump #

# NAME #

wddump - dump the data structure of a WebDyne page in the cache directory

# SYNOPSIS #

`wddump [OPTIONS] FILE`

# Description #

The  `wddump`  command reads a compiled WebDyne Storable cache file and displays its internal data structure with `Data::Dumper`. The  `wddump`  utility is of limited diagnostic use \- the  `wdcompile`  tool is more suitable for troubleshooting HTML tree errors.

`wddump`  can be useful for inspecting the final data structure of complex pages built through multiple filters, static blocks, and dynamic blocks.

# Options #

* **--help**

    Show brief help message.

* **--man**

    Display the full manual.

* **--dump_opt**

    Dump the processed option hash and exit.

* **--version**

    Display the script version and exit.

# Examples #

```sh
# Display the data structure from a compiled, cached webdyne time.psp file. 
# File name and location will vary depending on your configuration 
#
$ wddump /var/webdyne/cache/26f2c4edc8bfd52fbde915290db96779

$VAR1 = [
  '<!DOCTYPE html><html lang="en"><head><title>Untitled Document</title><meta charset="UTF-8"><meta content="width=device-width, initial-scale=1.0" name="viewport"></head>
<body><p>The current server time is: ',
  [
    'perl',
    {
      'inline' => 1,
      'perl' => ' localtime() '
    },
    undef,
    undef,
    2,
    2,
    \'time.psp'
  ],
  '</p></body></html>'
];

```

# Author #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright \(c) 2026 by Andrew Speer &lt;andrew.speer@isolutions.com.au&gt;.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

Full license text is available at:

&lt;http://dev.perl.org/licenses/&gt;
