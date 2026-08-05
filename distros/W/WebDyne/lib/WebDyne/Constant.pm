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
use File::Basename qw(dirname);
use Data::Dumper;
$Data::Dumper::Indent=1;
require Opcode;


#  Version information
#
$VERSION='3.008';


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
    WEBDYNE_EVAL_USE_STRICT => 'use strict qw(vars)',
    
    
    #  Anything to prepend after use strict
    #
    WEBDYNE_EVAL_PREPEND => '',


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
    
    
    #  Shortcut attributes for start_html. Use with convention <start_html pico title="My Title"> to use
    #
    WEBDYNE_START_HTML_SHORTCUT_HR => {
    
        pico    => { style  => 'https://cdn.jsdelivr.net/npm/@picocss/pico@latest/css/pico.min.css' },
        htmx    => { script => 'https://cdn.jsdelivr.net/npm/htmx.org@latest/dist/htmx.min.js' },
        alpine	=> { script => 'https://cdn.jsdelivr.net/npm/alpinejs@latest/dist/cdn.min.js#defer' }
        
        #  Commented out for now, left as syntax examples
        #

        #bootstrap	=> { 
        #    style => 'https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css', 
        #    script => 'https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/js/bootstrap.bundle.min.js' 
        #},
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
    #  Will be added to all <head> sections universally. Default is to inline webdyne.css so don't need to
    #  worry about where docroot is, enabling static file load etc. Just null out with
    #
    #  WEBDYNE_HEAD_INSERT => undef,
    #
    #  To disable.
    #
    WEBDYNE_HEAD_INSERT => sprintf('<style>%s</style>', do {
        local $/;
        my $style_fn=&fullpath('webdyne.css');
        open my $fh, '<', $style_fn
            or die sprintf('unable to read default stylesheet %s: %s', $style_fn, $!);
        <$fh>;
    }),
    

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
        Hx-Request
        X-Alpine-Request
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
    #WEBDYNE_PSGI_STATIC => 1,
    
    
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
    
    
    #  PAGI loaded ?
    #
    WEBDYNE_PAGI => $INC{'WebDyne/PAGI.pm'} ? 1 : 0,
    

    #  PSGI loaded ?
    #
    WEBDYNE_PSGI => $INC{'WebDyne/PSGI.pm'} ? 1 : 0,
    
    
    #  Indexer and test, style files
    #
    WEBDYNE_DEFAULT_TEST_FN  => &fullpath('time.psp'),
    WEBDYNE_DEFAULT_INDEX_FN => &fullpath('index.psp'),
    WEBDYNE_DEFAULT_STYLE_FN => &fullpath('webdyne.css'),

    
    #  Mod_perl level. Do not change unless you know what you are
    #  doing.
    #
    MP2      => $MP2,
    MOD_PERL => $MP_version,


);


sub fullpath {


    #  Test file to use if no DOCUMENT_ROOT found
    #
    my ($fn, $dn)=@_;
    $dn ||= dirname(__FILE__);
    return File::Spec->rel2abs(File::Spec->catfile($dn, $fn));
    
}


