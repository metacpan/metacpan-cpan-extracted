# wddump(1) #

# NAME #

wddump - dump the data structure of a WebDyne page in the cache directory

# SYNOPSIS #

`wddump [OPTIONS] FILE`

# Description #

The  `wddump`  command displays internal the data structure of a compiled WebDyne psp file from the WebDyne cache directory. The  `wddump`  utility is of limited diagnostic use \- the  `wdcompile`  tool is more suitable for troubleshooting HTML tree errors.

`wddump`  can be useful to see a picture of the final data structure looks like on complex pages built via many filters, combining static and dynamic blocks etc.

# Options #

* **-h, --help**

    Show brief help message.

# Examples #

```sh
# Display the data structure from a compiled, cached webdyne time.psp file. File name and location
# will vary depending on your configuration 
#
$ wdrender /var/webdyne/cache/26f2c4edc8bfd52fbde915290db96779

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

Written by Andrew Speer,  <andrew@webdyne.org>

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright \(c) 2025 by Andrew Speer &lt;andrew.speer@isolutions.com.au&gt;.

This is free software; you can redistribute it and/or modify it underthe same terms as the Perl 5 programming language system itself.

Full license text is available at:

&lt;http://dev.perl.org/licenses/&gt;