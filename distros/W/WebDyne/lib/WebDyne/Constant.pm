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
package WebDyne::Constant;


#  Pragma
#
use strict qw(vars);
#use vars   qw($VERSION @ISA %EXPORT_TAGS @EXPORT_OK @EXPORT %Constant);
use vars   qw($VERSION %Constant);
use warnings;
no warnings qw(uninitialized);
local $^W=0;


#  External modules
#
use WebDyne::Util;
use File::Spec;
use Data::Dumper;
$Data::Dumper::Indent=1;
require Opcode;


#  Version information
#
$VERSION='2.028';


#  Get mod_perl version. Clear $@ after evals
#
eval {require mod_perl2 if ($ENV{'MOD_PERL_API_VERSION'} == 2)} ||
    eval {require Apache2 if $ENV{'MOD_PERL'}=~/1.99/} ||
    eval {require mod_perl if $ENV{'MOD_PERL'}};
eval {} if $@;
my $Mod_perl_version=$mod_perl::VERSION || $mod_perl2::VERSION || $ENV{MOD_PERL_API_VERSION};
my $MP2=($Mod_perl_version > 1.99) ? 1 : 0;


#  Temp location to hold vars we propagate into multiple constants below.
#
my %constant_temp;


#  Hash of constants
#
%Constant=(


    #  Array structure index abstraction. Do not change or bad
    #  things will happen.
    #
    WEBDYNE_NODE_NAME_IX         => 0,
    WEBDYNE_NODE_ATTR_IX         => 1,
    WEBDYNE_NODE_CHLD_IX         => 2,
    WEBDYNE_NODE_SBST_IX         => 3,
    WEBDYNE_NODE_LINE_IX         => 4,
    WEBDYNE_NODE_LINE_TAG_END_IX => 5,
    WEBDYNE_NODE_SRCE_IX         => 6,


    #  Container structure
    #
    WEBDYNE_CONTAINER_META_IX => 0,
    WEBDYNE_CONTAINER_DATA_IX => 1,


    #  Where compiled scripts are stored. Scripts are stored in
    #  here with a the inode of the source file as the cache
    #  file name.
    #
    WEBDYNE_CACHE_DN => &cache_dn,


    #  Empty cache files at startup ? Default is yes (psp files wil be
    #  recompiled again after a server restart)
    #
    WEBDYNE_STARTUP_CACHE_FLUSH => 1,


    #  How often to check cache for excess entries, clean to
    #  low_water if > high_water entries, based on last used
    #  time or frequency.
    #
    #  clean_method 0				= clean based on last used time (oldest
    #  get cleaned)
    #
    #  clean_method 1				= clean based on frequency of use (least
    #  used get cleaned)
    #
    WEBDYNE_CACHE_CHECK_FREQ   => 256,
    WEBDYNE_CACHE_HIGH_WATER   => 64,
    WEBDYNE_CACHE_LOW_WATER    => 32,
    WEBDYNE_CACHE_CLEAN_METHOD => 1,


    #  Type of eval code to run - use Safe module, or direct. Direct
    #  is default, but may allow subversion of code
    #
    #  1					= Safe # Not tested much - don't assume it is really safe !
    #  0					= Direct (UnSafe)
    #
    WEBDYNE_EVAL_SAFE => 0,


    #  Prefix eval code with strict pragma. Can be undef'd to remove
    #  this behaviour, or altered to suit local taste
    #
    WEBDYNE_EVAL_USE_STRICT => 'use strict qw(vars);',


    #  Global opcode set, only these opcodes can be used if using a
    #  safe eval type. Uncomment the full_opset line if you want to
    #  be able to use all perl opcodes. Ignored if using direct eval
    #
    #WEBDYNE_EVAL_SAFE_OPCODE_AR		=>	[&Opcode::full_opset()],
    #WEBDYNE_EVAL_SAFE_OPCODE_AR			=>	[&Opcode::opset(':default')],
    WEBDYNE_EVAL_SAFE_OPCODE_AR => [':default'],


    #  Use strict var checking, eg will check that a when ${varname} param
    #  exists with a HTML page that the calling perl code (a) supplies a
    #  "varname" hash parm, and (b) that param is not undef
    #
    WEBDYNE_STRICT_VARS         => 1,
    WEBDYNE_STRICT_DEFINED_VARS => 0,


    #  When a perl method loaded by a user calls another method within
    #  that just-loaded package (eg sub foo { shift()->bar() }), the
    #  WebDyne AUTOLOAD method gets called to work out where "bar" is,
    #  as it is not in the WebDyne ISA stack.
    #
    #  By default, this gets done every time the routine is called,
    #  which can add up when done many times. By setting the var below
    #  to 1, the AUTOLOAD method will pollute the WebDyne class with
    #  a code ref to the method in question, saving a run through
    #  AUTOLOAD if it is ever called again. The downside - it is
    #  forever, and if your module has a method of the same name as
    #  one in the WebDyne class, it will clobber the WebDyne one, probably
    #  bringing the whole lot crashing down around your ears.
    #
    #  The upside. A speedup of about 10% on modules that use AUTOLOAD
    #  heavily
    #
    WEBDYNE_AUTOLOAD_POLLUTE => 0,


    #  Dump flag. Set to 1 if you want the <dump> tag to display the
    #  current CGI status
    #
    WEBDYNE_DUMP_FLAG => 0,


    #  Content-type for text/html. Combined with charset to produce Content-type header
    #
    WEBDYNE_CONTENT_TYPE_HTML => do {
        $constant_temp{'webdyne_content_type_html'}='text/html'
    },


    #  Content-type for text/plain. As above
    #
    WEBDYNE_CONTENT_TYPE_TEXT => 'text/plain',
    WEBDYNE_CONTENT_TYPE_JSON => 'application/json',
    
    
    #  Script types which are executable so we won't subst strings in them
    #
    WEBDYNE_SCRIPT_TYPE_EXECUTABLE_HR => { map { $_=>1 } qw(
        text/javascript
        application/javascript
        module
    )},

    #  Encoding
    #
    WEBDYNE_HTML_CHARSET => do {
        $constant_temp{'webdyne_html_charset'}='UTF-8'
    },


    #  DTD to use when generating HTML
    #
    WEBDYNE_DTD  => '<!DOCTYPE html>',
    WEBDYNE_META => {
    
        # Set to 'chareset=UTF-8' => undef to get result we want
        'charset='.$constant_temp{'webdyne_html_charset'} => undef,
        
        # Set viewport by default
        viewport => 'width=device-width, initial-scale=1.0'
    },


    #  Include a Content-Type meta tag ?
    #
    WEBDYNE_CONTENT_TYPE_HTML_META => 0,


    #  Default <html> tag paramaters, eg { lang	=>'en-US' }
    #
    WEBDYNE_HTML_PARAM => {lang => 'en' },
    

    #  Default params for <start_html> tag
    #
    #  E.g. WEBDYNE_START_HTML_PARAM => {  include_style=>['foo.css', 'bar.css'] },

    #
    WEBDYNE_START_HTML_PARAM => {},
    
    
    #  Make include/other sections in start_html tag static, i.e. load them at compile
    #  time and they never change. Make undef to force re-include every page load
    #
    WEBDYNE_START_HTML_PARAM_STATIC => 1,
    
    
    #  Anything that should be added in <head> section. Will be inserted verbatim before
    #  </head>. No interpolation or variables, simple text string only. Useful for setting
    #  global stylesheet, e.g. 
    #
    #  WEBDYNE_HEAD_INSERT =>  '<link href="https://cdn.jsdelivr.net/npm/water.css@2/out/water.css" rel="stylesheet">'
    #
    #  Will be added to all <head> sections universally.
    #
    WEBDYNE_HEAD_INSERT => '',
    
    
    #  Ignore ignorable whitespace in compile. Play around with these settings if
    #  you don't like the formatting of the compiled HTML. See HTML::TreeBuilder
    #  man page for details here
    #
    WEBDYNE_COMPILE_IGNORE_WHITESPACE   => 1,
    WEBDYNE_COMPILE_NO_SPACE_COMPACTING => 0,


    # Other Compile settings
    #
    WEBDYNE_COMPILE_P_STRICT            => 1,
    WEBDYNE_COMPILE_IMPLICIT_BODY_P_TAG => 1,


    #  Store and render comments ?
    #
    WEBDYNE_STORE_COMMENTS => 1,


    #  Send no-cache headers ?
    #
    WEBDYNE_NO_CACHE => 1,


    #  Render blocks outside of perl code
    #
    #WEBDYNE_DELAYED_BLOCK_RENDER		=>	1,


    #  Are warnings fatal ?
    #
    WEBDYNE_WARNINGS_FATAL => 0,


    #  CGI disable uploads default, max post size default
    #
    WEBDYNE_CGI_DISABLE_UPLOADS => 1,
    WEBDYNE_CGI_POST_MAX        => (512*1024),    #512Kb


    #  Expand CGI parameters found in CGI values, e.g. button with submit=1&name=2 will get those
    #  CGI params set.
    #
    WEBDYNE_CGI_PARAM_EXPAND => 1,


    #  Disable CGI autoescape of form fields ?
    #
    WEBDYNE_CGI_AUTOESCAPE => 0,


    #  Error handling. Use text errors rather than HTML ?
    #
    WEBDYNE_ERROR_TEXT => 0,


    #  Show errors ? Extended shows additional information with granularity as per following
    #  section.
    #
    WEBDYNE_ERROR_SHOW          => 1,
    WEBDYNE_ERROR_SHOW_EXTENDED => 0,


    #  Show error, source file context, number of lines pre and post. Only applicable
    #  for extended + HTML error output.
    #
    WEBDYNE_ERROR_SOURCE_CONTEXT_SHOW       => 1,
    WEBDYNE_ERROR_SOURCE_CONTEXT_LINES_PRE  => 4,
    WEBDYNE_ERROR_SOURCE_CONTEXT_LINES_POST => 4,

    #  Max length of source line to show in ouput. 0 for unlimited.
    WEBDYNE_ERROR_SOURCE_CONTEXT_LINE_FRAGMENT_MAX => 80,

    #  Show filename (FULL for full filesystem path)
    WEBDYNE_ERROR_SOURCE_FILENAME_SHOW => 1,
    WEBDYNE_ERROR_SOURCE_FILENAME_FULL => 0,

    #  Show backtrace, show full or brief backtrace
    WEBDYNE_ERROR_BACKTRACE_SHOW  => 1,
    WEBDYNE_ERROR_BACKTRACE_SHORT => 0,
    #  Skip (eval) and __ANON__ methods unless set to 1
    WEBDYNE_ERROR_BACKTRACE_FULL  => 0,

    #  Show eval trace. Uses SOURCE_CONTEXT_LINES to determine number of lines to show
    WEBDYNE_ERROR_EVAL_CONTEXT_SHOW => 1,

    #  CGI and other info
    WEBDYNE_ERROR_CGI_PARAM_SHOW        => 1,
    WEBDYNE_ERROR_ENV_SHOW              => 1,
    WEBDYNE_ERROR_WEBDYNE_CONSTANT_SHOW => 1,

    #  URI and version
    WEBDYNE_ERROR_URI_SHOW     => 1,
    WEBDYNE_ERROR_VERSION_SHOW => 1,
    WEBDYNE_ERROR_INTERNAL_SHOW => 0,

    #  Internal indexes for error eval handler array
    #
    #WEBDYNE_ERROR_EVAL_TEXT_IX     => 0,
    #WEBDYNE_ERROR_EVAL_EMBEDDED_IX => 1,
    #WEBDYNE_ERROR_EVAL_LINE_NO_IX  => 2,


    #  Alternate error message if WEBDYNE_ERROR_SHOW disabled
    #
    WEBDYNE_ERROR_SHOW_ALTERNATE =>
        'error display disabled - enable WEBDYNE_ERROR_SHOW to show errors, or review web server error log.',

    #  Default title
    #
    WEBDYNE_HTML_DEFAULT_TITLE => 'Untitled Document',


    #  HTML Tiny mode, XML or HTML
    #
    WEBDYNE_HTML_TINY_MODE => 'html',


    #  Development mode - recompile loaded modules
    #
    WEBDYNE_RELOAD => 0,


    #  Use JSON canonical mode ?
    #
    WEBDYNE_JSON_CANONICAL => 1,
    
    
    #  Enable the API mode ?
    #
    WEBDYNE_API_ENABLE => 1,
    
    
    #  Enable Alpine/Vue hack
    #
    WEBDYNE_ALPINE_VUE_ATTRIBUTE_HACK_ENABLE => 'x-on',
    
    
    #  Request headers for HTMX and Alpine Ajax
    #
    WEBDYNE_HTTP_HEADER_AJAX_HR => { map { $_=> 1} @{$_=[qw(
        hx-request
        x-alpine-request
    )]}},
    WEBDYNE_HTTP_HEADER_AJAX_AR => $_,


    #  Headers
    #
    WEBDYNE_HTTP_HEADER => {

        'Content-Type'              => sprintf('%s; charset=%s', @constant_temp{qw(webdyne_content_type_html webdyne_html_charset)}),
        'Cache-Control'             => 'no-cache, no-store, must-revalidate',
        'Pragma'                    => 'no-cache',
        'Expires'                   => '0',
        'X-Content-Type-Options'    => 'nosniff',
        'X-Frame-Options'           => 'SAMEORIGIN'
        
        #  Set other options here, e.g.
        #
        #'Strict-Transport-Security' => 'max-age=31536000; includeSubDomains; preload',
        #'Content-Security-Policy'   => "default-src 'self'; style-src 'self' https://cdn.jsdelivr.net https://fonts.googleapis.com/ 'unsafe-inline'; font-src https://fonts.gstatic.com",
        #'Referrer-Policy'           => 'strict-origin-when-cross-origin',

    },
    
    
    #  Webdyne PSGI serves static files ?
    #
    WEBDYNE_PSGI_STATIC => 1,
    
    
    #  WebDyne default extension and length, used in susbtr as faster than regex
    #
    WEBDYNE_PSP_EXT 	=> '.psp',
    WEBDYNE_PSP_EXT_LEN	=> 4,
    
    
    #  Very minimal MIME type hash used by lookup_file function
    #
    WEBDYNE_MIME_TYPE_HR => {
        'html' => 'text/html',
        'htm'  => 'text/html',
        'txt'  => 'text/plain',
        'jpg'  => 'image/jpeg',
        'jpeg' => 'image/jpeg',
        'png'  => 'image/png',
        'gif'  => 'image/gif',
        'css'  => 'text/css',
        'js'   => 'application/javascript',
        'json' => 'application/json',
        'pdf'  => 'application/pdf',
        'svg'  => 'image/svg+xml'
    },


    #  Mod_perl level. Do not change unless you know what you are
    #  doing.
    #
    MP2      => $MP2,
    MOD_PERL => $Mod_perl_version


);


