#
#  This file is part of WebDyne.
#
#  This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.
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
use vars   qw($VERSION %Constant %Package);
use warnings;
no warnings qw(uninitialized);


#  External modules
#
use WebDyne::Util;
use File::Spec;
use Data::Dumper;
$Data::Dumper::Indent=1;
require Opcode;


#  Version information
#
$VERSION='2.075';


#  Get mod_perl version taking intio account legacy strings. Clear $@ after evals
#
eval {require mod_perl2 if (defined($ENV{'MOD_PERL_API_VERSION'}) && ($ENV{'MOD_PERL_API_VERSION'} == 2))} ||
eval {require Apache2 if (defined($ENV{'MOD_PERL'}) && ($ENV{'MOD_PERL'}=~/1.99/))} ||
eval {require mod_perl if $ENV{'MOD_PERL'}};
eval {} if $@;
my $MP_version=$mod_perl::VERSION || $mod_perl2::VERSION || $ENV{MOD_PERL_API_VERSION};
my $MP2=(defined($MP_version) && ($MP_version  > 1.99)) ? 1 : 0;


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
    WEBDYNE_STRICT_VARS => 1,


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


    #  Encoding
    #
    WEBDYNE_HTML_CHARSET => do {
        $constant_temp{'webdyne_html_charset'}='UTF-8'
    },


    #  Content-type for text/html. Combined with charset to produce Content-type header
    #
    WEBDYNE_CONTENT_TYPE_HTML => do {
        $constant_temp{'webdyne_content_type_html'}='text/html'
    },
    WEBDYNE_CONTENT_TYPE_HTML_ENCODED => do {
        $constant_temp{'webdyne_content_type_html_encoded'}=sprintf('%s; charset=%s', @constant_temp{qw(webdyne_content_type_html webdyne_html_charset)})
    },


    #  Content-type for text/plain. As above
    #
    WEBDYNE_CONTENT_TYPE_TEXT => do {
        $constant_temp{'webdyne_content_type_text'}='text/plain'
    },
    WEBDYNE_CONTENT_TYPE_TEXT_ENCODED => 
        sprintf('%s; charset=%s', @constant_temp{qw(webdyne_content_type_text webdyne_html_charset)}),


    #  And JSON
    #
    WEBDYNE_CONTENT_TYPE_JSON => do {
        $constant_temp{'webdyne_content_type_json'}='application/json'
    },
    WEBDYNE_CONTENT_TYPE_JSON_ENCODED => 
        sprintf('%s; charset=%s', @constant_temp{qw(webdyne_content_type_json webdyne_html_charset)}),
    
    
    #  Script types which are executable so we won't subst strings in them
    #
    WEBDYNE_SCRIPT_TYPE_EXECUTABLE_HR => { map { $_=>1 } qw(
        text/javascript
        application/javascript
        module
    )},


    #  DTD to use when generating HTML
    #
    WEBDYNE_DTD  => '<!DOCTYPE html>',
    WEBDYNE_META => {
    
        # Set to 'chareset=UTF-8' => undef to get result we want
        'charset='.$constant_temp{'webdyne_html_charset'} => undef,
        
        # Set viewport by default
        'viewport' => 'width=device-width, initial-scale=1.0'
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
    
    
    #  Shortcut attributes for start_html
    #
    WEBDYNE_START_HTML_SHORTCUT_HR => {
    
        pico    => { style  => 'https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css' },
        htmx    => { script => 'https://cdn.jsdelivr.net/npm/htmx.org@2.0.8/dist/htmx.min.js' }
        
        #  Commented out for now, left as syntax examples
        #

        #bootstrap	=> { 
        #    style => 'https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css', 
        #    script => 'https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/js/bootstrap.bundle.min.js' 
        #},
        #alpine		=> { script => 'https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js#defer' },
        #tailwind	=> { style => 'https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4' },
        #alpine_ajax	=> { script => [
        #    'https://cdn.jsdelivr.net/npm/@imacrayon/alpine-ajax@0.12.6/dist/cdn.min.js#defer',
        #    'https://cdn.jsdelivr.net/npm/alpinejs@3.14.1/dist/cdn.min.js#defer'
        #]}
        
    },
    
    
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
    WEBDYNE_CGI_DISABLE_UPLOADS => 0,
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


    #  Use JSON canonical. pretty mode ?
    #
    WEBDYNE_JSON_CANONICAL => 1,
    WEBDYNE_JSON_PRETTY => 0,
    
    
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
    
    
    #  Force run of <htmx> tag even if no hx-request header
    #
    WEBDYNE_HTMX_FORCE => 0,


    #  Headers
    #
    WEBDYNE_HTTP_HEADER => {

        #'Content-Type'              => sprintf('%s; charset=%s', @constant_temp{qw(webdyne_content_type_html webdyne_html_charset)}),
        'Content-Type'              => $constant_temp{'webdyne_content_type_html_encoded'},
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
    
    
    #  WebDyne default extension and length, used in susbtr as faster than regex. Update - too slow, retiring and going to fixed
    #  string .psp extension
    #
    WEBDYNE_PSP_EXT 	=> ($constant_temp{'webdyne_psp_ext'}='.psp'),
    WEBDYNE_PSP_EXT_RE  => qr/\Q$constant_temp{'webdyne_psp_ext'}\E/,
    
    
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
        'svg'  => 'image/svg+xml',
        'yml'  => 'application/x-yaml',
        'yaml' => 'application/x-yaml',
        'xml'  => 'application/xml',
        'toml' => 'application/toml',
        'md'   => 'text/markdown'
    },
    
    
    #  Other file extenstions the PSGI indexer is allowed to open
    #
    WEBDYNE_INDEX_EXT_ALLOWED_HR => { map {$_=>1} qw(
        psp
        pm
        pl
    )},


    #  And raw file names. Should be regexp, todo
    #
    WEBDYNE_INDEX_FN_ALLOWED_HR => { map {$_=>1} qw(
        LICENSE
        MANIFEST
        Makefile
        cpanfile
        cpanfile.snapshot
        Dockerfile
    )},
    
    
    #  Dir_config can be loaded from here if not in Apache
    #
    WEBDYNE_DIR_CONFIG => undef,
    
    
    #  Dir_config can be loaded from each directory via webdyne.conf.pl 
    #  if desired, only under Plack at the moment
    #
    WEBDYNE_DIR_CONFIG_CWD_LOAD => 1,
    
    
    #  Local constant path names. Used as marker only, updated dynamically
    #  by &local_constant_load;
    #
    WEBDYNE_CONF_HR => undef,
    
    
    #  Config file name
    #
    WEBDYNE_CONF_FN => 'webdyne.conf.pl',
    
    
    #  Tidy output ? Will require HTML::Tidy5 and all dependencies to be installed
    #
    WEBDYNE_HTML_TIDY => 0,
    
    
    #  HTML::Tidy5 config
    #
    WEBDYNE_HTML_TIDY_CONFIG_HR => {

        'indent'            => 0,      # enable indentation
        'indent-spaces'     => 2,     # 2 spaces per indent level
        'wrap'              => 0,      # don't wrap lines
        'tidy-mark'         => 'no',   # don't add a tidy comment
        'clean'             => 'no',   # don't clean embedded styles
        'drop-empty-elements' => 'no',  # don't remove empty elements
        'hide-comments'     => 'no',        # keep HTML comments
        'fix-uri'           => 'no',        # don't alter URIs
        'output-html'       => 'yes',       # output as HTML
        'show-warnings'     => 'no',        # suppress warnings

    },
    
    
    #  Add some linefeeds via "\n" to output
    #
    WEBDYNE_HTML_NEWLINE => 0,


    #  Mod_perl level. Do not change unless you know what you are
    #  doing.
    #
    MP2      => $MP2,
    MOD_PERL => $MP_version,


);


