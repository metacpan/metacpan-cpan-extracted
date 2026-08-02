# WebDyne::HTML::TreeBuilder #

# NAME #

WebDyne::HTML::TreeBuilder - HTML::TreeBuilder subclass used by the WebDyne compiler

# SYNOPSIS #

```perl
use WebDyne::HTML::TreeBuilder;

my $tree = WebDyne::HTML::TreeBuilder->new();
$tree->parse_fh($fh);
```

# DESCRIPTION #

`WebDyne::HTML::TreeBuilder` is the parser front end used by the WebDyne compiler. It subclasses `HTML::TreeBuilder`, teaches the parser about WebDyne-specific tags and CGI-style shortcut tags, preserves line-number context, and transforms parsed HTML into the internal tree structures used by the rest of the framework.

It also coordinates with `WebDyne::HTML::Tiny` for generated markup fragments and shortcut expansion.

# METHODS #

Notable methods include:

* **new(%options)**

    Construct a parser instance. An existing `WebDyne::HTML::Tiny` object may be supplied as `html_tiny_or`.

* **parse_fh($fh)**

    Parse a source file handle while tracking line numbers and WebDyne-specific syntax.

* **tag_parse(...)**

    Internal tag parser for WebDyne-specific or specially handled elements.

* **process() / start() / end() / text() / comment()**

    Core parser event handlers.

* **start_html() / end_html()**
* **start_form() / end_form()**
* **start_multipart_form() / end_multipart_form()**
* **include()**
* **perl()**
* **json()**
* **htmx()**
* **api()**

    Special handlers for WebDyne tags or compile-time shortcut tags.

# NOTES #

The module extends `HTML::Tagset` behavior at load time so WebDyne tags participate correctly in parsing, list handling, table handling, and paragraph-closing rules.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
