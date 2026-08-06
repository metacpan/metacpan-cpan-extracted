# webdyne.pagi #

# NAME #

webdyne.pagi - PAGI application runner for WebDyne

# SYNOPSIS

`webdyne.pagi [--option] <document_root>`

`webdyne.pagi --port 8080 /var/www/html`

`webdyne.pagi --test`

# DESCRIPTION

`webdyne.pagi` is a PAGI application script that handles web requests using the WebDyne framework. It builds a `WebDyne::PAGI` application, loads any configured PAGI middleware, and starts it through `PAGI::Server::Runner`.

The underlying `WebDyne::PAGI` application can dispatch PAGI scope types for normal HTTP requests, server-sent events, WebSocket connections, and lifespan startup or shutdown events.

# OPTIONS

`webdyne.pagi` parses a small set of wrapper options itself and passes remaining command line options through to `PAGI::Server::Runner`.

Wrapper defaults can be preloaded from `~/.webdyne.pagi.opt` by creating an anonymous hash of option names and values.

Wrapper options handled by `webdyne.pagi` itself:

* **--test**

    Use WebDyne's internal test page as the root.

* **--static**

    Enable or disable PAGI static-file middleware.

* **--index**

    Enable or disable directory index handling. With the default enabled setting, `--index` uses WebDyne's built-in dynamic index page.

* **--index=FILE**

    Use `FILE` as the default document for directory requests instead of the built-in dynamic index page. Use the equals form so the document root argument is not consumed as the index value.

* **--root**

    Set the document root. If omitted, the final non-option command line argument is used. If neither is supplied, `DOCUMENT_ROOT` or the current working directory is used.

* **--env**

    Set the PAGI environment mode to `development`, `production`, or `none`. The wrapper sets `PAGI_ENV` and forwards the mode to `PAGI::Server::Runner`.

* **--argv**

    Supply additional arguments that the wrapper prepends to the remaining command line arguments before invoking `PAGI::Server::Runner`.

* **--dump_opt**

    Dump the processed option hash and exit.

Remaining command line options are handled by `PAGI::Server::Runner`. Some common options are:

* **--host**

    Which host interface to bind to. When launched through `webdyne.pagi`, the wrapper adds `--host 0.0.0.0` unless a `--host` option is present.

* **--port**

    Which port to bind to.

* **--server**

    Which PAGI server class to use. The runner default is `PAGI::Server`.

* **--loop**

    Event loop backend.

* **--lib**

    Add a library path to `@INC`.

* **-M**

    Load a module before the app starts.

* **--default-middleware**

    Enable or disable runner default middleware.

* **--daemonize**

    Run as a background daemon.

* **--access-log**

    Configure access logging.

Additional runner process and output controls are passed through to
`PAGI::Server::Runner`; see that runner's documentation for details.

On macOS, if no `--port` option is passed through to `PAGI::Server::Runner`, the wrapper uses port `5001` to avoid conflicts with the default port. Other platforms use the normal runner default unless a port is supplied.

# EXAMPLES

To run the script for basic functionality and serve files from `/var/www/html`, use:

`webdyne.pagi /var/www/html`

Disable wrapper-managed index handling and rely on the PAGI request layer's default document behaviour instead:

`webdyne.pagi --no-index /var/www/html`

Use `home.psp` as the default document for directory requests:

`webdyne.pagi --index=home.psp /var/www/html`

Start in production mode:

`webdyne.pagi --env production /var/www/html`

Start on another port:

`webdyne.pagi --port 8080 /var/www/html`

Start with a specific host:

`webdyne.pagi --host 127.0.0.1 --port 8080 /var/www/html`

Start with the internal test page:

`webdyne.pagi --test`

Start with a different event loop backend:

`webdyne.pagi --loop EV /home/aspeer/public_html`

# ENVIRONMENT VARIABLES

This script is a frontend to the WebDyne PAGI stack. It uses WebDyne configuration and environment handling.

* **DOCUMENT_ROOT**

    Supplies the document root when neither `--root` nor a final non-option document root argument is provided.

* **DOCUMENT_DEFAULT**

    Supplies the default `index` value before `~/.webdyne.pagi.opt` and command-line options are applied. This means explicit CLI index options override the environment, and `~/.webdyne.pagi.opt` also overrides the environment. When the script is loaded by `pagi-server` instead of run directly, the PAGI constant layer default is `app.psp`.

* **PAGI_ENV**

    Supplies the PAGI environment mode when `--env` is not provided.

* **WEBDYNE_***

    Supplies the relevant WebDyne settings used by the PAGI modules.

When the PAGI app is built, the wrapper also reads local WebDyne configuration from `DOCUMENT_ROOT/.webdyne.conf.pl`. This applies both when `webdyne.pagi` is launched directly and when it is loaded by an external PAGI server.

Relevant PAGI-specific settings from `WebDyne::PAGI::Constant` include:

* **WEBDYNE_PAGI_STATIC**

    Enable or disable static-file serving middleware.

* **WEBDYNE_PAGI_MIDDLEWARE_STATIC**

    Regular expression used to decide which static files are served directly.

* **WEBDYNE_PAGI_MIDDLEWARE**

    Middleware stack applied around the WebDyne PAGI app.

* **WEBDYNE_PAGI_ENV_KEEP / WEBDYNE_PAGI_ENV_SET**

    Environment variables preserved or injected for request handling.

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