sub local_constant_fn {


    #  Where local constants reside
    #
    my @local_constant_fn;
    my $local_constant_fn=$Constant{'WEBDYNE_CONF_FN'};
    if ($^O=~/MSWin[32|64]/) {
        my $dn=$ENV{'WEBDYNE_HOME'} || $ENV{'WEBDYNE'} || $ENV{'WINDIR'};
        push @local_constant_fn, ($ENV{'WEBDYNE_CONF'} || 
            File::Spec->catfile($dn, $local_constant_fn))
    }
    else {
        push @local_constant_fn, ($ENV{'WEBDYNE_CONF'} || 
            File::Spec->catfile(
                File::Spec->rootdir(), 'etc', $local_constant_fn
        ))
    }
    unless ($ENV{'WEBDYNE_CONF'}) {
        push @local_constant_fn, glob(sprintf('~/.%s', $local_constant_fn));
    }
    debug('local_constant_fn: %s, env: %s', Dumper(\@local_constant_fn, \%ENV));
    return \@local_constant_fn;

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



sub local_constant_load {


    #  Load constants from override files.
    #
    my ($class, $local_constant_fn)=@_;
    debug("class: $class, local_constant_fn: $local_constant_fn");
    
    
    #  Var to hold hash ref we load
    #
    my $constant_hr;
    
    
    #  Now load, making sure we don't reload already loaded file - with bonus of creating
    #  var that tracks/shows loaded files - WEBDYNE_CONF_HR
    #
    debug("attempt load local_constant_fn: $local_constant_fn");
    if (-f $local_constant_fn && !$Constant{'WEBDYNE_CONF_HR'}{$local_constant_fn}++) {
    #if (-f $local_constant_fn && !$Package{'file'}{$local_constant_fn}++) {
        debug("file exists, about to load from: $local_constant_fn (%s)", File::Spec->rel2abs($local_constant_fn));
        $Constant{'WEBDYNE_CONF_HR'}{$local_constant_fn}++;
        $constant_hr=do(File::Spec->rel2abs($local_constant_fn)) ||
            warn("unable to read local constant file, $!"); 
    }


    #  Now from environment vars - override anything in config file
    #
    my %constant_class=%{"${class}::Constant"};
    foreach my $key (keys %constant_class) {
        if (defined $ENV{$key}) {
            my $val=$ENV{$key};
            debug("using environment value $val for key: $key");
            $constant_hr->{$class}{$key}=$val;
        }
    }


    #  Load up Apache config - only if running under mod_perl
    #
    if (my $server_or=&server_or()) {
        my $table_or=$server_or->dir_config();
        while (my ($key, $val)=each %{$table_or}) {
            debug("installing value $val for Apache directive: $key");
            $constant_hr->{$class}{$key}=$val if exists $constant_class{$key}
        }
    }


    #  Done - return constant hash ref
    #
    return $constant_hr;

}


sub server_or {

    
    #  Get the apache server object if available
    #
    unless (exists($Package{'server_or'})) {
    
    
        #  Var to hold any server object found
        #
        my $server_or;
    
    
        #  Only do checks if running under mod_perl
        #
        if ($MP_version) {


            #  Ignore die's for the moment so don't get caught by error handler
            #
            debug("detected mod_perl version $MP_version - loading Apache directives");
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
            
        }
        else {
            debug('skip server_or load, not running under mod_perl');
        }
        
        
        #  Save away so don't have to do this again
        #
        $Package{'server_or'}=$server_or;
        
    }
    
    
    #  Return it
    #
    return $Package{'server_or'};
    
}


sub import {
    

    #  Get caller
    #
    my ($class, $local_constant_fn)=@_;
    
    
    #  Check for dump flag, reserved word
    #
    my $dump_fg;
    if (($local_constant_fn ||= '') eq 'dump') {
        $dump_fg++;
        $local_constant_fn=undef;
    }
    
    
    #  Get array of local files also
    #
    my $local_constant_fn_ar=&local_constant_fn();
    debug("local_constant_fn_ar: %s", Dumper($local_constant_fn_ar));
    
    
    #  Load files if neccessary, get hash of constants to be applied
    #
    my @class_constant_hr;
    foreach my $fn (grep {$_} (@{$local_constant_fn_ar}, $local_constant_fn)) {
        
        
        #  Don't process twice
        #
        my $fn_hr=$Package{'import'}{$fn} ||= do {
        
            #  Need to load in file, haven't seen it yet/
            #
            debug("loading file: $fn");
            
        
            #  If here need to read hash ref in from file
            #
            &local_constant_load($class, $fn);
            
        };
        debug("local_constant_load hr: $fn_hr, %s", Dumper($fn_hr));
        
        
        #  Any constants for this class into array for loading
        #
        if (my $class_constant_hr=$fn_hr->{$class}) {
            
            
            #   Yes, save for later processing
            #
            debug("adding class_constant_hr: $class_constant_hr for processing, %s", Dumper($class_constant_hr));
            push @class_constant_hr, $class_constant_hr;
            
        }
        else {
            
            debug("skip $fn, no class: $class component in hash ref");
            
        }
        
    }

    
    #  Debug what we have
    #
    debug('class_constant_hr: %s', Dumper(\@class_constant_hr));
        
    
    #  Get hash ref of Constants file from class calling us - calling
    #  module needs to declare a %Class:Name::Constant variable in 
    #  global space.
    #
    my $class_constant_hr=\%{"${class}::Constant"};
    

    #  We want to load variable into namespace. Get the parent class and who is
    #  calling us/
    #
    (my $class_parent=$class)=~s/::Constant$//;
    my $caller = caller(0);
    debug("caller: $caller");        
    
    
    #  Remember caller
    #
    $Package{'caller'}{$class}{$caller}++;
    

    #  Now start iterating over and loading
    #
    foreach $caller (keys %{$Package{'caller'}{$class}}) {
        foreach my $constant_hr ($class_constant_hr, @class_constant_hr) {
        

            #  Now iterate across all callers and load vars into namespace. Turn off warnings as
            #  we may have to redefine some variables
            #
            no warnings qw(once redefine);
            debug("importing for caller: $caller");
            
            
            #  Don't load hash ref into caller if already done. This probably needs to be reworked ..
            #
            if (my $var_test= (keys(%{$constant_hr}))[0] ) {
                debug("picking var: $var_test as test, exists *{${caller}::${var_test}}: %s", defined(*{"${caller}::${var_test}"}));
                if ($Package{'caller'}{$caller}{$constant_hr}++ && defined(*{"${caller}::${var_test}"})) {
                    debug("skip, already applied $constant_hr to caller: $caller");
                    next;
                }
                else {
                    debug('continue');
                }
            }
            else {
                debug('no test var found in constant_hr: %s', Dumper($constant_hr));
            }
            
            
            #  Start iterating over all constants in class 
            #
            while (my($k, $v)=each %{$class_constant_hr}) {
            
                #  Override ?
                #
                if (defined($constant_hr->{$k}) && ($constant_hr ne $class_constant_hr)) {
                
                    #  Yes
                    #
                    debug('override constant_hr $k value: %s with file value: %s', $v, $constant_hr->{$k});
                    $v=$class_constant_hr->{$k}=$constant_hr->{$k};

                }
                debug("caller: $caller, class: $class  set:$k value:$v");


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
                    if (defined *{"${class_parent}::${k}"}) {
                        *{"${caller}::${k}"} = *{"${class_parent}::${k}"};
                    }
                    else {
                        *{"${caller}::${k}"} = \$v;
                    }
                    #  Used to be this                
                    #*{"${caller}::${k}"}=\${"${class_parent}::${k}"};
                }
                debug("caller: $caller, set:$k value:$v");
                #next if ref($v); # Not needed, stop Regexp conversion
                if ($v=~/^\d+$/) {
                    debug("using sub() ${caller}::${k}=$v");
                    *{"${caller}::${k}"}=eval("sub () { $v }");
                }
                else {
                    debug("fall through, using sub() ${caller}::${k}=q($v)");
                    *{"${caller}::${k}"}=eval("sub () { q($v) }");
                }
                    
            }
        }
    }
    
    
    #  Check if just dumping for view, or actually loading into caller
    #  namespace
    #
    if ($dump_fg) {

        #  We just to want to see what they are
        #
        local $Data::Dumper::Indent=1;
        local $Data::Dumper::Terse=1;
        local $Data::Dumper::Sortkeys=1;
        CORE::print Dumper($class_constant_hr);
        exit 0;
    }
    
}


