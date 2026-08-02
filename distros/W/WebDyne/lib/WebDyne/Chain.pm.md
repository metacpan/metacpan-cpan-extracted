# WebDyne::Chain #

# NAME #

WebDyne::Chain - WebDyne chaining module, allows extension of base WebDyne handler pipeline with additional modules.

# SYNOPSIS #

SYNOPSIS

```
#  Basic usage. Save as file named chain.psp:
#
<start_html>
Server local time is: <? localtime ?>
__PERL__
use WebDyne::Chain qw(WebDyne::Session)
```

    #  Render with wdrender. Note the session variable
    #
    $ wdrender --header ./chain.psp
    Status: 200
    X-Frame-Options: SAMEORIGIN
    Pragma: no-cache
    Cache-Control: no-cache, no-store, must-revalidate
    Expires: 0
    Content-Type: text/html; charset=UTF-8
    Set-cookie: session=3653dbc88d665db9a4bfabf27a01310c; path=/
    X-Content-Type-Options: nosniff
    Content-Length: 242
    
    <!DOCTYPE html><html lang="en"><head><title>Untitled Document</title><meta charset="UTF-8"><meta content="width=device-width, initial-scale=1.0" name="viewport"></head>
    <body><p>Server local time is: Sun Dec  7 21:56:17 2025</p></body></html>

    # Or extend manually from command line for testing. Does not require use of WebDyne::Chain
    # in page.
    #
    $ WebDyneChain=WebDyne::Session wdrender --header --handler WebDyne::Chain time.psp 

# DESCRIPTION #

WebDyne::Chain allows chaining of modules within the WebDyne pipeline. This allows custom modules to insert themselves into the server handler pipeline, whereby they can make changes to the input or output of WebDyne pages. Common uses may include:

* Setting or getting session tracking data

* Checking for authentication status and redirecting if not valid

* Rewriting input URL&#39;s or parameters, or rewriting output HTML

* Tracking user state from a database connection

WebDyne includes two example Chain modules in the base package:

* **WebDyne::Session**

    Sets/gets a session cookie in the headers

* **WebDyne::Filter**

    Rewrite Request or Response headers, HTML content

When used inside a page, `use WebDyne::Chain ...` is intended for the page `__PERL__` block. The import routine stores the nominated module list in page metadata and switches the page handler to `WebDyne::Chain`.

# USAGE #

WebDyne::Chain allows nomination of modules to chain in a psp page via the import method when using the module. At it&#39;s simplest you can import just the modules you want.

```
<start_html>
Server local time is <? localtime ?>
__PERL__
use WebDyne::Chain qw(WebDyne::Session WebDyne::Filter);
1;
```

WebDyne::Chain will automatically add any methods made available by the chained modules into the page, e.g.

```
<start_html>
Session ID is: <? shift()->session_id() ?>
__PERL__
#  WebDyne::Session exposes the session_id() method used above
#
use WebDyne::Chain qw(WebDyne::Session);
```

In reality most modules that can be loaded by WebDyne::Chain will work when loaded standalone, e.g. the code below is the equivalent to loading WebDyne::Session via WebDyne::Chain:

```
<start_html>
Session ID is: <? shift()->session_id() ?>
__PERL__
#  Will autoload WebDyne::Chain and add itself into the handler pipeline
#
use WebDyne::Session;
```

# METHODS #

WebDyne::Chain does not expose any public methods intended for page code. Its `handler()` implementation is internal and is used to construct and dispatch the nominated handler chain.

# OPTIONS #

WebDyne::Chain does not expose any options other than the names of modules to add to the handler chain via the import() method on module use \- as seen in the Usage section above.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au> and contributors.

# LICENSE #

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself. See  [http://dev.perl.org/licenses/](http://dev.perl.org/licenses/) .