sub local_constant_load {


    #  Load constants from override files first
    #
    my ($class, $constant_hr)=@_;
    debug("class $class, constant_hr %s", Dumper($constant_hr));
    my $local_constant_pn_ar=&local_constant_pn();
    debug("local_constant_pn_ar: %s", Dumper($local_constant_pn_ar));
    foreach my $local_constant_pn (@{$local_constant_pn_ar}) {
        debug("load local_constant_pn: $local_constant_pn");
        my $local_hr=(-f $local_constant_pn) && (
            do($local_constant_pn)
            ||
            warn "unable to read local constant file, $!"
        );
        debug("local_hr $local_hr");
        if (my $hr=$local_hr->{$class}) {
            debug("found class $class hr %s", Dumper($hr));
            while (my ($key, $val)=each %{$hr}) {
                $constant_hr->{$key}=$val;
            }
        }
    }


    #  Now from environment vars - override anything in config file
    #
    foreach my $key (keys %{$constant_hr}) {
        if (defined $ENV{$key}) {
            my $val=$ENV{$key};
            debug("using environment value $val for key: $key");
            $constant_hr->{$key}=$val;
        }
    }


    #  Then command line
    #
    #GetOptions($constant_hr, map { "$_=s" } keys %{$constant_hr});


    #  Load up Apache config - only if running under mod_perl
    #
    if ($Mod_perl_version) {


        #  Ignore die's for the moment so don't get caught by error handler
        #
        debug("detected mod_perl version $Mod_perl_version - loading Apache directives");
        local $SIG{'__DIE__'}=undef;
        my $server_or;
        eval {
            #  Modern mod_perl 2
            require Apache2::ServerUtil;
            require APR::Table;
            $server_or=Apache2::ServerUtil->server();
        };
        $@ && eval {

            #  Interim mod_perl 1.99x
            require Apache::ServerUtil;
            require APR::Table;
            $server_or=Apache::ServerUtil->server();
        };
        $@ && eval {

            #  mod_perl 1x ?
            require Apache::Table;
            $server_or=Apache->server();
        };

        #  Clear any eval errors, set via dir_config now (overrides env)
        #
        $@ && do {
            eval {undef}; errclr()
        };
        debug("loaded server_or: $server_or");
        if ($server_or) {
            my $table_or=$server_or->dir_config();
            while (my ($key, $val)=each %{$table_or}) {
                debug("installing value $val for Apache directive: $key");
                $constant_hr->{$key}=$val if exists $constant_hr->{$key};
            }
        }
    }


    #  Is charset defined ? If so combine into content-type header
    #
    if (my $charset=$constant_hr->{'WEBDYNE_CHARSET'}) {
        $constant_hr->{'WEBDYNE_CONTENT_TYPE_HTML'}=sprintf("%s; charset=$charset", $constant_hr->{'WEBDYNE_CONTENT_TYPE_HTML'})
            unless $constant_hr->{'WEBDYNE_CONTENT_TYPE_HTML'}=~/charset=/;
        $constant_hr->{'WEBDYNE_CONTENT_TYPE_TEXT'}=sprintf("%s; charset=$charset", $constant_hr->{'WEBDYNE_CONTENT_TYPE_TEXT'})
            unless $constant_hr->{'WEBDYNE_CONTENT_TYPE_TEXT'}=~/charset=/;
        $constant_hr->{'WEBDYNE_CONTENT_TYPE_JSON'}=sprintf("%s; charset=$charset", $constant_hr->{'WEBDYNE_CONTENT_TYPE_JSON'})
            unless $constant_hr->{'WEBDYNE_CONTENT_TYPE_JSON'}=~/charset=/;
    }


    #  Done - return constant hash ref
    #
    $constant_hr;

}


