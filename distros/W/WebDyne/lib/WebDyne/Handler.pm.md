# WebDyne::Handler #

# NAME #

WebDyne::Handler - WebDyne handler module, forces use non-chained WebDyne handler. 

# SYNOPSIS #

SYNOPSIS

```perl
#  Basic usage in a simple file in a directory which forces WebDyne::Chain usage
#
<start_html>
Server local time is: <? localtime ?>
__PERL__
use WebDyne::Handler;

```

# DESCRIPTION #

WebDyne::Handler module forces plain \(non-chained) processing of a page. This can be useful in an environment where WebDyne::Chain has been configured to process all pages in a directory via alternate configuration options \(e.g. Dir_config or other settings).

Using this module will ensure there is no pre or post processing of results by any WebDyne::Chain modules. 

`use WebDyne::Handler;` is intended to be called from within a WebDyne page `__PERL__` block. The import routine updates the current page instance so that subsequent handling uses the nominated handler class directly.

> **WARNING**
> 
> If you use WebDyne::Chain to load an authentication or session tracking module they will not be run on any pages that use this module, which may result in inadvertently allowing unauthenticated access to pages.
>

# USAGE #

WebDyne::Handler is used as per the synopsis.

You can also nominate a specific handler class explicitly:

```perl
__PERL__
use WebDyne::Handler handler => 'WebDyne';
```

or with the single-argument shorthand:

```perl
__PERL__
use WebDyne::Handler 'WebDyne';
```

# METHODS #

WebDyne::Handler does not expose any public methods.

# OPTIONS #

WebDyne::Handler accepts an optional handler class name at import time. The following forms are supported:

* `use WebDyne::Handler;`

    Reset the page to the plain `WebDyne` handler flow.

* `use WebDyne::Handler 'Some::Handler';`

    Use the nominated handler class.

* `use WebDyne::Handler handler => 'Some::Handler';`

    Named form of the same option.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au> and contributors.

# LICENSE #

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself. See  [http://dev.perl.org/licenses/](http://dev.perl.org/licenses/) .
