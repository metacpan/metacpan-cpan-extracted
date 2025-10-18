
# NAME

WebDyne::Constant - WebDyne Configuration Constants

#  SYNOPSIS

```perl
#  Perl code
#
use WebDyne::Constant;
print $WEBDYNE_CACHE_DN;
```

# DESCRIPTION

This module provides a list of configuration constants used in the WebDyne code. These constants are used to configure the behavior of the WebDyne system 
and can be accessed by importing the module and referencing the constants by name.

Constants can be configured to different values by setting environment variables, command line options, or Apache directives

## CONSTANTS

The following user configurable constants are defined in the module. The default value of the configuration
constant is provided after the constant name.

- `WEBDYNE_CACHE_DN` (cache directory)
  - Directory where compiled scripts are stored.

- `WEBDYNE_STARTUP_CACHE_FLUSH` (1)
  - Flush cache files at startup.

- `WEBDYNE_CACHE_CHECK_FREQ` (256)
  - Frequency to check cache for excess entries.

- `WEBDYNE_CACHE_HIGH_WATER` (64)
  - High water mark for cache entries.

- `WEBDYNE_CACHE_LOW_WATER` (32)
  - Low water mark for cache entries.

- `WEBDYNE_CACHE_CLEAN_METHOD` (1)
  - Method to clean cache (0: last used time, 1: frequency of use).

- `WEBDYNE_EVAL_SAFE` (0)
  - Type of eval code to run (0: Direct, 1: Safe).

- `WEBDYNE_EVAL_USE_STRICT` ('use strict qw(vars);')
  - Prefix eval code with strict pragma.

- `WEBDYNE_EVAL_SAFE_OPCODE_AR` ([':default'])
  - Global opcode set for safe eval.

- `WEBDYNE_STRICT_VARS` (1)
  - Use strict variable checking.

- `WEBDYNE_STRICT_DEFINED_VARS` (0)
  - Check that variables are defined.

- `WEBDYNE_AUTOLOAD_POLLUTE` (0)
  - Pollute WebDyne class with method references for speedup.

- `WEBDYNE_DUMP_FLAG` (0)
  - Flag to display current CGI value and other information if <dump> tag is used.

- `WEBDYNE_CONTENT_TYPE_HTML` ('text/html')
  - Content-type for text/html.

- `WEBDYNE_CONTENT_TYPE_PLAIN` ('text/plain')
  - Content-type for text/plain.

- `WEBDYNE_HTML_CHARSET` ('UTF-8')
  - Character set for HTML.

- `WEBDYNE_DTD` ('<!DOCTYPE html>')
  - DTD to use when generating HTML.

- `WEBDYNE_META` ({charset => 'UTF-8'})
  - Meta information for HTML.

- `WEBDYNE_CONTENT_TYPE_HTML_META` (0)
  - Include a Content-Type meta tag.

- `WEBDYNE_HTML_PARAM` ({lang => 'en'})
  - Default <html> tag parameters.

- `WEBDYNE_COMPILE_IGNORE_WHITESPACE` (1)
  - Ignore ignorable whitespace in compile.

- `WEBDYNE_COMPILE_NO_SPACE_COMPACTING` (0)
  - Disable space compacting in compile.

- `WEBDYNE_COMPILE_P_STRICT` (1)
  - Use strict parsing in compile.

- `WEBDYNE_COMPILE_IMPLICIT_BODY_P_TAG` (1)
  - Implicitly add \<body\> and \<p\> tags in compile.

- `WEBDYNE_STORE_COMMENTS` (1)
  - Store and render comments.

- `WEBDYNE_NO_CACHE` (1)
  - Send no-cache headers.

- `WEBDYNE_WARNINGS_FATAL` (0)
  - Are warnings fatal?

- `WEBDYNE_CGI_DISABLE_UPLOADS` (1)
  - Disable CGI uploads by default.

- `WEBDYNE_CGI_POST_MAX` (524288)
  - Max post size for CGI (512KB).

- `WEBDYNE_CGI_PARAM_EXPAND` (1)
  - Expand CGI parameters found in CGI values.

- `WEBDYNE_CGI_AUTOESCAPE` (0)
  - Disable CGI autoescape of form fields.

- `WEBDYNE_ERROR_TEXT` (0)
  - Use text errors rather than HTML.

- `WEBDYNE_ERROR_SHOW` (1)
  - Show errors.

- `WEBDYNE_ERROR_SHOW_EXTENDED` (0)
  - Show extended error information.

- `WEBDYNE_ERROR_SOURCE_CONTEXT_SHOW` (1)
  - Show error source file context.

- `WEBDYNE_ERROR_SOURCE_CONTEXT_LINES_PRE` (4)
  - Number of lines to show before error context.

- `WEBDYNE_ERROR_SOURCE_CONTEXT_LINES_POST` (4)
  - Number of lines to show after error context.

- `WEBDYNE_ERROR_SOURCE_CONTEXT_LINE_FRAGMENT_MAX` (80)
  - Max length of source line to show in output.

- `WEBDYNE_ERROR_SOURCE_FILENAME_SHOW` (1)
  - Show filename in error output.

- `WEBDYNE_ERROR_BACKTRACE_SHOW` (1)
  - Show backtrace in error output.

- `WEBDYNE_ERROR_BACKTRACE_SHORT` (0)
  - Show brief backtrace.

- `WEBDYNE_ERROR_EVAL_CONTEXT_SHOW` (1)
  - Show eval trace in error output.

- `WEBDYNE_ERROR_CGI_PARAM_SHOW` (1)
  - Show CGI parameters in error output.

- `WEBDYNE_ERROR_ENV_SHOW` (1)
  - Show environment variables in error output.

- `WEBDYNE_ERROR_WEBDYNE_CONSTANT_SHOW` (1)
  - Show WebDyne constants in error output.

- `WEBDYNE_ERROR_URI_SHOW` (1)
  - Show URI in error output.

- `WEBDYNE_ERROR_VERSION_SHOW` (1)
  - Show version in error output.

- `WEBDYNE_ERROR_EVAL_TEXT_IX` (0)
  - Index for error eval text.

- `WEBDYNE_ERROR_SHOW_ALTERNATE` ('error display disabled - enable WEBDYNE_ERROR_SHOW to show errors, or review web server error log.')
  - Alternate error message if error display is disabled.

- `WEBDYNE_HTML_DEFAULT_TITLE` ('Untitled Document')
  - Default title for HTML documents.

- `WEBDYNE_HTML_TINY_MODE` ('html')
  - Mode for HTML Tiny (XML or HTML).

- `WEBDYNE_RELOAD` (0)
  - Development mode - recompile loaded modules.

- `WEBDYNE_JSON_CANONICAL` (1)
  - Use JSON canonical mode.

- `WEBDYNE_HTTP_HEADER` (HashRef)
  - Default HTTP headers.

- `MP2` (mod_perl version)
  - Mod_perl level. Auto-detected, do not change unless you know what you are doing.

- `MOD_PERL` (mod_perl version)
  - Mod_perl version. Auto-detected, do not change unless you know what you are doing.