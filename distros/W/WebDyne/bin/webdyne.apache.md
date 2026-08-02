# webdyne.apache #

# NAME #

webdyne.apache - start a temporary Apache mod_perl instance for serving WebDyne pages

# SYNOPSIS

`webdyne.apache [--option] [document_root]`

`webdyne.apache --port 8080 /var/www/html`

`webdyne.apache --test`

`webdyne.apache /var/www/html/time.psp`

# DESCRIPTION

`webdyne.apache` starts a temporary Apache instance using `Apache::TestRunPerl` and configures it to handle `.psp` files with the WebDyne response handler. It is intended as a quick way to run WebDyne pages under Apache for local development, prototyping, and troubleshooting without doing a full Apache installation or system-wide configuration step first.

By default the script:

- uses `DOCUMENT_ROOT` as the document root if it is set, otherwise the current working directory
- enables WebDyne index handling, using `DOCUMENT_DEFAULT` if it is set
- listens on port `5001` on macOS, or `5000` on other platforms
- creates a temporary Apache server root
- creates a temporary WebDyne cache directory under that server root
- starts Apache in one-process mode and then waits until interrupted

If the supplied root is a file rather than a directory, the parent directory becomes Apache `DocumentRoot` and the selected file is passed through to WebDyne as `DOCUMENT_ROOT` so that a single-page application can be served.

This utility is primarily designed for quick prototyping and development under Apache. For a fuller Apache installation intended for ongoing or production-style deployment, use `bin/wdapacheinit` instead.

# OPTIONS

* **--index**

    Enable index handling. This is on by default. If enabled with the default value, WebDyne uses its internal default index page.

* **--index=FILE**

    Use `FILE` as the Apache directory index/default document. Relative names are emitted as `DirectoryIndex FILE`. Absolute names are exposed through the same alias/rewrite mechanism used for the internal WebDyne index page.

* **--no-index**

    Disable wrapper-managed index handling. No `DOCUMENT_DEFAULT`, `DirectoryIndex`, index alias, or index rewrite rules are emitted.

* **--root**

    Specify the document root directory or a single `.psp` file to serve.

* **--port**

    Specify the Apache listen port. The default is `5001` on macOS, or `5000` on other platforms.

* **--keep_tmp**

    Keep or remove the temporary Apache server root on exit. By default it is cleaned up automatically.

* **--test**

    Use the internal WebDyne test page as the root page.

* **--dump_postamble**

    Print the generated Apache configuration postamble and exit instead of starting the server.

* **--dump_opt**

    Dump the processed option hash and exit.

* **--argv**

    Accepted by the script option parser, but not otherwise used by the current code.

* **--help**

    Display a brief help message and exit.

# BEHAVIOUR

The generated Apache configuration currently does the following:

- loads the `WebDyne` Perl module
- installs `mod_perl` handling for `.psp` files with `PerlResponseHandler WebDyne`
- passes through any current `WEBDYNE_*` environment variables as `PerlSetEnv`
- passes through non-default Perl include paths as `PerlSwitches -I...`
- sets `WEBDYNE_ERROR_TEXT=1` unless already defined
- grants access to the selected document root
- when built-in index handling is enabled, sets `DOCUMENT_DEFAULT` to WebDyne's internal index page, grants access to that file's directory, aliases `/index.psp` to it, and rewrites directory requests to `/index.psp`
- when `DOCUMENT_DEFAULT` or `--index=FILE` supplies a relative filename, emits `PerlSetEnv DOCUMENT_DEFAULT FILE` and `DirectoryIndex FILE`
- when `DOCUMENT_DEFAULT` or `--index=FILE` supplies an absolute filename, aliases `/index.psp` to that file and rewrites directory requests to `/index.psp`
- when `--no-index` is used, omits all wrapper-managed index configuration
- on macOS, loads `mod_rewrite` explicitly when Apache does not already have it loaded
- logs to `/dev/stderr` and `/dev/stdout` where possible, otherwise falls back to Apache log files

The script also reads defaults from `~/.webdyne.apache.opt` if that file exists. `index` is the canonical runtime option; a seeded `no_index` value is normalized into `index => 0`, and command-line options take final precedence.

# ENVIRONMENT VARIABLES

`webdyne.apache` uses a small number of environment variables directly and passes WebDyne environment settings through to the generated Apache configuration.

* **DOCUMENT_ROOT**

    Supplies the document root when neither `--root` nor a final non-option document root argument is provided.

* **DOCUMENT_DEFAULT**

    Supplies the default `index` value before `~/.webdyne.apache.opt` and command-line options are applied. This means explicit CLI index options override the environment, and `~/.webdyne.apache.opt` also overrides the environment.

* **WEBDYNE_***

    Any current non-empty `WEBDYNE_*` environment variables are emitted into the generated Apache configuration as `PerlSetEnv` directives.

* **WEBDYNE_ERROR_TEXT**

    If not already defined, the wrapper emits `WEBDYNE_ERROR_TEXT=1` so errors from the temporary development server are returned as plain text.

* **APXS**

    On macOS, used to locate Apache's module directory when the wrapper needs to load `mod_rewrite` explicitly.

* **APACHE_TEST_APXS**

    On macOS, used as the fallback Apache extension tool path when `APXS` is not set.

# EXAMPLES

Start Apache in the current directory on the default port:

```sh
webdyne.apache
```

Serve files from a specific directory:

```sh
webdyne.apache /var/www/html
```

Serve a single WebDyne page:

```sh
webdyne.apache /var/www/html/time.psp
```

Run on another port and keep the temporary Apache tree for inspection:

```sh
webdyne.apache --port 8080 --keep_tmp /var/www/html
```

Show the generated Apache configuration instead of starting the server:

```sh
webdyne.apache --dump_postamble /var/www/html
```

Disable wrapper-managed index handling:

```sh
webdyne.apache --no-index /var/www/html
```

Use a site-local default document:

```sh
webdyne.apache --index=home.psp /var/www/html
```

Start using the internal test page:

```sh
webdyne.apache --test
```

# NOTES

This script is a development helper, not a full Apache installation tool. It starts Apache using `Apache::Test` infrastructure in one-process mode, which is convenient for local testing but is not a substitute for a proper Apache deployment.

For production or more complete Apache setup, prefer `bin/wdapacheinit`, which is intended for installing Apache configuration more formally.

If you want to use `webdyne.apache`, additional system and CPAN tooling may need to be installed first. These components are not nominated by default in the WebDyne module:

- system packages for Apache HTTP Server
- `mod_perl`
- `mod_perl-dev` or the equivalent development package on your platform
- Perl CPAN modules `Apache::Test`
- Perl CPAN modules `Module::CoreList`

The script also checks for `Apache2::Build` at startup. If `Module::CoreList` is broken or outdated relative to the installed `Apache2::Build`, startup can fail with a message requesting rebuild or upgrade of `Module::CoreList`.

The Apache configuration generated by this script is assembled dynamically. Use `--dump_postamble` if you need to inspect the exact config fragment before startup.

The process stays in the foreground and exits on `INT` or `TERM`, at which point it attempts to stop the temporary Apache server cleanly.

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
