# wdrender #

# NAME #

wdrender - parse and render WebDyne files

# SYNOPSIS #

`wdrender [OPTIONS] FILE`

# DESCRIPTION #

`wdrender` renders a WebDyne source file and prints the resulting response body to standard output.

By default it uses the internal `WebDyne` handler with the `fake` request backend. It can also exercise other backends such as `psgi`, `psgi_server`, `pagi`, and `mod_perl`, or use a different handler module via `--handler`.

Defaults:

* request backend: `fake`
* method: `GET`
* root: current working directory
* colour: enabled
* line numbers: enabled
* tidy formatting: enabled
* head insertion: disabled
* theme: `light`

Options can also be preloaded from `~/.wdrender.opt` by creating an anonymous hash of option names and values.

# OPTIONS #

## General ##

* **--help**

    Show brief help output \(synopsis and options).

* **--man**

    Display the full manual.

* **--version**

    Display the script version and WebDyne version, then exit.

* **--handler=MODULE**

    Use a different WebDyne handler module, for example `WebDyne::Chain`.

* **--conf=FILE**

    Set `WEBDYNE_CONF` to the specified configuration file before rendering.

* **--no_conf**

    Disable normal config loading by setting `WEBDYNE_CONF=.`.

* **--raw**

    Disable config loading and skip HTML tidy/colour formatting.

* **--outfile=FILE**

    Send output to nominated file. Colourisation is disabled but tidy will be performed if available.
    
* **--test**

    Use WebDyne's built-in default test page as the source file.

* **--warn**

    Enable or disable warnings about missing Tidy or Colourise modules

* **--head_insert**

    Enable or disable WebDyne head insertion while rendering from the command line, including configured `WEBDYNE_HEAD_INSERT` content and related `start_html` parameters. This is disabled by default so command-line checks show the page output without head snippets normally inserted during Apache, PSGI, or PAGI request handling.

## Backend Selection ##

* **--request=TYPE**

    Select one or more backends used to execute the request. Repeat the option to run multiple backends. Valid values are `fake`, `psgi`, `psgi_server`, `pagi`, `mod_perl`, and `all`.

* **--fake**

    Shortcut for `--request=fake`.

* **--psgi**

    Shortcut for `--request=psgi`.

* **--psgi_server**

    Shortcut for `--request=psgi_server`.

* **--pagi**

    Shortcut for `--request=pagi`.

* **--mod_perl**

    Shortcut for `--request=mod_perl`.

* **--all**

    Run all supported backends instead of just one selected backend. This is equivalent to `--request=all`.

* **--root=DIR**

    Set the document root passed to backend handlers. Defaults to the current working directory.

* **--keep_tmp**

    When using the `mod_perl` backend, do not cleanup temporary Apache server root.

* **--apache_stdout**

    When using the `mod_perl` backend, send Apache access/error logs to stdout/stderr where possible instead of suppressing them.

* **--dump_postamble**

    Print the generated Apache postamble and exit instead of starting the Apache test instance.

* **--dump_opt**

    Dump the parsed option hash for debugging and exit.

## Request Construction ##

* **--method=VERB**

    Explicitly set the HTTP method, for example `GET`, `POST`, `PUT`, `PATCH`, `OPTIONS`, or `HEAD`.

* **--get=KEY=VALUE**

    Add request parameters and use `GET`.

* **--post=KEY=VALUE**

    Add request parameters and use `POST`.

* **--put=KEY=VALUE**

    Add request parameters and use `PUT`.

* **--patch=KEY=VALUE**

    Add request parameters and use `PATCH`.

* **--options=KEY=VALUE**

    Add request parameters and use `OPTIONS`.

Request parameter options may be repeated, and each value may contain multiple `;` or `&` separated key/value pairs. Keys and values may be separated with `=` or `:`.

* **--head**

    Use `HEAD`.

* **--param=KEY=VALUE**

    Pass handler parameters to the WebDyne handler call. These are separate from request query/body parameters and are available to handler-side Perl code. Repeat the option or separate entries with `;` or `&`. Duplicate keys are preserved as array values.

* **--headers_in=NAME:VALUE**

    Add request headers. Multiple values may be supplied by repeating the option.

* **--htmx**

    Add the request header `HX-Request: true`.

* **--sse**

    Add the request header `Accept: text/event-stream`.

## Response Display ##

* **--header**

    Include the response status line and headers ahead of the rendered body.

* **--header_only**

    Print only the response status line and headers.

* **--colour**

    Enable or disable HTML syntax highlighting for `text/html` responses.

* **--lineno**

    Enable or disable line numbers in colourised output.

* **--theme=light|dark**

    Select the colour theme used by syntax highlighting.

* **--tidy**

    Enable or disable HTML tidy formatting for `text/html` responses. Tidy is skipped automatically for HTMX output.

## Repetition and Comparison ##

* **--repeat=NUM**

    Repeat the render `NUM` times.

* **--compare**

    When repeating renders, require each rendered body to match the first one. If output differs, the script aborts and shows a diff when `Text::Diff` is installed.

* **--loop**

    Repeat forever. Intended for leak or stability testing.

* **--delay=SECONDS**

    Sleep between iterations.

# EXAMPLES #

```sh
# Show the rendered version of time.psp
wdrender time.psp
```

```sh
# Show headers as well as the body
wdrender --header time.psp
```

```sh
# Show only the status line and headers
wdrender --header-only time.psp
```

```sh
# Render using a different handler
WebDyneChain=WebDyne::Session wdrender --handler WebDyne::Chain time.psp
```

```sh
# Simulate a GET request with query parameters
wdrender --get "test=1" checkbox.psp
```

```sh
# Simulate a POST request
wdrender --post "name=alice" form.psp
```

```sh
# Force the PSGI backend
wdrender --psgi app/example.psp
```

```sh
# Compare repeated renders for stability
wdrender --repeat 5 --compare page.psp
```

```sh
# Simulate an HTMX request with a custom header
wdrender --htmx --headers_in "X-Debug: 1" fragment.psp
```

# NOTES #

`wdrender` aims to reproduce WebDyne output from the command line, but it cannot perfectly duplicate every web-server runtime detail. In particular, pages that depend on a specific server environment may behave differently across `fake`, `psgi`, `psgi_server`, `pagi`, and `mod_perl` backends.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE AND COPYRIGHT #

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
