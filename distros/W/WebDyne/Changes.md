# Revision history for WebDyne

## 3.009 - 2026-08-06

- Added `style_prepend`/`style_append` and
  `script_prepend`/`script_append` pseudo attributes for `<start_html>`,
  allowing pages to add resources around configured
  `WEBDYNE_START_HTML_PARAM` defaults without replacing them.
- Clarified `<start_html>` default-attribute override behaviour: page
  attributes replace matching `WEBDYNE_START_HTML_PARAM` values, while the
  new prepend/append variants preserve and extend configured style/script
  resources.
- Documented `<start_html>` resource ordering for linked styles versus
  `include_style` content, and external scripts versus `include_script`
  content.
- Made PSGI and PAGI wrapper configuration loading consistent by loading
  `DOCUMENT_ROOT/.webdyne.conf.pl` when the app is built, including when
  `webdyne.psgi` or `webdyne.pagi` is loaded by an external server.
- Clarified root `.webdyne.conf.pl` loading versus per-request directory
  `.webdyne.conf.pl` handling, where only `WEBDYNE_DIR_CONFIG` is read from
  PSP-directory config files.
- Added regression coverage for `<start_html>` style/script extension
  attributes and PSGI/PAGI external-loader root configuration loading.

## 3.008 - 2026-08-04

- Added REST-style `<api>` route discovery and `PATH_INFO` mapping to
  `WebDyne::PAGI`, bringing PAGI API support in line with PSGI.
- Added per-application API filename caches for PSGI and PAGI. API
  filename or route-structure changes may require a server restart.
- Ensured PAGI emits a valid empty HTTP response when an API document
  produces no body, avoiding PAGI lint errors.
- Clarified that Apache mod_perl does not provide automatic extensionless
  API route discovery without additional Apache rewrite or routing rules.
- Added integration coverage for PSGI and PAGI API routing, caching,
  normal PSP requests, and 404 handling.
- Fixed labelled `<textfield>` rendering so label-wrapped text inputs
  retain the correct HTML input type.
- Added `default`/`defaults` handling for grouped form controls and popup
  menus, aligning generated form state with the documented attributes.
- Added labelled textfield render fixtures and included them in the
  distribution manifest.
- Updated the XML and generated Markdown documentation for the latest API,
  form-control, and demo example behaviour.

## 3.005 - 2026-08-02

Major Version 3 release.

- Added PAGI runtime support through `WebDyne::PAGI` and the
  `webdyne.pagi` wrapper, including HTTP, server-sent event, WebSocket,
  and lifespan request handling.
- Added a common request abstraction for standalone, Apache/mod_perl,
  PSGI, and PAGI execution environments.
- Refactored PSGI support into `WebDyne::PSGI` and expanded runtime
  handling for document roots, default documents, directory indexes,
  static files, and API routes.
- Added `webdyne.apache` for temporary local Apache/mod_perl execution
  without requiring a permanent system Apache configuration.
- Expanded `wdapacheinit` to support broader Apache installations,
  APXS discovery, installation and uninstall workflows, dry-run
  operation, and platform-specific configuration layouts.
- Expanded `wdrender` to exercise multiple request backends, including
  fake, PSGI, PAGI, and mod_perl, with support for request methods,
  headers, parameters, response inspection, and comparison testing.
- Added test-file modes to command-line compilation and rendering
  utilities.
- Added a bundled default stylesheet for generated WebDyne pages and
  improved the appearance of default directory index output.
- Added Docker runtime selection between PSGI and PAGI, with
  environment-variable tuning for server workers, timeouts, backlog,
  connection limits, and request body sizes.
- Improved request and static-file safety, including path traversal,
  upload, multipart, error handling, and binary response coverage.
- Reworked the documentation into a DocBook/MkDocs build with generated
  utility and module reference pages.
- Added extensive examples and expanded automated test coverage for
  runtime backends, wrappers, static handling, APIs, SSE, WebSockets,
  and command-line utilities.
- Removed the old `WebDyne::CGI::PSGI` adapter in favour of the new
  request and runtime abstraction.

## 2.021 - 2025-11-07

- Added multi-line `<start_html>` attributes for scripts, styles, and
  related inclusions.
- Prevented WebDyne substitution inside executable JavaScript blocks.
- Added default viewport metadata and expanded head inclusion support,
  including array-valued includes.
- Added Alpine/Vue attribute compatibility handling.

## 2.018 - 2025-10-29

- Added the `<htmx>` tag for request-aware HTML fragment rendering.
- Made directory indexes and static files available by default through
  the PSGI wrapper.
- Improved HTML tree handling, constant importing, and error reporting.

## 2.017 - 2025-10-27

- Added the `<api>` tag for lightweight JSON API responses using
  `Router::Simple` path matching.

## 2.015 - 2025-10-22

- Added the `wdlint` utility for checking Perl syntax in `__PERL__`
  sections of PSP files.
- Added the default PSGI directory index page and `--index` support.

## 2.014 - 2025-10-18

- Replaced the CGI.pm-based HTML generation path with `CGI::Simple` and
  `WebDyne::HTML::Tiny`.
- Refactored compilation and evaluation handling around the new HTML
  generation backend.
- Added the JSON tag, alternate div-based WebDyne syntax,
  `application/perl` script blocks, and expanded HTML5 tag handling.
- Added PSGI/Plack support to the main WebDyne distribution, including
  command-line document-root and default-document selection.
- Added exported `WebDyne::html()` and `WebDyne::html_sr()` functions for
  standalone PSP rendering.
- Added `WebDyne::Template` to the core distribution and added PSGI
  static-file serving through `--static`.
- Added `WEBDYNE_HEAD_INSERT` for injecting common content into generated
  document heads.
- Added Docker build files and container-oriented development support,
  including automatic dependency installation from a mounted `cpanfile`.
