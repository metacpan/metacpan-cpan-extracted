# WebDyne::Constant #

# NAME #

WebDyne::Constant - WebDyne module that sets constants and defaults for WebDyne processing

# SYNOPSIS #

```
#!/usr/bin/env perl
#
use WebDyne::Constant;
print $WEBDYNE_DTD
```

    # Dump all constant settings for review
    #
    $ perl -MWebDyne::Constant=dump

# Description #

This module provides a list of configuration constants used in the WebDyne code. These constants are used to configure the behavior of the WebDyne module and can be accessed by importing the module and referencing the constants by name. Constants can be configured to different values by overriding values in local configuration files, setting environment
 variables, command line options, or Apache directives.

Common uses for modifying constant values allow for:

* Changing default language from en-US to something else.

* Modifying or adding new meta-data or default headers to output

* Adding default style-sheets or other inclusions to all output files

Default values for these configuration constants can be updated the following locations:

1. /etc/webdyne.conf.pl

2. $HOME/.webdyne.conf.pl

3. $DOCUMENT_ROOT/.webdyne.conf.pl

As a special case when running under PSGI environments, if WEBDYNE_DIR_CONFIG_CWD_LOAD is true \(which it is by default) then each directory that a \.psp file is run from is checked for the \.webdyne.conf.pl file \- but only WEBDYNE_DIR_CONFIG entries from the file are loaded. This allows for configuration of settings such a WebDyneChain modules to load, WebDyneTemplate
 configuration etc. on a per directory basis

The WebDyne::Constant module is sub-classed by other WebDyne modules, and the values for any constants in the WebDyne::&lt;Module&gt;::Constant family of modules can be overridden by creating or updating one of the above configuration files. Here is a sample configuration file:

```
$_={

    #  Update config constants for WebDyne::Constant module
    #
    'WebDyne::Constant' => {

        #  Where the cache directory will live
        #
        WEBDYNE_CACHE_DN            => '/tmp',
 
        #  The attributes below will be added to any <start_html> tag, effectively
        #  adding two stylesheets to every page
        #
        WEBDYNE_START_HTML_PARAM    => {
          style => [qw(
            https://cdn.jsssdelivr.net/npm/@picocss/pico@2/css/pico.classless.m
            /style.css
          )]
        },

        #  Enable extended error display
        #
        WEBDYNE_ERROR_SHOW_EXTENDED => 1,

        #  Update CGI upload capacity to 2GB
        #
        WEBDYNE_CGI_POST_MAX        => (2048*1024),

        #  Handle examples directory differently
        #
        WEBDYNE_DIR_CONFIG => {
            '/examples' => {
                'WebDyneHandler'    => 'WebDyne::Chain',
                'WebDyneChain'      => 'WebDyne::Session',
            },
        },

  },

  #  And for WebDyne::Session module
  #
  'WebDyne::Session::Constant' => {
      WEBDYNE_SESSION_ID_COOKIE_NAME => 'mysession'  
  },
};
```

> **WARNING**
> 
> Ensure the configuration file has the correct syntax by checking the Perl interpreter doesn&#39;t throw any errors. Use  `perl -c -w`  to check syntax:
> 
>     # perl -c -w /etc/webdyne.conf.pl
>     /etc/webdyne.conf.pl syntax OK
>     # perl -c -w ~/.webdyne.conf.pl
>     /home/<user>/.webdyne.conf.pl OK
> 
>

# CONSTANTS #

The constants below are defined by `WebDyne::Constant`. Each definition includes a short default description. Unless marked read-only or internal, constants can be overridden through normal WebDyne configuration loading, environment variables, command line options, or Apache directives.

* **WEBDYNE_NODE_NAME_IX**

    **Default:** `0`

    Internal read-only index for the node name slot in WebDyne's compiled node array structure. Do not change.

* **WEBDYNE_NODE_ATTR_IX**

    **Default:** `1`

    Internal read-only index for the node attribute slot in WebDyne's compiled node array structure. Do not change.

* **WEBDYNE_NODE_CHLD_IX**

    **Default:** `2`

    Internal read-only index for the child-node slot in WebDyne's compiled node array structure. Do not change.