sub local_constant_fn {


    #  Where local constants reside
    #
    my @local_constant_fn;
    my $local_constant_fn=$Constant{'WEBDYNE_CONF_FN'};
    if ($^O=~/MSWin[32|64]/) {
        my $dn=$ENV{'WEBDYNE_HOME'} || $ENV{'WEBDYNE'} || $ENV{'WINDIR'};
        push @local_constant_fn, (exists $ENV{'WEBDYNE_CONF'} ? $ENV{'WEBDYNE_CONF'} : 
            File::Spec->catfile($dn, $local_constant_fn))
    }
    else {
        push @local_constant_fn, ($ENV{'WEBDYNE_CONF'} || 
            File::Spec->catfile(
                File::Spec->rootdir(), 'etc', $local_constant_fn
        ))
    }
    unless ($ENV{'WEBDYNE_CONF'}) {
        push @local_constant_fn, (my ($fn)=glob(sprintf('~/.%s', $local_constant_fn)));
        debug("push fn: $fn onto local_constant_fn: %s, env: %s", Dumper(\@local_constant_fn, \%ENV));
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
        #  Dump all constants
        $dump_fg++;
        $local_constant_fn=undef;
    }
    elsif ($dump_fg=exists($Constant{$local_constant_fn}) ? $local_constant_fn : undef) {
        #  Dump one constant value
        #
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
            if (0 && (my $var_test= (keys(%{$constant_hr}))[0])) {
                debug("picking var: $var_test as test, exists *{${caller}::${var_test}}: %s", defined(*{"${caller}::${var_test}"}));
                if ($Package{'caller'}{$caller}{$constant_hr}++ && defined(*{"${caller}::${var_test}"})) {
                    debug("skip, already applied $constant_hr to caller: $caller");
                    #next;
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
                #if (defined($constant_hr->{$k}) && ($constant_hr ne $class_constant_hr)) {
                if (defined($constant_hr->{$k}) && ($constant_hr->{$k} ne $class_constant_hr->{$k})) {
                
                    #  Yes
                    #
                    debug('override constant_hr: %s value: %s with file value: %s', $k, $v, $constant_hr->{$k});
                    $v=$class_constant_hr->{$k}=$constant_hr->{$k};

                }
                debug("caller: $caller, class: $class  set: $k=%s", defined($v) ? $v : q[]);


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
                #debug("caller: $caller, set:$k value:$v");
                #next if ref($v); # Not needed, stop Regexp conversion
                if ($v=~/^\d+$/) {
                    #debug("using sub() ${caller}::${k}=$v");
                    *{"${caller}::${k}"}=eval("sub () { $v }");
                }
                else {
                    #debug("fall through, using sub() ${caller}::${k}=q($v)");
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
        CORE::print exists($Constant{$dump_fg}) ? Dumper($class_constant_hr->{$dump_fg}) : Dumper($class_constant_hr);
        exit 0;
    }
    
}


1;


__END__

=begin markdown

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

=end markdown


=head1 WebDyne::Constant


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

This module provides a list of configuration constants used in the WebDyne code. These constants are used to configure the behavior of the WebDyne module and can be accessed by importing the module and referencing the constants by name. Constants can be configured to different values by overriding values in local configuration files, setting environment
 variables, command line options, or Apache directives.

Common uses for modifying constant values allow for:

=over

=item *

Changing default language from en-US to something else.



=item *

Modifying or adding new meta-data or default headers to output



=item *

Adding default style-sheets or other inclusions to all output files



=back

Default values for these configuration constants can be updated the following locations:

=over

=item 1.

/etc/webdyne.conf.pl



=item 2.

$HOME/.webdyne.conf.pl



=item 3.

$DOCUMENT_ROOT/.webdyne.conf.pl



=back

As a special case when running under PSGI environments, if WEBDYNE_DIR_CONFIG_CWD_LOAD is true (which it is by default) then each directory that a .psp file is run from is checked for the .webdyne.conf.pl file - but only WEBDYNE_DIR_CONFIG entries from the file are loaded. This allows for configuration of settings such a WebDyneChain modules to load, WebDyneTemplate
 configuration etc. on a per directory basis

The WebDyne::Constant module is sub-classed by other WebDyne modules, and the values for any constants in the WebDyne::E<lt>ModuleE<gt>::Constant family of modules can be overridden by creating or updating one of the above configuration files. Here is a sample configuration file:


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
=over 2

B<WARNING>

Ensure the configuration file has the correct syntax by checking the Perl interpreter doesnE<#39>t throw any errors. Use  C<perl -c -w>  to check syntax:

    # perl -c -w /etc/webdyne.conf.pl
    /etc/webdyne.conf.pl syntax OK
    # perl -c -w ~/.webdyne.conf.pl
    /home/<user>/.webdyne.conf.pl OK

=back


=head1 CONSTANTS

The constants below are defined by C<WebDyne::Constant>. Each definition includes a short default description. Unless marked read-only or internal, constants can be overridden through normal WebDyne configuration loading, environment variables, command line options, or Apache directives.

=over

=item *

B<WEBDYNE_NODE_NAME_IX>

B<Default:> C<0>

Internal read-only index for the node name slot in WebDyne's compiled node array structure. Do not change.



=item *

B<WEBDYNE_NODE_ATTR_IX>

B<Default:> C<1>

Internal read-only index for the node attribute slot in WebDyne's compiled node array structure. Do not change.



=item *

B<WEBDYNE_NODE_CHLD_IX>

B<Default:> C<2>

Internal read-only index for the child-node slot in WebDyne's compiled node array structure. Do not change.



=item *

B<WEBDYNE_NODE_SBST_IX>

B<Default:> C<3>

Internal read-only index for the substitution slot in WebDyne's compiled node array structure. Do not change.



=item *

B<WEBDYNE_NODE_LINE_IX>

B<Default:> C<4>

Internal read-only index for the source line slot in WebDyne's compiled node array structure. Do not change.



=item *

B<WEBDYNE_NODE_LINE_TAG_END_IX>

B<Default:> C<5>

Internal read-only index for the source tag-end line slot in WebDyne's compiled node array structure. Do not change.



=item *

B<WEBDYNE_NODE_SRCE_IX>

B<Default:> C<6>

Internal read-only index for the source text slot in WebDyne's compiled node array structure. Do not change.



=item *

B<WEBDYNE_CONTAINER_META_IX>

B<Default:> C<0>

Internal read-only index for the metadata slot in WebDyne's compiled page container structure. Do not change.



=item *

B<WEBDYNE_CONTAINER_DATA_IX>

B<Default:> C<1>

Internal read-only index for the data slot in WebDyne's compiled page container structure. Do not change.



=item *

B<WEBDYNE_CACHE_DN>

B<Default:> See the command below for the value.


 perl -MWebDyne::Constant=WEBDYNE_CACHE_DN
Directory used to store compiled page cache files. Installer and server wrappers normally set this to a writable cache directory. The directory must exist and be writable by the web server process. If unset, WebDyne may fall back to runtime-specific temporary locations.



=item *

B<WEBDYNE_STARTUP_CACHE_FLUSH>

B<Default:> C<1>

Remove existing disk cache files at startup so PSP files are recompiled after restart and then cached again when first viewed. Set to 0 to keep disk cache files across restarts.



=item *

B<WEBDYNE_CACHE_CHECK_FREQ>

B<Default:> C<256>

Per-process request interval used to trigger memory cache housekeeping.



=item *

B<WEBDYNE_CACHE_HIGH_WATER>

B<Default:> C<64>

Maximum number of compiled pages to keep in memory before cache housekeeping removes entries.



=item *

B<WEBDYNE_CACHE_LOW_WATER>

B<Default:> C<32>

Target number of compiled pages to retain after memory cache housekeeping runs.



=item *

B<WEBDYNE_CACHE_CLEAN_METHOD>

B<Default:> C<1>

Memory cache cleanup method. C<0> removes entries by oldest last-use time; C<1> removes least-used entries first.



=item *

B<WEBDYNE_EVAL_SAFE>

B<Default:> C<0>

Run dynamic PSP code in a C<Safe> compartment instead of direct Perl eval. Safe mode is experimental and not recommended as a security boundary.



=item *

B<WEBDYNE_EVAL_USE_STRICT>

B<Default:> C<'use strict qw(vars)'>

Perl source prepended before generated eval code to enable strict variable checking. Set to C<undef> to disable this strict pragma. In Safe mode this behaves as a strict on/off flag rather than arbitrary source text.



=item *

B<WEBDYNE_EVAL_PREPEND>

B<Default:> C<''>

Perl source text prepended to generated eval code after C<WEBDYNE_EVAL_USE_STRICT>. Use conservatively because it affects interpreted PSP code globally.



=item *

B<WEBDYNE_EVAL_SAFE_OPCODE_AR>

B<Default:> array reference containing C<:default>

Opcode set allowed when C<WEBDYNE_EVAL_SAFE> is enabled. Ignored when direct eval mode is used. Use C<Opcode::full_opset()> for the full opcode set if Safe mode is enabled and you explicitly want to allow all Perl opcodes.



=item *

B<WEBDYNE_STRICT_VARS>

B<Default:> C<1>

Check render variables referenced as C<${name}> and raise an error when a referenced variable was not supplied to C<render()> or C<render_block()>, or was supplied as C<undef>.



=item *

B<WEBDYNE_AUTOLOAD_POLLUTE>

B<Default:> C<0>

Cache dynamically found method references in the C<WebDyne> namespace to avoid repeated C<AUTOLOAD> lookup. This can improve some workloads but risks method-name clashes, so it should only be used in controlled environments.



=item *

B<WEBDYNE_DUMP_FLAG>

B<Default:> C<0>

Enable output from the special C<<< <dump> >>> tag, mainly for form and request debugging.



=item *

B<WEBDYNE_HTML_CHARSET>

B<Default:> C<'UTF-8'>

Default character set used for generated content types and default HTML metadata.



=item *

B<WEBDYNE_CONTENT_TYPE_HTML>

B<Default:> C<'text/html'>

Base content type for HTML responses.



=item *

B<WEBDYNE_CONTENT_TYPE_HTML_ENCODED>

B<Default:> C<'text/html; charset=UTF-8'>

Encoded HTML content type including the configured character set.



=item *

B<WEBDYNE_CONTENT_TYPE_TEXT>

B<Default:> C<'text/plain'>

Base content type for plain text responses.



=item *

B<WEBDYNE_CONTENT_TYPE_TEXT_ENCODED>

B<Default:> C<'text/plain; charset=UTF-8'>

Encoded plain text content type including the configured character set.



=item *

B<WEBDYNE_CONTENT_TYPE_JSON>

B<Default:> C<'application/json'>

Base content type for JSON responses.



=item *

B<WEBDYNE_CONTENT_TYPE_JSON_ENCODED>

B<Default:> C<'application/json; charset=UTF-8'>

Encoded JSON content type including the configured character set.



=item *

B<WEBDYNE_SCRIPT_TYPE_EXECUTABLE_HR>

B<Default:> See the command below for the value.


 perl -MWebDyne::Constant=WEBDYNE_SCRIPT_TYPE_EXECUTABLE_HR
Hash reference of script MIME types where WebDyne variable substitution is suppressed by default so JavaScript syntax such as C<${name}> is not interpreted as WebDyne substitution.



=item *

B<WEBDYNE_DTD>

B<Default:> C<<< '<!DOCTYPE html>' >>>

Document type emitted by generated HTML helpers.



=item *

B<WEBDYNE_META>

B<Default:> See the command below for the value.


 perl -MWebDyne::Constant=WEBDYNE_META
Default metadata emitted by C<<< <start_html> >>>. Defaults include a UTF-8 charset declaration and a responsive viewport declaration.



=item *

B<WEBDYNE_CONTENT_TYPE_HTML_META>

B<Default:> C<0>

Include a Content-Type C<<< <meta> >>> tag in generated HTML output.



=item *

B<WEBDYNE_HTML_PARAM>

B<Default:> hash reference containing C<<< lang => 'en' >>>

Default attributes applied to the generated C<<< <html> >>> tag; the default contains C<<< lang => 'en' >>>.



=item *

B<WEBDYNE_START_HTML_PARAM>

B<Default:> empty hash reference

Hash reference of default attributes applied to every C<<< <start_html> >>> tag, such as global scripts, styles, metadata, or include files. Explicit C<<< <start_html> >>> attributes can override these defaults.



=item *

B<WEBDYNE_START_HTML_PARAM_STATIC>

B<Default:> C<1>

Controls whether include-style values supplied through C<<< <start_html> >>> defaults are loaded at compile time and reused. Set to 0 or C<undef> when included content should be re-read on each page load.



=item *

B<WEBDYNE_START_HTML_SHORTCUT_HR>

B<Default:> See the command below for the value.


 perl -MWebDyne::Constant=WEBDYNE_START_HTML_SHORTCUT_HR
Shortcut attribute mappings for C<<< <start_html> >>>. Defaults include C<pico>, C<htmx>, and C<alpine>, which expand to stylesheet or script includes.



=item *

B<WEBDYNE_HEAD_INSERT>

B<Default:> See the command below for the value.


 perl -MWebDyne::Constant=WEBDYNE_HEAD_INSERT
HTML inserted verbatim before C<<< </head> >>> in generated pages. The value must be valid HTML for the document head and is not interpreted, interpolated, or compiled by WebDyne. By default WebDyne inlines its bundled C<webdyne.css> stylesheet. Set to C<undef> to disable default stylesheet insertion.



=item *

B<WEBDYNE_COMPILE_IGNORE_WHITESPACE>

B<Default:> C<1>

Ignore ignorable source whitespace during HTML tree compilation, corresponding to the HTML::TreeBuilder C<ignore_ignorable_whitespace> behaviour.



=item *

B<WEBDYNE_COMPILE_NO_SPACE_COMPACTING>

B<Default:> C<0>

Disable HTML::TreeBuilder-style source whitespace compacting during compilation, corresponding to the HTML::TreeBuilder C<no_space_compacting> behaviour.



=item *

B<WEBDYNE_COMPILE_P_STRICT>

B<Default:> C<1>

Controls parser strictness for paragraph handling during compilation.



=item *

B<WEBDYNE_COMPILE_IMPLICIT_BODY_P_TAG>

B<Default:> C<1>

Controls whether implicit body and paragraph tags are generated during compilation.



=item *

B<WEBDYNE_STORE_COMMENTS>

B<Default:> C<1>

Store and render comments from source files. Set to 0 to suppress comment output.



=item *

B<WEBDYNE_NO_CACHE>

B<Default:> C<1>

Send no-cache response headers by default. This can be changed globally or cleared for a page through the C<no_cache()> method.



=item *

B<WEBDYNE_WARNINGS_FATAL>

B<Default:> C<0>

Treat Perl warnings from interpreted code as fatal WebDyne errors. When enabled, a C<warn()> behaves as if C<die()> had been called.



=item *

B<WEBDYNE_CGI_DISABLE_UPLOADS>

B<Default:> C<0>

Disable CGI file uploads. Uploads are allowed by default.



=item *

B<WEBDYNE_CGI_POST_MAX>

B<Default:> C<524288>

Maximum accepted POST body size for CGI processing, in bytes. The default is 512 KiB.



=item *

B<WEBDYNE_CGI_PARAM_EXPAND>

B<Default:> C<1>

Expand CGI parameter strings embedded in parameter values into separate CGI parameters.



=item *

B<WEBDYNE_CGI_AUTOESCAPE>

B<Default:> C<0>

Controls automatic escaping of CGI form field values before they are rendered back into generated form elements.



=item *

B<WEBDYNE_ERROR_TEXT>

B<Default:> C<0>

Display simplified plain-text errors instead of the HTML error handler. This is mainly useful for WebDyne development and command-line/server wrapper diagnostics.



=item *

B<WEBDYNE_ERROR_SHOW>

B<Default:> C<1>

Display the primary error message in the HTML error handler.



=item *

B<WEBDYNE_ERROR_SHOW_EXTENDED>

B<Default:> C<0>

Enable extended HTML error output. The granular error constants below determine which source, backtrace, environment, CGI, and internal details are shown.



=item *

B<WEBDYNE_ERROR_SOURCE_CONTEXT_SHOW>

B<Default:> C<1>

Show a fragment of the PSP source file around the error location when extended HTML error output is enabled.



=item *

B<WEBDYNE_ERROR_SOURCE_CONTEXT_LINES_PRE>

B<Default:> C<4>

Number of source lines before the error location to show.



=item *

B<WEBDYNE_ERROR_SOURCE_CONTEXT_LINES_POST>

B<Default:> C<4>

Number of source lines after the error location to show.



=item *

B<WEBDYNE_ERROR_SOURCE_CONTEXT_LINE_FRAGMENT_MAX>

B<Default:> C<80>

Maximum source line length to show in error output. Set to 0 for unlimited length.



=item *

B<WEBDYNE_ERROR_SOURCE_FILENAME_SHOW>

B<Default:> C<1>

Show the source filename in extended HTML error output.



=item *

B<WEBDYNE_ERROR_SOURCE_FILENAME_FULL>

B<Default:> C<0>

Show the full filesystem path for the source filename in extended HTML error output.



=item *

B<WEBDYNE_ERROR_BACKTRACE_SHOW>

B<Default:> C<1>

Show a backtrace of modules through which the error propagated in extended HTML error output.



=item *

B<WEBDYNE_ERROR_BACKTRACE_SHORT>

B<Default:> C<0>

Remove WebDyne internal modules from the displayed backtrace.



=item *

B<WEBDYNE_ERROR_BACKTRACE_FULL>

B<Default:> C<0>

Show the full backtrace, including frames normally skipped such as eval and anonymous subroutine frames.



=item *

B<WEBDYNE_ERROR_EVAL_CONTEXT_SHOW>

B<Default:> C<1>

Show generated eval context around an error when extended HTML error output is enabled.



=item *

B<WEBDYNE_ERROR_CGI_PARAM_SHOW>

B<Default:> C<1>

Show CGI parameters in extended HTML error output.



=item *

B<WEBDYNE_ERROR_ENV_SHOW>

B<Default:> C<1>

Show environment variables in extended HTML error output.



=item *

B<WEBDYNE_ERROR_WEBDYNE_CONSTANT_SHOW>

B<Default:> C<1>

Show WebDyne constants in extended HTML error output.



=item *

B<WEBDYNE_ERROR_URI_SHOW>

B<Default:> C<1>

Show request URI information in extended HTML error output.



=item *

B<WEBDYNE_ERROR_VERSION_SHOW>

B<Default:> C<1>

Show WebDyne version information in extended HTML error output.



=item *

B<WEBDYNE_ERROR_INTERNAL_SHOW>

B<Default:> C<0>

Show internal error-handler state in extended HTML error output.



=item *

B<WEBDYNE_ERROR_SHOW_ALTERNATE>

B<Default:> C<'error display disabled - enable WEBDYNE_ERROR_SHOW to show errors, or review web server error log.'>

Alternate message displayed when HTML error display is disabled with C<WEBDYNE_ERROR_SHOW>.



=item *

B<WEBDYNE_HTML_DEFAULT_TITLE>

B<Default:> C<'Untitled Document'>

Default document title emitted by C<<< <start_html> >>> when no title is supplied.



=item *

B<WEBDYNE_HTML_TINY_MODE>

B<Default:> C<'html'>

Controls whether the HTML helper emits HTML-style or XML-style output.



=item *

B<WEBDYNE_RELOAD>

B<Default:> C<0>

Development-mode switch that forces cached compiled pages to be recompiled.



=item *

B<WEBDYNE_JSON_CANONICAL>

B<Default:> C<1>

Enable canonical JSON output by default, preserving stable key ordering where the encoder supports it. Canonical output can be slightly slower.



=item *

B<WEBDYNE_JSON_PRETTY>

B<Default:> C<0>

Enable pretty-printed JSON output for C<<< <json> >>> tags unless overridden by a tag attribute.



=item *

B<WEBDYNE_API_ENABLE>

B<Default:> C<1>

Enable processing of C<<< <api> >>> routes in PSGI request handling. Set to 0 to disable API route dispatch.



=item *

B<WEBDYNE_ALPINE_VUE_ATTRIBUTE_HACK_ENABLE>

B<Default:> C<'x-on'>

Rewrite shorthand attributes beginning with C<@>, such as C<@click>, into parser-safe attributes because the HTML parser does not recognise C<@> as a valid attribute character. The default rewrites them to Alpine-style C<x-on:> attributes; set a different prefix such as C<v-on:> for Vue-style output.



=item *

B<WEBDYNE_HTTP_HEADER_AJAX_HR>

B<Default:> See the command below for the value.


 perl -MWebDyne::Constant=WEBDYNE_HTTP_HEADER_AJAX_HR
Hash reference of HTTP request header names used to detect htmx or Alpine Ajax style partial requests. Matching requests can receive partial HTML output, such as the page body only or a matching C<<< <htmx> >>> fragment.



=item *

B<WEBDYNE_HTTP_HEADER_AJAX_AR>

B<Default:> See the command below for the value.


 perl -MWebDyne::Constant=WEBDYNE_HTTP_HEADER_AJAX_AR
Array reference form of the AJAX request header names derived from C<WEBDYNE_HTTP_HEADER_AJAX_HR>.



=item *

B<WEBDYNE_HTMX_FORCE>

B<Default:> C<0>

Force htmx-oriented partial rendering behaviour even when the request does not contain an AJAX request header. This is equivalent to setting C<force=1> on all C<<< <htmx> >>> tags.



=item *

B<WEBDYNE_HTTP_HEADER>

B<Default:> See the command below for the value.


 perl -MWebDyne::Constant=WEBDYNE_HTTP_HEADER
Hash reference of default HTTP response headers sent with WebDyne responses. Defaults include Content-Type, Cache-Control, Pragma, Expires, X-Content-Type-Options, and X-Frame-Options.



=item *

B<WEBDYNE_PSP_EXT>

B<Default:> C<'.psp'>

Default extension used to identify interpreted WebDyne PSP files.



=item *

B<WEBDYNE_PSP_EXT_RE>

B<Default:> See the command below for the value.


 perl -MWebDyne::Constant=WEBDYNE_PSP_EXT_RE
Regular expression form of C<WEBDYNE_PSP_EXT>, used internally for matching PSP filenames.



=item *

B<WEBDYNE_MIME_TYPE_HR>

B<Default:> See the command below for the value.


 perl -MWebDyne::Constant=WEBDYNE_MIME_TYPE_HR
Hash reference of file extensions and MIME types used when WebDyne identifies static file content types.



=item *

B<WEBDYNE_INDEX_EXT_ALLOWED_HR>

B<Default:> See the command below for the value.


 perl -MWebDyne::Constant=WEBDYNE_INDEX_EXT_ALLOWED_HR
Hash reference of source-code file extensions that the default directory indexer may open for viewing, in addition to recognised static file types.



=item *

B<WEBDYNE_INDEX_FN_ALLOWED_HR>

B<Default:> See the command below for the value.


 perl -MWebDyne::Constant=WEBDYNE_INDEX_FN_ALLOWED_HR
Hash reference of literal file names that the default directory indexer may open for viewing, in addition to recognised static file types.



=item *

B<WEBDYNE_DIR_CONFIG>

B<Default:> C<undef>

Hash reference used by non-Apache request layers to provide Apache-style directory configuration values such as C<WebDyneHandler>, C<WebDyneChain>, and C<WebDyneTemplate>.



=item *

B<WEBDYNE_DIR_CONFIG_CWD_LOAD>

B<Default:> C<1>

Controls whether PSGI-style local request handling attempts to load C<WEBDYNE_DIR_CONFIG> values from a C<.webdyne.conf.pl> file in the current PSP directory.



=item *

B<WEBDYNE_CONF_HR>

B<Default:> C<undef>

Read-only marker populated by local configuration loading with information about configuration files that contributed constant values.



=item *

B<WEBDYNE_CONF_FN>

B<Default:> C<'webdyne.conf.pl'>

Default configuration filename searched by local configuration loading.



=item *

B<WEBDYNE_HTML_TIDY>

B<Default:> C<0>

Enable optional HTML::Tidy5 cleanup of rendered output where supported by the rendering path. Requires HTML::Tidy5 and its dependencies to be installed.



=item *

B<WEBDYNE_HTML_TIDY_CONFIG_HR>

B<Default:> See the command below for the value.


 perl -MWebDyne::Constant=WEBDYNE_HTML_TIDY_CONFIG_HR
Hash reference of HTML::Tidy5 options used when C<WEBDYNE_HTML_TIDY> is enabled.



=item *

B<WEBDYNE_HTML_NEWLINE>

B<Default:> C<0>

Add extra newline characters to generated HTML output.



=item *

B<WEBDYNE_PAGI>

B<Default:> See the command below for the value.


 perl -MWebDyne::Constant=WEBDYNE_PAGI
Read-only flag indicating whether the PAGI support module is loaded.



=item *

B<WEBDYNE_PSGI>

B<Default:> See the command below for the value.


 perl -MWebDyne::Constant=WEBDYNE_PSGI
Read-only flag indicating whether the PSGI support module is loaded.



=item *

B<WEBDYNE_DEFAULT_TEST_FN>

B<Default:> See the command below for the value.


 perl -MWebDyne::Constant=WEBDYNE_DEFAULT_TEST_FN
Absolute path to the built-in WebDyne test page.



=item *

B<WEBDYNE_DEFAULT_INDEX_FN>

B<Default:> See the command below for the value.


 perl -MWebDyne::Constant=WEBDYNE_DEFAULT_INDEX_FN
Absolute path to the built-in WebDyne directory index page.



=item *

B<WEBDYNE_DEFAULT_STYLE_FN>

B<Default:> See the command below for the value.


 perl -MWebDyne::Constant=WEBDYNE_DEFAULT_STYLE_FN
Absolute path to the bundled default C<webdyne.css> stylesheet.



=item *

B<MP2>

B<Default:> See the command below for the value.


 perl -MWebDyne::Constant=MP2
Read-only mod_perl major-version flag.



=item *

B<MOD_PERL>

B<Default:> See the command below for the value.


 perl -MWebDyne::Constant=MOD_PERL
Read-only mod_perl runtime version value.



=back

=cut
