#
#  This file is part of WebDyne.
#
#  This software is copyright (c) 2025 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#

#  Config setting defaults. See documentation for full range. Commented out
#  options represent defaults
#
use WebDyne;


#  Error display/extended display on/off. More granular options below. 
#  Set to 1 to enable, 0 to disable
#
#  $WebDyne::WEBDYNE_ERROR_SHOW=<!-- $WEBDYNE_ERROR_SHOW -->;
#  $WebDyne::WEBDYNE_ERROR_SHOW_EXTENDED=<!-- $WEBDYNE_ERROR_SHOW_EXTENDED -->;


#  Extended error control.
#
#  $WebDyne::WEBDYNE_ERROR_SOURCE_CONTEXT_SHOW=<!-- $WEBDYNE_ERROR_SOURCE_CONTEXT_SHOW -->;
#  $WebDyne::WEBDYNE_ERROR_SOURCE_CONTEXT_LINES_PRE=<!-- $WEBDYNE_ERROR_SOURCE_CONTEXT_LINES_PRE -->;
#  $WebDyne::WEBDYNE_ERROR_SOURCE_CONTEXT_LINES_POST=<!-- $WEBDYNE_ERROR_SOURCE_CONTEXT_LINES_POST -->;
#
#
#  Max length of source line to show in ouput. 0 for unlimited.
#
#  $WebDyne::WEBDYNE_ERROR_SOURCE_CONTEXT_LINE_FRAGMENT_MAX=<!-- $WEBDYNE_ERROR_SOURCE_CONTEXT_LINE_FRAGMENT_MAX -->;
#
#
#  Show filename (including full filesystem path)
#
#
#  $WebDyne::WEBDYNE_ERROR_SOURCE_FILENAME_SHOW=<!-- $WEBDYNE_ERROR_SOURCE_FILENAME_SHOW -->;
#
#
#  Show backtrace, show full or brief backtrace
#
#  $WebDyne::WEBDYNE_ERROR_BACKTRACE_SHOW=<!-- $WEBDYNE_ERROR_BACKTRACE_SHOW -->;
#  $WebDyne::WEBDYNE_ERROR_BACKTRACE_SHORT=<!-- $WEBDYNE_ERROR_BACKTRACE_SHORT -->;
#
#
#  Show eval trace. Uses SOURCE_CONTEXT_LINES to determine number of lines to show
#
#  $WebDyne::WEBDYNE_ERROR_EVAL_CONTEXT_SHOW=<!-- $WEBDYNE_ERROR_EVAL_CONTEXT_SHOW -->;
#
#
#
#  CGI Params
#
#  $WebDyne::WEBDYNE_ERROR_CGI_PARAM_SHOW=<!-- $WEBDYNE_ERROR_CGI_PARAM_SHOW -->;
#
#
#  URI and version
#
#  $WebDyne::WEBDYNE_ERROR_URI_SHOW=<!-- $WEBDYNE_ERROR_URI_SHOW -->;
#  $WebDyne::WEBDYNE_ERROR_VERSION_SHOW=<!-- $WEBDYNE_ERROR_VERSION_SHOW -->;


#  CGI Upload facility. Set to 0 to enable, max post size as required
#
#  $WebDyne::WEBDYNE_CGI_DISABLE_UPLOADS=<!-- $WEBDYNE_CGI_DISABLE_UPLOADS -->;
#  $WebDyne::WEBDYNE_CGI_POST_MAX=<!-- $WEBDYNE_CGI_POST_MAX -->; #(512 * 1024); #512Kb


#  Send no-cache headers ?
#
#  $WebDyne::WEBDYNE_NO_CACHE=<!-- $WEBDYNE_NO_CACHE -->;


#  Warnings fatal ? 
#
#  $WebDyne::WEBDYNE_WARNINGS_FATAL=<!-- $WEBDYNE_WARNINGS_FATAL -->;


#  Encoding
#
#  $WebDyne::WEBDYNE_CHARSET='<!-- $WEBDYNE_CHARSET -->';


#  Include a Content-Type meta tag ?
#
#  $WebDyne::WEBDYNE_CONTENT_TYPE_HTML_META=<!-- $WEBDYNE_CONTENT_TYPE_HTML_META -->;


#  Default <html> tag paramaters, eg { lang	=>'en-US' }
#
#  $WebDyne::WEBDYNE_HTML_PARAM=<!-- $WEBDYNE_HTML_PARAM || 'undef'-->;


#  CGI Paramater expansion. Will make POST submit strings of "foo=bar&car=dar" into
#  individual paramaters. Set to 0 if not desired
#
#  $WebDyne::WEBDYNE_CGI_PARAM_EXPAND=<!-- $WEBDYNE_CGI_PARAM_EXPAND -->;


#  Reload modules from disk if changed ?
#
#
#  $WebDyne::WENDYNE_RELOAD=<!-- $WEBDYNE_RELOAD -->;


#  Alway return true value at end of load
#
1;