sub local_constant_pn {


    #  Where local constants reside
    #
    my @local_constant_pn;
    my $local_constant_fn='webdyne.conf.pl';
    if ($^O=~/MSWin[32|64]/) {
        my $dn=$ENV{'WEBDYNE_HOME'} || $ENV{'WEBDYNE'} || $ENV{'WINDIR'};
        push @local_constant_pn, ($ENV{'WEBDYNE_CONF'} || 
            File::Spec->catfile($dn, $local_constant_fn))
    }
    else {
        push @local_constant_pn, ($ENV{'WEBDYNE_CONF'} || 
            File::Spec->catfile(
                File::Spec->rootdir(), 'etc', $local_constant_fn
        ))
    }
    unless ($ENV{'WEBDYNE_CONF'}) {
        push @local_constant_pn, glob(sprintf('~/.%s', $local_constant_fn));
    }
    return \@local_constant_pn;

}


sub cache_dn {


    #  Where the cache directory should be located
    #
    my $cache_dn;
    if ($ENV{'PAR_TEMP'}) {
        $cache_dn=$ENV{'PAR_TEMP'}
    }


    #  Used to set like this - now leave the installer to
    #  find and set an appropriate location
    #
    #else {
    #require File::Temp;
    #$cache_dn=&File::Temp::tempdir( CLEANUP=> 1 );
    #}
    #elsif ($prefix) {
    #  $cache_dn=File::Spec->catdir($prefix, 'cache');
    #}
    #elsif ($^O=~/MSWin[32|64]/) {
    #  $cache_dn=File::Spec->catdir($ENV{'SYSTEMROOT'}, qw(TEMP webdyne))
    #}
    #else {
    #  $cache_dn=File::Spec->catdir(
    #    File::Spec->rootdir(), qw(var cache webdyne));
    #}
    return $cache_dn

}