* **WEBDYNE_NODE_SBST_IX**

    **Default:** `3`

    Internal read-only index for the substitution slot in WebDyne's compiled node array structure. Do not change.

* **WEBDYNE_NODE_LINE_IX**

    **Default:** `4`

    Internal read-only index for the source line slot in WebDyne's compiled node array structure. Do not change.

* **WEBDYNE_NODE_LINE_TAG_END_IX**

    **Default:** `5`

    Internal read-only index for the source tag-end line slot in WebDyne's compiled node array structure. Do not change.

* **WEBDYNE_NODE_SRCE_IX**

    **Default:** `6`

    Internal read-only index for the source text slot in WebDyne's compiled node array structure. Do not change.

* **WEBDYNE_CONTAINER_META_IX**

    **Default:** `0`

    Internal read-only index for the metadata slot in WebDyne's compiled page container structure. Do not change.

* **WEBDYNE_CONTAINER_DATA_IX**

    **Default:** `1`

    Internal read-only index for the data slot in WebDyne's compiled page container structure. Do not change.

* **WEBDYNE_CACHE_DN**

    **Default:** See the command below for the value.

    ```sh
    perl -MWebDyne::Constant=WEBDYNE_CACHE_DN
    ```

    Directory used to store compiled page cache files. Installer and server wrappers normally set this to a writable cache directory. The directory must exist and be writable by the web server process. If unset, WebDyne may fall back to runtime-specific temporary locations.

* **WEBDYNE_STARTUP_CACHE_FLUSH**

    **Default:** `1`

    Remove existing disk cache files at startup so PSP files are recompiled after restart and then cached again when first viewed. Set to 0 to keep disk cache files across restarts.

* **WEBDYNE_CACHE_CHECK_FREQ**

    **Default:** `256`

    Per-process request interval used to trigger memory cache housekeeping.

* **WEBDYNE_CACHE_HIGH_WATER**

    **Default:** `64`

    Maximum number of compiled pages to keep in memory before cache housekeeping removes entries.

* **WEBDYNE_CACHE_LOW_WATER**

    **Default:** `32`

    Target number of compiled pages to retain after memory cache housekeeping runs.

* **WEBDYNE_CACHE_CLEAN_METHOD**

    **Default:** `1`

    Memory cache cleanup method. `0` removes entries by oldest last-use time; `1` removes least-used entries first.

* **WEBDYNE_EVAL_SAFE**

    **Default:** `0`

    Run dynamic PSP code in a `Safe` compartment instead of direct Perl eval. Safe mode is experimental and not recommended as a security boundary.

* **WEBDYNE_EVAL_USE_STRICT**

    **Default:** `'use strict qw(vars)'`

    Perl source prepended before generated eval code to enable strict variable checking. Set to `undef` to disable this strict pragma. In Safe mode this behaves as a strict on/off flag rather than arbitrary source text.

* **WEBDYNE_EVAL_PREPEND**

    **Default:** `''`

    Perl source text prepended to generated eval code after `WEBDYNE_EVAL_USE_STRICT`. Use conservatively because it affects interpreted PSP code globally.

* **WEBDYNE_EVAL_SAFE_OPCODE_AR**

    **Default:** array reference containing `:default`

    Opcode set allowed when `WEBDYNE_EVAL_SAFE` is enabled. Ignored when direct eval mode is used. Use `Opcode::full_opset()` for the full opcode set if Safe mode is enabled and you explicitly want to allow all Perl opcodes.

* **WEBDYNE_STRICT_VARS**

    **Default:** `1`

    Check render variables referenced as `${name}` and raise an error when a referenced variable was not supplied to `render()` or `render_block()`, or was supplied as `undef`.

* **WEBDYNE_AUTOLOAD_POLLUTE**

    **Default:** `0`

    Cache dynamically found method references in the `WebDyne` namespace to avoid repeated `AUTOLOAD` lookup. This can improve some workloads but risks method-name clashes, so it should only be used in controlled environments.

* **WEBDYNE_DUMP_FLAG**

    **Default:** `0`

    Enable output from the special `<dump>` tag, mainly for form and request debugging.

