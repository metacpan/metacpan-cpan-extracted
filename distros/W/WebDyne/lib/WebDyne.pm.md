# WebDyne #

# NAME #

WebDyne - Primary runtime module for the WebDyne framework, with support for standalone `.psp` to HTML rendering

# SYNOPSIS #

```perl
# Framework usage usually happens under a WebDyne-compatible runtime
# such as Apache/mod_perl, PSGI, or PAGI, where WebDyne->handler()
# is called by the request layer.
#
use WebDyne qw(html html_sr);

# Render a .psp file to HTML and return a string
#
my $html = html('app.psp');

# Render a .psp file with template parameters
#
my $html = html('app.psp', {
    param => {
        user => 'alice',
    },
});

# Render a .psp file to HTML and return a scalar ref
#
my $html_ref = html_sr('app.psp');

# Write rendered output to an existing filehandle
#
html('template.psp', { outfile => $fh });
```

# DESCRIPTION #

*WebDyne* is the primary supporting module for the WebDyne framework. In normal use it operates under a web server or application runtime such as Apache/mod_perl, PSGI, or PAGI, where it acts as the main request handler and rendering engine for `.psp` pages.

The module can also be used directly from scripts to render `.psp` templates to HTML without a web server, which is useful for tooling, diagnostics, offline generation, and simple standalone usage. In that mode the main entry points are `html()` and `html_sr()`.

The `html()` and `html_sr()` functions are exported only on request:

```perl
use WebDyne qw(html html_sr);
```

WebDyne supports embedded Perl within HTML, compile-time parsing and caching, chained handler modules, filters, templates, CGI-style parameter access, and integration with the wider WebDyne module family.

Comprehensive documentation around `.psp` page construction and framework usage is available in the module source tree and the [Github repository](https://github.com/aspeer/WebDyne).

The simplest representation of a `.psp` file that can be rendered is:

```
<start_html>
The current server time is: <? localtime() ?>
```

If this example is saved as `app.psp`, it can be rendered from the command line with `wdrender`:

    $ wdrender app.psp
     
    <!DOCTYPE html><html lang="en"><head><title>Untitled Document</title><meta charset="UTF-8"></head>
    <body><p>The current server time is: ...</p></body></html>

# METHODS #

* **html($filename, \%options, ...)**

    Render a `.psp` file and return the result as a string. This is the convenience wrapper around `html_sr()`.

    Supported calling styles include:

    `html('page.psp')`

    `html('page.psp', { ... })`

    `html('page.psp', key => value, ...)`

    `html({ filename => 'page.psp', ... })`

* **html_sr($filename, \%options, ...)**

    Render a `.psp` file and return a scalar reference to the generated HTML when output is captured internally. This is the core script-facing rendering function.

    If `outfile` is supplied, output is written to that filehandle and `html_sr()` returns a reference to `undef` instead of a scalar reference containing generated HTML. The `html()` wrapper dereferences this, so `html(..., outfile => $fh)` returns `undef`.

    Arguments and options are the same as for `html()`.

    In standalone rendering, `html_sr()` creates a `WebDyne::Request::Fake` request object unless an `r` option is supplied. If a custom `handler` option is supplied, that handler class is loaded before rendering.

* **handler($r, \%params)**

    Main request lifecycle entry point for WebDyne under server environments such as Apache/mod_perl, PSGI, PAGI, and chained WebDyne handler modules. It is not typically called directly from standalone scripts.

    Raw Apache request objects are wrapped in `WebDyne::Request::Apache`; other runtimes normally provide an appropriate WebDyne request object. The return value is the status or response result expected by the active runtime.

# OPTIONS #

The following options are the most commonly used with `html()` and `html_sr()`:

* **filename**

    `.psp` filename to render. Usually supplied as the first argument.

* **handler**

    Custom handler class to use for rendering. Defaults to `WebDyne`.

* **outfile**

    Filehandle to receive rendered output. When supplied, output is written directly and `html_sr()` does not return a scalar reference.

* **param**

    Hash reference of parameters passed into the handler/rendering context for use by page code.

* **r**

    Optional prebuilt request object. If omitted, WebDyne creates a `WebDyne::Request::Fake` object for standalone rendering.

# SEE ALSO #

[Plack](https://metacpan.org/pod/Plack) [Catalyst](https://metacpan.org/pod/Catalyst) [Dancer2](https://metacpan.org/pod/Dancer2) [Mojolicious](https://metacpan.org/pod/Mojolicious)

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au> and contributors.

# LICENSE #

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself. See  [http://dev.perl.org/licenses/](http://dev.perl.org/licenses/) .