1;


__END__

=pod

=head1 WebDyne::Constant(3pm)

=head1 NAME

WebDyne::Constant - WebDyne module that sets constants and defaults for WebDyne processing

=head1 SYNOPSIS

    #!/usr/bin/env perl
    #
    use WebDyne::Constant;
    print $WEBDYNE_DTD

    # Dump all constant settings for review
    #
    $ perl -MWebDyne::Constant=dump

=head1 Description

This module provides a list of configuration constantDs used in the WebDyne code. These constants are used to configure the behavior of the WebDyne module and can be accessed by importing the module and referencing the constants by name. Constants can be configured to different values by overriding values in local configuration files, setting environment
 variables, command line options, or Apache directives.

Common uses for modifying constant values allow for:

=over

=item * Changing default language from en-US to something else.

=item * Modifying or adding new meta-data or default headers to output

=item * Adding default style-sheets or other inclusions to all output files

=back

Default values for these configuration constants can be updated the following locations:

=over

=item 1. /etc/webdyne.conf.pl

=item 2. $HOME/.webdyne.conf.pl

=item 3. $DOCUMENT_ROOT/.webdyne.conf.pl

=back

As a special case when running under PSGI environments, if WEBDYNE_DIR_CONFIG_CWD_LOAD is true (which it is by default) then each directory that a .psp file is run from is checked for the .webdyne.conf.pl file - but only WEBDYNE_DIR_CONFIG entries from the file are loaded. This allows for configuration of settings such a WebDyneChain modules to load, WebDyneTemplate
 configuration etc. on a per directory basis