* **WEBDYNE_HTML_CHARSET**

    **Default:** `'UTF-8'`

    Default character set used for generated content types and default HTML metadata.

* **WEBDYNE_CONTENT_TYPE_HTML**

    **Default:** `'text/html'`

    Base content type for HTML responses.

* **WEBDYNE_CONTENT_TYPE_HTML_ENCODED**

    **Default:** `'text/html; charset=UTF-8'`

    Encoded HTML content type including the configured character set.

* **WEBDYNE_CONTENT_TYPE_TEXT**

    **Default:** `'text/plain'`

    Base content type for plain text responses.

* **WEBDYNE_CONTENT_TYPE_TEXT_ENCODED**

    **Default:** `'text/plain; charset=UTF-8'`

    Encoded plain text content type including the configured character set.

* **WEBDYNE_CONTENT_TYPE_JSON**

    **Default:** `'application/json'`

    Base content type for JSON responses.

* **WEBDYNE_CONTENT_TYPE_JSON_ENCODED**

    **Default:** `'application/json; charset=UTF-8'`

    Encoded JSON content type including the configured character set.

* **WEBDYNE_SCRIPT_TYPE_EXECUTABLE_HR**

    **Default:** See the command below for the value.

    ```sh
    perl -MWebDyne::Constant=WEBDYNE_SCRIPT_TYPE_EXECUTABLE_HR
    ```

    Hash reference of script MIME types where WebDyne variable substitution is suppressed by default so JavaScript syntax such as `${name}` is not interpreted as WebDyne substitution.

* **WEBDYNE_DTD**

    **Default:** `'<!DOCTYPE html>'`

    Document type emitted by generated HTML helpers.

* **WEBDYNE_META**

    **Default:** See the command below for the value.

    ```sh
    perl -MWebDyne::Constant=WEBDYNE_META
    ```

    Default metadata emitted by `<start_html>`. Defaults include a UTF-8 charset declaration and a responsive viewport declaration.

* **WEBDYNE_CONTENT_TYPE_HTML_META**

    **Default:** `0`

    Include a Content-Type `<meta>` tag in generated HTML output.

* **WEBDYNE_HTML_PARAM**

    **Default:** hash reference containing `lang => 'en'`

    Default attributes applied to the generated `<html>` tag; the default contains `lang => 'en'`.

* **WEBDYNE_START_HTML_PARAM**

    **Default:** empty hash reference

    Hash reference of default attributes applied to every `<start_html>` tag, such as global scripts, styles, metadata, or include files. Explicit `<start_html>` attributes can override these defaults.

* **WEBDYNE_START_HTML_PARAM_STATIC**

    **Default:** `1`

    Controls whether include-style values supplied through `<start_html>` defaults are loaded at compile time and reused. Set to 0 or `undef` when included content should be re-read on each page load.

* **WEBDYNE_START_HTML_SHORTCUT_HR**

    **Default:** See the command below for the value.

    ```sh
    perl -MWebDyne::Constant=WEBDYNE_START_HTML_SHORTCUT_HR
    ```

    Shortcut attribute mappings for `<start_html>`. Defaults include `pico`, `htmx`, and `alpine`, which expand to stylesheet or script includes.

* **WEBDYNE_HEAD_INSERT**

    **Default:** See the command below for the value.

    ```sh
    perl -MWebDyne::Constant=WEBDYNE_HEAD_INSERT
    ```

    HTML inserted verbatim before `</head>` in generated pages. The value must be valid HTML for the document head and is not interpreted, interpolated, or compiled by WebDyne. By default WebDyne inlines its bundled `webdyne.css` stylesheet. Set to `undef` to disable default stylesheet insertion.

* **WEBDYNE_COMPILE_IGNORE_WHITESPACE**

    **Default:** `1`

    Ignore ignorable source whitespace during HTML tree compilation, corresponding to the HTML::TreeBuilder `ignore_ignorable_whitespace` behaviour.

* **WEBDYNE_COMPILE_NO_SPACE_COMPACTING**

    **Default:** `0`

    Disable HTML::TreeBuilder-style source whitespace compacting during compilation, corresponding to the HTML::TreeBuilder `no_space_compacting` behaviour.

