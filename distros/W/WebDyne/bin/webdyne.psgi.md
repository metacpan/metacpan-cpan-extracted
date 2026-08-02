# webdyne.psgi #

# NAME #

webdyne.psgi - PSGI application runner for WebDyne

# SYNOPSIS

`webdyne.psgi [--option] <document_root>`

`webdyne.psgi --port 8080 /var/www/html` 

`webdyne.psgi --test`

# DESCRIPTION

`webdyne.psgi` builds a `WebDyne::PSGI` application, applies configured Plack middleware, loads local WebDyne constants for the selected root, and runs the app through `Plack::Runner`.

# OPTIONS

`webdyne.psgi` parses a small set of wrapper options itself and passes remaining command line options through to `Plack::Runner`.

Wrapper defaults can be preloaded from `~/.webdyne.psgi.opt` by creating an anonymous hash of option names and values.

Wrapper options handled by `webdyne.psgi` itself:

* **--test**

    Use WebDyne's internal test page as the root.

* **--static**

    Enable or disable PSGI static-file middleware.

* **--index**

    Enable or disable directory index handling. With the default enabled setting, `--index` uses WebDyne's built-in dynamic index page.

* **--index=FILE**

    Use `FILE` as the default document for directory requests instead of the built-in dynamic index page. Use the equals form so the document root argument is not consumed as the index value.

* **--root**

    Set the document root. If omitted, the final non-option command line argument is used. If neither is supplied, `DOCUMENT_ROOT` or the current working directory is used.

* **--env**

    Set the PSGI/Plack environment mode to `development`, `production`, or `none`. The wrapper sets `PLACK_ENV` and forwards the mode to `Plack::Runner`.

* **--argv**

    Supply additional arguments that the wrapper prepends to the remaining command line arguments before invoking `Plack::Runner`.

* **--dump_opt**

    Dump the processed option hash and exit.

Remaining command line options are handled by `Plack::Runner` and are the same as described in the [plackup(1)](man:plackup(1)) man page. Refer to that page for full options but some common options are:

* **--host**

    Which host interface to bind to

* **--port**

    Which port to bind to

* **--server**

    Which server to use, e.g. Starman

* **--reload**

    Reload if libraries or other files change

* **-I**

    Same as perl -I for library include paths

* **-M**

    Same as perl -M for loading modules before the script starts

On macOS, if no `--port` option is passed through to `Plack::Runner`, the wrapper uses port `5001` to avoid conflicts with Plack's default port. Other platforms use the normal Plack default unless a port is supplied.


# EXAMPLES

To run the script, use the following command for basic functionality and serving files from the /var/www/html directory. With default settings, index handling is enabled and the wrapper uses WebDyne's built-in dynamic index page.

`webdyne.psgi /var/www/html`

Disable wrapper-managed index handling and rely on the PSGI request layer's default document behaviour instead

`webdyne.psgi --no-index /var/www/html`

Use `home.psp` as the default document for directory requests

`webdyne.psgi --index=home.psp /var/www/html`

Start in production mode

`webdyne.psgi --env production /var/www/html`

Start with the Starman server

`webdyne.psgi --no-default-middleware --server Starman /home/aspeer/public_html`

Start with the internal test page

`webdyne.psgi --test`

# ENVIRONMENT VARIABLES

This script is a frontend to the WebDyne PSGI stack. In addition to `Plack::Runner` options, it uses WebDyne configuration and environment handling.

* **DOCUMENT_ROOT**

    Supplies the document root when neither `--root` nor a final non-option document root argument is provided.

* **DOCUMENT_DEFAULT**

    Supplies the default `index` value before `~/.webdyne.psgi.opt` and command-line options are applied. This means explicit CLI index options override the environment, and `~/.webdyne.psgi.opt` also overrides the environment. When the script is loaded by `plackup` or `starman` instead of run directly, the PSGI constant layer default is `app.psp`.

* **PLACK_ENV**

    Supplies the PSGI/Plack environment mode when `--env` is not provided.

* **WEBDYNE_***

    Supplies the relevant WebDyne settings used by the PSGI modules.

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
