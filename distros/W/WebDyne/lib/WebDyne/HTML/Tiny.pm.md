# WebDyne::HTML::Tiny #

# NAME #

WebDyne::HTML::Tiny - HTML::Tiny subclass with WebDyne page and form helpers

# SYNOPSIS #

```perl
use WebDyne::HTML::Tiny;

my $html = WebDyne::HTML::Tiny->new();
print $html->start_html({ title => 'Demo' });
```

# DESCRIPTION #

`WebDyne::HTML::Tiny` extends `HTML::Tiny` with helpers used by the WebDyne compiler and runtime. It adds `start_html`-style shortcuts, CGI-like form tag helpers, request-aware value persistence, global default meta and header insertion, and a number of convenience methods for common form controls.

The module is used both directly and through `WebDyne::HTML::TreeBuilder`.

# METHODS #

Notable methods include:

* **new(%options)**

    Construct a `WebDyne::HTML::Tiny` object. The current request may be supplied as `r => $request`.

* **Vars()**

    Return cached form parameters from the current request’s CGI wrapper.

* **CGI()**

    Return the `WebDyne::CGI::Simple` object associated with the current request.

* **shortcut() / shortcut_enable() / shortcut_disable()**

    Control support for WebDyne shortcut tags such as `start_html`, `start_form`, and related aliases.

* **html() / head() / meta() / script() / link()**

    Override or extend the corresponding `HTML::Tiny` output helpers to honor WebDyne defaults and metadata rules.

* **popup_menu() / scrolling_list() / textarea() / checkbox() / checkbox_group() / radio_group()**

    CGI-style form helpers with value persistence behavior derived from the current request.

# NOTES #

Global behavior is influenced by constants such as `WEBDYNE_DTD`, `WEBDYNE_META`, `WEBDYNE_HTML_PARAM`, `WEBDYNE_START_HTML_PARAM`, `WEBDYNE_START_HTML_SHORTCUT_HR`, and `WEBDYNE_HEAD_INSERT`.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