* **WEBDYNE_COMPILE_P_STRICT**

    **Default:** `1`

    Controls parser strictness for paragraph handling during compilation.

* **WEBDYNE_COMPILE_IMPLICIT_BODY_P_TAG**

    **Default:** `1`

    Controls whether implicit body and paragraph tags are generated during compilation.

* **WEBDYNE_STORE_COMMENTS**

    **Default:** `1`

    Store and render comments from source files. Set to 0 to suppress comment output.

* **WEBDYNE_NO_CACHE**

    **Default:** `1`

    Send no-cache response headers by default. This can be changed globally or cleared for a page through the `no_cache()` method.

* **WEBDYNE_WARNINGS_FATAL**

    **Default:** `0`

    Treat Perl warnings from interpreted code as fatal WebDyne errors. When enabled, a `warn()` behaves as if `die()` had been called.

* **WEBDYNE_CGI_DISABLE_UPLOADS**

    **Default:** `0`

    Disable CGI file uploads. Uploads are allowed by default.

* **WEBDYNE_CGI_POST_MAX**

    **Default:** `524288`

    Maximum accepted POST body size for CGI processing, in bytes. The default is 512 KiB.

* **WEBDYNE_CGI_PARAM_EXPAND**

    **Default:** `1`

    Expand CGI parameter strings embedded in parameter values into separate CGI parameters.

* **WEBDYNE_CGI_AUTOESCAPE**

    **Default:** `0`

    Controls automatic escaping of CGI form field values before they are rendered back into generated form elements.

* **WEBDYNE_ERROR_TEXT**

    **Default:** `0`

    Display simplified plain-text errors instead of the HTML error handler. This is mainly useful for WebDyne development and command-line/server wrapper diagnostics.

* **WEBDYNE_ERROR_SHOW**

    **Default:** `1`

    Display the primary error message in the HTML error handler.

* **WEBDYNE_ERROR_SHOW_EXTENDED**

    **Default:** `0`

    Enable extended HTML error output. The granular error constants below determine which source, backtrace, environment, CGI, and internal details are shown.

* **WEBDYNE_ERROR_SOURCE_CONTEXT_SHOW**

    **Default:** `1`

    Show a fragment of the PSP source file around the error location when extended HTML error output is enabled.

* **WEBDYNE_ERROR_SOURCE_CONTEXT_LINES_PRE**

    **Default:** `4`

    Number of source lines before the error location to show.

* **WEBDYNE_ERROR_SOURCE_CONTEXT_LINES_POST**

    **Default:** `4`

    Number of source lines after the error location to show.

* **WEBDYNE_ERROR_SOURCE_CONTEXT_LINE_FRAGMENT_MAX**

    **Default:** `80`

    Maximum source line length to show in error output. Set to 0 for unlimited length.

* **WEBDYNE_ERROR_SOURCE_FILENAME_SHOW**

    **Default:** `1`

    Show the source filename in extended HTML error output.

* **WEBDYNE_ERROR_SOURCE_FILENAME_FULL**

    **Default:** `0`

    Show the full filesystem path for the source filename in extended HTML error output.

* **WEBDYNE_ERROR_BACKTRACE_SHOW**

    **Default:** `1`

    Show a backtrace of modules through which the error propagated in extended HTML error output.

* **WEBDYNE_ERROR_BACKTRACE_SHORT**

    **Default:** `0`

    Remove WebDyne internal modules from the displayed backtrace.

* **WEBDYNE_ERROR_BACKTRACE_FULL**

    **Default:** `0`

    Show the full backtrace, including frames normally skipped such as eval and anonymous subroutine frames.

* **WEBDYNE_ERROR_EVAL_CONTEXT_SHOW**

    **Default:** `1`

    Show generated eval context around an error when extended HTML error output is enabled.

* **WEBDYNE_ERROR_CGI_PARAM_SHOW**

    **Default:** `1`

    Show CGI parameters in extended HTML error output.

* **WEBDYNE_ERROR_ENV_SHOW**

    **Default:** `1`

    Show environment variables in extended HTML error output.