sub hashref {

    my $class=shift();
    return \%{"${class}::Constant"};

}


sub import {
    
    my $class=shift();
    (my $class_parent=$class)=~s/::Constant$//;
    my $hr=\%{"${class}::Constant"};
    if ($_[0] eq 'dump') {
        local $Data::Dumper::Indent=1;
        local $Data::Dumper::Terse=1;
        CORE::print Dumper($hr);
        exit 0;
    }
    else {

        my $caller = caller(0);
        no warnings qw(once);
        while (my($k, $v)=each %{$hr}) {
            #  Used to do just
            #  
            # *{"${caller}::${k}"}=\$v;
            #
            #  Make a bit more sophisticated so if the
            #  var is updated anywhere it is used all 
            #  modules see + put a hash called Constant in
            #  the parent module so we don't have to do
            #
            #  %WebDyne::Constant::Constant 
            # 
            #  now just
            #
            #  %WebDyne::Constant
            #
            if ($caller eq $class_parent) {
                *{"${caller}::${k}"}=\$v;
                #*{"${caller}::Constant"}=$hr; # Pulled for moment, bit polluting without ability to ref constant scalars in hash values
            }
            else {
                *{"${caller}::${k}"}=\${"${class_parent}::${k}"};
                #*{"${caller}::${k}"}=\${"${class_parent}::${k}"}; # Stop "only used once" warning;
            }
            next if *{"${caller}::${k}"}{'CODE'};
            next if ref($v);
            if ($v=~/^\d+$/) {
                *{"${caller}::${k}"}=eval("sub () { $v }");
            }
            else {
                *{"${caller}::${k}"}=eval("sub () { q($v) }");
            }
                
        }
    }
}