The WebDyne::Constant module is sub-classed by other WebDyne modules, and the values for any constants in the WebDyne::<Module>::Constant family of modules can be overridden by creating/updating one of the above two files. Here is a sample configuration file:

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

B<<< WARNING >>>: Ensure the configuration file has the correct syntax by checking the Perl interpreter doesn't throw any errors. Use  C<<<< perl -c -w >>>>  to check syntax:

    # perl -c -w /etc/webdyne.conf.pl
    /etc/webdyne.conf.pl syntax OK
    # perl -c -w ~/.webdyne.conf.pl
    /home/<user>/.webdyne.conf.pl OK

=head1 CONSTANTS

The following configuration constants are defined. The default value of the configuration item is provided after the constant name. Most can be overridden or adjusted however where they are read-only this is noted.

=over

=item * B<<< WEBDYNE_CACHE_DN () >>>

Directory where compiled pages are stored. Unset by default on command line, usually set to temporary directory by installer or PSGI handler. Pages that are compiled from .psp source into an intermediate data structure in Storable format are stored in this location.

=item * B<<< WEBDYNE_STARTUP_CACHE_FLUSH (1) >>>

Flush cache files at startup. If set will delete all cache files and force re-read and recompile of all source .psp files at startup. Recommended to leave at (1)