* **WEBDYNE_ERROR_WEBDYNE_CONSTANT_SHOW**

    **Default:** `1`

    Show WebDyne constants in extended HTML error output.

* **WEBDYNE_ERROR_URI_SHOW**

    **Default:** `1`

    Show request URI information in extended HTML error output.

* **WEBDYNE_ERROR_VERSION_SHOW**

    **Default:** `1`

    Show WebDyne version information in extended HTML error output.

* **WEBDYNE_ERROR_INTERNAL_SHOW**

    **Default:** `0`

    Show internal error-handler state in extended HTML error output.

* **WEBDYNE_ERROR_SHOW_ALTERNATE**

    **Default:** `'error display disabled - enable WEBDYNE_ERROR_SHOW to show errors, or review web server error log.'`

    Alternate message displayed when HTML error display is disabled with `WEBDYNE_ERROR_SHOW`.

* **WEBDYNE_HTML_DEFAULT_TITLE**

    **Default:** `'Untitled Document'`

    Default document title emitted by `<start_html>` when no title is supplied.

* **WEBDYNE_HTML_TINY_MODE**

    **Default:** `'html'`

    Controls whether the HTML helper emits HTML-style or XML-style output.

* **WEBDYNE_RELOAD**

    **Default:** `0`

    Development-mode switch that forces cached compiled pages to be recompiled.

* **WEBDYNE_JSON_CANONICAL**

    **Default:** `1`

    Enable canonical JSON output by default, preserving stable key ordering where the encoder supports it. Canonical output can be slightly slower.

* **WEBDYNE_JSON_PRETTY**

    **Default:** `0`

    Enable pretty-printed JSON output for `<json>` tags unless overridden by a tag attribute.

* **WEBDYNE_API_ENABLE**

    **Default:** `1`

    Enable processing of `<api>` routes in PSGI request handling. Set to 0 to disable API route dispatch.

* **WEBDYNE_ALPINE_VUE_ATTRIBUTE_HACK_ENABLE**

    **Default:** `'x-on'`

    Rewrite shorthand attributes beginning with `@`, such as `@click`, into parser-safe attributes because the HTML parser does not recognise `@` as a valid attribute character. The default rewrites them to Alpine-style `x-on:` attributes; set a different prefix such as `v-on:` for Vue-style output.

* **WEBDYNE_HTTP_HEADER_AJAX_HR**

    **Default:** See the command below for the value.

    ```sh
    perl -MWebDyne::Constant=WEBDYNE_HTTP_HEADER_AJAX_HR
    ```

    Hash reference of HTTP request header names used to detect htmx or Alpine Ajax style partial requests. Matching requests can receive partial HTML output, such as the page body only or a matching `<htmx>` fragment.

* **WEBDYNE_HTTP_HEADER_AJAX_AR**

    **Default:** See the command below for the value.

    ```sh
    perl -MWebDyne::Constant=WEBDYNE_HTTP_HEADER_AJAX_AR
    ```

    Array reference form of the AJAX request header names derived from `WEBDYNE_HTTP_HEADER_AJAX_HR`.

* **WEBDYNE_HTMX_FORCE**

    **Default:** `0`

    Force htmx-oriented partial rendering behaviour even when the request does not contain an AJAX request header. This is equivalent to setting `force=1` on all `<htmx>` tags.

* **WEBDYNE_HTTP_HEADER**

    **Default:** See the command below for the value.

    ```sh
    perl -MWebDyne::Constant=WEBDYNE_HTTP_HEADER
    ```

    Hash reference of default HTTP response headers sent with WebDyne responses. Defaults include Content-Type, Cache-Control, Pragma, Expires, X-Content-Type-Options, and X-Frame-Options.

* **WEBDYNE_PSP_EXT**

    **Default:** `'.psp'`

    Default extension used to identify interpreted WebDyne PSP files.

* **WEBDYNE_PSP_EXT_RE**

    **Default:** See the command below for the value.

    ```sh
    perl -MWebDyne::Constant=WEBDYNE_PSP_EXT_RE
    ```

    Regular expression form of `WEBDYNE_PSP_EXT`, used internally for matching PSP filenames.