&local_constant_load(__PACKAGE__, \%Constant);
1;


__END__

=begin markdown

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

=end markdown


=head1 NAME

WebDyne::Constant - WebDyne Configuration Constants


=head1 SYNOPSIS


 #  Perl code
 #
 use WebDyne::Constant;
 print $WEBDYNE_CACHE_DN;

=head1 DESCRIPTION

This module provides a list of configuration constants used in the WebDyne code. These constants are used to configure the behavior of the WebDyne system 
and can be accessed by importing the module and referencing the constants by name.

Constants can be configured to different values by setting environment variables, command line options, or Apache directives


=head2 CONSTANTS

The following user configurable constants are defined in the module. The default value of the configuration
constant is provided after the constant name.

=over

=item -

C<WEBDYNE_CACHE_DN> (cache directory)


=item -

Directory where compiled scripts are stored.



=item -

C<WEBDYNE_STARTUP_CACHE_FLUSH> (1)


=item -

Flush cache files at startup.



=item -

C<WEBDYNE_CACHE_CHECK_FREQ> (256)


=item -

Frequency to check cache for excess entries.



=item -

C<WEBDYNE_CACHE_HIGH_WATER> (64)


=item -

High water mark for cache entries.



=item -

C<WEBDYNE_CACHE_LOW_WATER> (32)