=item * B<<< WEBDYNE_CACHE_CHECK_FREQ (256) >>>

Perl process frequency (number of runs) to check cache for excess entries and clean any that exceed the cache high water mark.

=item * B<<< WEBDYNE_CACHE_HIGH_WATER (64) >>>

High water mark for cache entries. Once this limit is reaped cache entries will be deleted down to the low water mark level.

=item * B<<< WEBDYNE_CACHE_LOW_WATER (32) >>>

Low water mark for cache entries. Once high water mark is reached cached entries will be deleted down to this level.

=item * B<<< WEBDYNE_CACHE_CLEAN_METHOD (1) >>>

Method to clean cache (0: last used time, 1: frequency of use).

=item * B<<< WEBDYNE_EVAL_SAFE (0) >>>

Type of eval code to run (0: Direct, 1: Safe). All dynamic components of a .psp page are run in an eval block. Running using eval via the Safe module is experimental.

=item * B<<< WEBDYNE_EVAL_SAFE_OPCODE_AR => [':default'] >>>

Opcode set to allow when running in Safe mode.

=item * B<<< WEBDYNE_EVAL_USE_STRICT ('use strict qw(vars)') >>>

Prefix eval code with strict pragma via this string

=item * B<<< WEBDYNE_STRICT_VARS (1) >>>

Use strict variable checking. If any variables are referenced which are not populated in a render(variable=><value>) call an error will thrown.

=item * B<<< WEBDYNE_AUTOLOAD_POLLUTE (0) >>>

Pollute WebDyne class with method references for minor speedup. Saves AUTOLOAD trying to find method in call stack but at the price of potentially clashing with an inbuilt method. Use with care.

=item * B<<< WEBDYNE_DUMP_FLAG (0) >>>

Flag to display current CGI value and other information if <dump> tag is used.

=item * B<<< WEBDYNE_CONTENT_TYPE_HTML ('text/html') >>>

Content-type header for text/html.

=item * B<<< WEBDYNE_CONTENT_TYPE_PLAIN ('text/plain') >>>

Content-type header for text/plain.

=item * B<<< WEBDYNE_CONTENT_TYPE_JSON ('application/json') >>>

Content-type header for text/json