* **WEBDYNE_MIME_TYPE_HR**

    **Default:** See the command below for the value.

    ```sh
    perl -MWebDyne::Constant=WEBDYNE_MIME_TYPE_HR
    ```

    Hash reference of file extensions and MIME types used when WebDyne identifies static file content types.

* **WEBDYNE_INDEX_EXT_ALLOWED_HR**

    **Default:** See the command below for the value.

    ```sh
    perl -MWebDyne::Constant=WEBDYNE_INDEX_EXT_ALLOWED_HR
    ```

    Hash reference of source-code file extensions that the default directory indexer may open for viewing, in addition to recognised static file types.

* **WEBDYNE_INDEX_FN_ALLOWED_HR**

    **Default:** See the command below for the value.

    ```sh
    perl -MWebDyne::Constant=WEBDYNE_INDEX_FN_ALLOWED_HR
    ```

    Hash reference of literal file names that the default directory indexer may open for viewing, in addition to recognised static file types.

* **WEBDYNE_DIR_CONFIG**

    **Default:** `undef`

    Hash reference used by non-Apache request layers to provide Apache-style directory configuration values such as `WebDyneHandler`, `WebDyneChain`, and `WebDyneTemplate`.

* **WEBDYNE_DIR_CONFIG_CWD_LOAD**

    **Default:** `1`

    Controls whether PSGI-style local request handling attempts to load `WEBDYNE_DIR_CONFIG` values from a `.webdyne.conf.pl` file in the current PSP directory.

* **WEBDYNE_CONF_HR**

    **Default:** `undef`

    Read-only marker populated by local configuration loading with information about configuration files that contributed constant values.

* **WEBDYNE_CONF_FN**

    **Default:** `'webdyne.conf.pl'`

    Default configuration filename searched by local configuration loading.

* **WEBDYNE_HTML_TIDY**

    **Default:** `0`

    Enable optional HTML::Tidy5 cleanup of rendered output where supported by the rendering path. Requires HTML::Tidy5 and its dependencies to be installed.

* **WEBDYNE_HTML_TIDY_CONFIG_HR**

    **Default:** See the command below for the value.

    ```sh
    perl -MWebDyne::Constant=WEBDYNE_HTML_TIDY_CONFIG_HR
    ```

    Hash reference of HTML::Tidy5 options used when `WEBDYNE_HTML_TIDY` is enabled.

* **WEBDYNE_HTML_NEWLINE**

    **Default:** `0`

    Add extra newline characters to generated HTML output.

* **WEBDYNE_PAGI**

    **Default:** See the command below for the value.

    ```sh
    perl -MWebDyne::Constant=WEBDYNE_PAGI
    ```

    Read-only flag indicating whether the PAGI support module is loaded.

* **WEBDYNE_PSGI**

    **Default:** See the command below for the value.

    ```sh
    perl -MWebDyne::Constant=WEBDYNE_PSGI
    ```

    Read-only flag indicating whether the PSGI support module is loaded.

* **WEBDYNE_DEFAULT_TEST_FN**

    **Default:** See the command below for the value.

    ```sh
    perl -MWebDyne::Constant=WEBDYNE_DEFAULT_TEST_FN
    ```

    Absolute path to the built-in WebDyne test page.

* **WEBDYNE_DEFAULT_INDEX_FN**

    **Default:** See the command below for the value.

    ```sh
    perl -MWebDyne::Constant=WEBDYNE_DEFAULT_INDEX_FN
    ```

    Absolute path to the built-in WebDyne directory index page.

* **WEBDYNE_DEFAULT_STYLE_FN**

    **Default:** See the command below for the value.

    ```sh
    perl -MWebDyne::Constant=WEBDYNE_DEFAULT_STYLE_FN
    ```

    Absolute path to the bundled default `webdyne.css` stylesheet.

* **MP2**

    **Default:** See the command below for the value.

    ```sh
    perl -MWebDyne::Constant=MP2
    ```

    Read-only mod_perl major-version flag.

* **MOD_PERL**

    **Default:** See the command below for the value.

    ```sh
    perl -MWebDyne::Constant=MOD_PERL
    ```

    Read-only mod_perl runtime version value.