=item -

Low water mark for cache entries.



=item -

C<WEBDYNE_CACHE_CLEAN_METHOD> (1)


=item -

Method to clean cache (0: last used time, 1: frequency of use).



=item -

C<WEBDYNE_EVAL_SAFE> (0)


=item -

Type of eval code to run (0: Direct, 1: Safe).



=item -

C<WEBDYNE_EVAL_USE_STRICT> ('use strict qw(vars);')


=item -

Prefix eval code with strict pragma.



=item -

C<WEBDYNE_EVAL_SAFE_OPCODE_AR> ([':default'])


=item -

Global opcode set for safe eval.



=item -

C<WEBDYNE_STRICT_VARS> (1)


=item -

Use strict variable checking.



=item -

C<WEBDYNE_STRICT_DEFINED_VARS> (0)


=item -

Check that variables are defined.



=item -

C<WEBDYNE_AUTOLOAD_POLLUTE> (0)


=item -

Pollute WebDyne class with method references for speedup.



=item -

C<WEBDYNE_DUMP_FLAG> (0)


=item -

Flag to display current CGI value and other information if  tag is used.



=item -

C<WEBDYNE_CONTENT_TYPE_HTML> ('text/html')


=item -

Content-type for text/html.



=item -

C<WEBDYNE_CONTENT_TYPE_PLAIN> ('text/plain')


=item -

Content-type for text/plain.



=item -

C<WEBDYNE_HTML_CHARSET> ('UTF-8')


=item -

Character set for HTML.



=item -

C<WEBDYNE_DTD> ('')


=item -

DTD to use when generating HTML.



=item -

C<WEBDYNE_META> ({charset => 'UTF-8'})


=item -

Meta information for HTML.



=item -

C<WEBDYNE_CONTENT_TYPE_HTML_META> (0)


=item -

Include a Content-Type meta tag.



=item -

C<WEBDYNE_HTML_PARAM> ({lang => 'en'})


=item -

Default  tag parameters.



=item -

C<WEBDYNE_COMPILE_IGNORE_WHITESPACE> (1)


=item -

Ignore ignorable whitespace in compile.



=item -

C<WEBDYNE_COMPILE_NO_SPACE_COMPACTING> (0)


=item -

Disable space compacting in compile.



=item -

C<WEBDYNE_COMPILE_P_STRICT> (1)


=item -

Use strict parsing in compile.