=item * B<<< WEBDYNE_SCRIPT_TYPE_EXECUTABLE_HR >>>

Script types which are executable on the browser and won't have substitution imposed on variables that match WebDyne syntax (e.g. ${foo}). includes:

=over

=item * text/javascript

=item * application/javascript

=item * module

=back

=item * B<<< WEBDYNE_HTML_CHARSET ('UTF-8') >>>

Character set for HTML.

=item * B<<< WEBDYNE_DTD ('<!DOCTYPE html>') >>>

DTD to use when generating HTML.

=item * B<<< WEBDYNE_META ({charset => 'UTF-8', viewport' => 'width=device-width, initial-scale=1.0'}) >>>

Meta information for HTML

=item * B<<< WEBDYNE_CONTENT_TYPE_HTML_META (0) >>>

Include a Content-Type meta tag.

=item * B<<< WEBDYNE_HTML_PARAM ({lang => 'en'}) >>>

Default <html> tag parameter attributes

=item * B<<< WEBDYNE_START_HTML_PARAM () >>>

Default attributes for any <start_html> tags, e.g. include_style=>['foo.css', 'bar.css']. These will be inserted automatically into any start_html tag seen in any .psp page.

=item * B<<< WEBDYNE_START_HTML_PARAM_STATIC (1) >>>

Make include/other sections in start_html tag static, i.e. load them at compile time and they never change. Make undef to force re-include every page load

=item * B<<< WEBDYNE_HEAD_INSERT () >>>

Anything that should be added in <head> section. Will be inserted verbatim before </head>. No interpolation or variables, simple text string only. Useful for setting global stylesheet, e.g. <link href="https://cdn.jsdelivr.net/npm/water.css@2/out/water.css" rel="stylesheet">. Will be added to all <head> sections
 universally.

=item * B<<< WEBDYNE_COMPILE_IGNORE_WHITESPACE (1) >>>

Ignore ignorable whitespace in compile.

=item * B<<< WEBDYNE_COMPILE_NO_SPACE_COMPACTING (0) >>>

Disable space compacting in compile.

=item * B<<< WEBDYNE_COMPILE_P_STRICT (1) >>>

Use strict parsing in compile.

=item * B<<< WEBDYNE_COMPILE_IMPLICIT_BODY_P_TAG (1) >>>

Implicitly add <body> and <p> tags in compile

=item * B<<< WEBDYNE_STORE_COMMENTS (1) >>>

Store and render comments.

=item * B<<< WEBDYNE_NO_CACHE (1) >>>

Send no-cache headers.

=item * B<<< WEBDYNE_WARNINGS_FATAL (0) >>>

Treat any warnings as fatal errors.

=item * B<<< WEBDYNE_CGI_DISABLE_UPLOADS (0) >>>

Disable CGI uploads. They are enabled by defaults

=item * B<<< WEBDYNE_CGI_POST_MAX (524288) >>>

Max post size for CGI (512KB).

=item * B<<< WEBDYNE_CGI_PARAM_EXPAND (1) >>>

Expand CGI parameters found in CGI names.

=item * B<<< WEBDYNE_CGI_AUTOESCAPE (0) >>>

Disable CGI autoescape of form fields.

=item * B<<< WEBDYNE_ERROR_TEXT (0) >>>

Use text errors rather than HTML.

=item * B<<< WEBDYNE_ERROR_SHOW (1) >>>

Show errors.

=item * B<<< WEBDYNE_ERROR_SHOW_EXTENDED (0) >>>

Show extended error information, including backtraces and source code

=item * B<<< WEBDYNE_ERROR_SOURCE_CONTEXT_SHOW (1) >>>

Show error source file context.

=item * B<<< WEBDYNE_ERROR_SOURCE_CONTEXT_LINES_PRE (4) >>>

Number of lines to show before error context.

=item * B<<< WEBDYNE_ERROR_SOURCE_CONTEXT_LINES_POST (4) >>>

Number of lines to show after error context.

=item * B<<< WEBDYNE_ERROR_SOURCE_CONTEXT_LINE_FRAGMENT_MAX (80) >>>

Max length of source line to show in output.

=item * B<<< WEBDYNE_ERROR_SOURCE_FILENAME_SHOW (1) >>>

Show filename in error output.

=item * B<<< WEBDYNE_ERROR_BACKTRACE_SHOW (1) >>>

Show backtrace in error output.

=item * B<<< WEBDYNE_ERROR_BACKTRACE_SHORT (0) >>>

Show brief backtrace.

=item * B<<< WEBDYNE_ERROR_EVAL_CONTEXT_SHOW (1) >>>

Show eval trace in error output.

=item * B<<< WEBDYNE_ERROR_CGI_PARAM_SHOW (1) >>>

Show CGI parameters in error output.

=item * B<<< WEBDYNE_ERROR_ENV_SHOW (1) >>>

Show environment variables in error output.

=item * B<<< WEBDYNE_ERROR_WEBDYNE_CONSTANT_SHOW (1) >>>

Show WebDyne constants in error output.

=item * B<<< WEBDYNE_ERROR_URI_SHOW (1) >>>

Show URI in error output.

=item * B<<< WEBDYNE_ERROR_VERSION_SHOW (1) >>>

Show version in error output.

=item * B<<< WEBDYNE_ERROR_EVAL_TEXT_IX (0) >>>

Index for error eval text.

=item * B<<< WEBDYNE_ERROR_SHOW_ALTERNATE` ('error display disabled - enable WEBDYNE_ERROR_SHOW to show errors, or review web server error log.') >>>

Alternate error message if error display is disabled.

=item * B<<< WEBDYNE_HTML_DEFAULT_TITLE ('Untitled Document') >>>

Default title for HTML documents.

=item * B<<< WEBDYNE_HTML_TINY_MODE ('html') >>>

Mode for HTML::Tiny object used for generating output (XML or HTML).

=item * B<<< WEBDYNE_RELOAD (0) >>>

Development mode - recompile loaded modules.

=item * B<<< WEBDYNE_JSON_CANONICAL (1) >>>

Use JSON canonical mode.

=item * B<<< WEBDYNE_HTTP_HEADER (<HashRef>) >>>

Default HTTP response headers to send. Includes:

=over

=item * Content-type: text/html; charset=UTF-8

=item * Cache-Control: no-cache, no-store, must-revalidate

=item * Pragma: no-cache

=item * Expires: 0

=item * X-Content-Type-Options: nosniff

=item * X-Frame-Options: SAMEORIGIN

=back

=item * B<<< WEBDYNE_API_ENABLE (1) >>>

Enable support for the <api> tag. Will cause slight slow-down as routes are converted to .psp file names. Enabled by default.

=item * B<<< WEBDYNE_ALPINE_VUE_ATTRIBUTE_HACK_ENABLE ('x-on') >>>

Converts @click="dosomething()" attributes to x-on:click="dosomething()" in tags as HTML::Parser does not support the '@' character in tag attributes.

=item * B<<< WEBDYNE_HTTP_HEADER_AJAX_HR ({ hx-request=>1, x-alpine-request=>1 }) >>>

List of HTTP request headers that denote the request is part of an AJAX (e.g. HTMX) request and only partial HTML response is required.

=item * B<<< WEBDYNE_PSGI_STATIC (1) >>>

Allow the PSGI module to serve static content (css files etc.)

=item * B<<< WEBDYNE_PSP_EXT (.psp) >>>

Extension for .psp pages. Do not change unless you know what you are doing.

=item * B<<< WEBDYNE_MIME_TYPE_HR (<HashRef>) >>>

Very minimal MIME type hash used by lookup_file function. See file for default content, usual definitions for text, images, style-sheets, PDF etc.

=item * B<<< WEBDYNE_DIR_CONFIG () >>>

Hash ref that contains location based hierarchy of configuration variables similar to that returned by Apache mod_perl dir_config module. See test (t) directory in source for example.

=item * B<<< WEBDYNE_DIR_CONFIG_CWD_LOAD (1) >>>

Enable loading of WEBDYNE_DIR_CONFIG hash ref from the current .psp file working directory if a .webdyne.conf.pl file is present.

=item * B<<< WEBDYNE_CONF_HR (<HashRef>) >>>

Read-only value as hash reference showing location of files used to create the values for constants in this module.

=item * B<<< MP2 (mod_perl version) >>>

Mod_perl level. Auto-detected, do not change unless you know what you are doing.

=item * B<<< MOD_PERL (mod_perl version) >>>

Mod_perl environment runtime detected. Do not change unless you know what you are doing

=back

=cut