=item -

C<WEBDYNE_COMPILE_IMPLICIT_BODY_P_TAG> (1)


=item -

Implicitly add <body> and <p> tags in compile.



=item -

C<WEBDYNE_STORE_COMMENTS> (1)


=item -

Store and render comments.



=item -

C<WEBDYNE_NO_CACHE> (1)


=item -

Send no-cache headers.



=item -

C<WEBDYNE_WARNINGS_FATAL> (0)


=item -

Are warnings fatal?



=item -

C<WEBDYNE_CGI_DISABLE_UPLOADS> (1)


=item -

Disable CGI uploads by default.



=item -

C<WEBDYNE_CGI_POST_MAX> (524288)


=item -

Max post size for CGI (512KB).



=item -

C<WEBDYNE_CGI_PARAM_EXPAND> (1)


=item -

Expand CGI parameters found in CGI values.



=item -

C<WEBDYNE_CGI_AUTOESCAPE> (0)


=item -

Disable CGI autoescape of form fields.



=item -

C<WEBDYNE_ERROR_TEXT> (0)


=item -

Use text errors rather than HTML.



=item -

C<WEBDYNE_ERROR_SHOW> (1)


=item -

Show errors.



=item -

C<WEBDYNE_ERROR_SHOW_EXTENDED> (0)


=item -

Show extended error information.



=item -

C<WEBDYNE_ERROR_SOURCE_CONTEXT_SHOW> (1)


=item -

Show error source file context.



=item -

C<WEBDYNE_ERROR_SOURCE_CONTEXT_LINES_PRE> (4)


=item -

Number of lines to show before error context.



=item -

C<WEBDYNE_ERROR_SOURCE_CONTEXT_LINES_POST> (4)


=item -

Number of lines to show after error context.



=item -

C<WEBDYNE_ERROR_SOURCE_CONTEXT_LINE_FRAGMENT_MAX> (80)


=item -

Max length of source line to show in output.



=item -

C<WEBDYNE_ERROR_SOURCE_FILENAME_SHOW> (1)


=item -

Show filename in error output.



=item -

C<WEBDYNE_ERROR_BACKTRACE_SHOW> (1)


=item -

Show backtrace in error output.



=item -

C<WEBDYNE_ERROR_BACKTRACE_SHORT> (0)


=item -

Show brief backtrace.



=item -

C<WEBDYNE_ERROR_EVAL_CONTEXT_SHOW> (1)


=item -

Show eval trace in error output.



=item -

C<WEBDYNE_ERROR_CGI_PARAM_SHOW> (1)


=item -

Show CGI parameters in error output.



=item -

C<WEBDYNE_ERROR_ENV_SHOW> (1)


=item -

Show environment variables in error output.



=item -

C<WEBDYNE_ERROR_WEBDYNE_CONSTANT_SHOW> (1)


=item -

Show WebDyne constants in error output.



=item -

C<WEBDYNE_ERROR_URI_SHOW> (1)


=item -

Show URI in error output.



=item -

C<WEBDYNE_ERROR_VERSION_SHOW> (1)


=item -

Show version in error output.



=item -

C<WEBDYNE_ERROR_EVAL_TEXT_IX> (0)


=item -

Index for error eval text.



=item -

C<WEBDYNE_ERROR_SHOW_ALTERNATE> ('error display disabled - enable WEBDYNE_ERROR_SHOW to show errors, or review web server error log.')


=item -

Alternate error message if error display is disabled.



=item -

C<WEBDYNE_HTML_DEFAULT_TITLE> ('Untitled Document')


=item -

Default title for HTML documents.



=item -

C<WEBDYNE_HTML_TINY_MODE> ('html')


=item -

Mode for HTML Tiny (XML or HTML).



=item -

C<WEBDYNE_RELOAD> (0)


=item -

Development mode - recompile loaded modules.



=item -

C<WEBDYNE_JSON_CANONICAL> (1)


=item -

Use JSON canonical mode.



=item -

C<WEBDYNE_HTTP_HEADER> (HashRef)


=item -

Default HTTP headers.



=item -

C<MP2> (mod_perl version)


=item -

Mod_perl level. Auto-detected, do not change unless you know what you are doing.



=item -

C<MOD_PERL> (mod_perl version)


=item -

Mod_perl version. Auto-detected, do not change unless you know what you are doing.


=back

=cut
