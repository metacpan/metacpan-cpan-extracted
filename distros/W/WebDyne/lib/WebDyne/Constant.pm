#
#  This file is part of WebDyne.
#
#  This software is Copyright (c) 2017 by Andrew Speer <andrew@webdyne.org>.
#
#  This is free software, licensed under:
#
#    The GNU General Public License, Version 2, June 1991
#
#  Full license text is available at:
#
#  <http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt>
#
package WebDyne::Constant;


#  Pragma
#
use strict qw(vars);
use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT_OK @EXPORT %Constant);
use warnings;
no warnings qw(uninitialized);
local $^W=0;


#  External modules
#
use WebDyne::Base;
use File::Spec;
use Data::Dumper;
require Opcode;


#  Version information
#
$VERSION='1.248';


#  Get mod_perl version. Clear $@ after evals
#
eval     {require mod_perl2 if ($ENV{'MOD_PERL_API_VERSION'} == 2)} ||
    eval {require Apache2   if $ENV{'MOD_PERL'}=~/1.99/}            ||
    eval {require mod_perl  if $ENV{'MOD_PERL'}};
eval {undef} if $@;
my $Mod_perl_version=$mod_perl::VERSION || $mod_perl2::VERSION || $ENV{MOD_PERL_API_VERSION};
my $MP2=($Mod_perl_version > 1.99) ? 1 : 0;


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


    #  DTD to use when generating HTML
    #
    WEBDYNE_DTD =>
        '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" ' .
        '"http://www.w3.org/TR/html4/loose.dtd">',


    #  Content-type for text/html. Combined with charset to produce Content-type header
    #
    WEBDYNE_CONTENT_TYPE_HTML => 'text/html',


    #  Content-type for text/plain. As above
    #
    WEBDYNE_CONTENT_TYPE_PLAIN => 'text/plain',


    #  Encoding
    #
    WEBDYNE_CHARSET => 'ISO-8859-1',


    #  Include a Content-Type meta tag ?
    #
    WEBDYNE_CONTENT_TYPE_HTML_META => 0,


    #  Default <html> tag paramaters, eg { lang	=>'en-US' }
    #
    WEBDYNE_HTML_PARAM => undef,


    #  Ignore ignorable whitespace in compile. Play around with these settings if
    #  you don't like the formatting of the compiled HTML. See HTML::TreeBuilder
    #  man page for details here
    #
    WEBDYNE_COMPILE_IGNORE_WHITESPACE   => 1,
    WEBDYNE_COMPILE_NO_SPACE_COMPACTING => 0,


    #  Store and render comments ?
    #
    WEBDYNE_STORE_COMMENTS => 0,


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

    #  Show filename (including full filesystem path)
    WEBDYNE_ERROR_SOURCE_FILENAME_SHOW => 1,

    #  Show backtrace, show full or brief backtrace
    WEBDYNE_ERROR_BACKTRACE_SHOW  => 1,
    WEBDYNE_ERROR_BACKTRACE_SHORT => 0,

    #  Show eval trace. Uses SOURCE_CONTEXT_LINES to determine number of lines to show
    WEBDYNE_ERROR_EVAL_CONTEXT_SHOW => 1,

    #  CGI Params
    WEBDYNE_ERROR_CGI_PARAM_SHOW => 1,

    #  URI and version
    WEBDYNE_ERROR_URI_SHOW     => 1,
    WEBDYNE_ERROR_VERSION_SHOW => 1,


    #  Internal indexes for error eval handler array
    #
    WEBDYNE_ERROR_EVAL_TEXT_IX     => 0,
    WEBDYNE_ERROR_EVAL_EMBEDDED_IX => 1,
    WEBDYNE_ERROR_EVAL_LINE_NO_IX  => 2,


    #  Alternate error message if WEBDYNE_ERROR_SHOW disabled
    #
    WEBDYNE_ERROR_SHOW_ALTERNATE =>
        'error display disabled - enable WEBDYNE_ERROR_SHOW to show errors, or review web server error log.',


    #  Development mode - recompile loaded modules
    #
    WEBDYNE_RELOAD => 0,


    #  Mod_perl level. Do not change unless you know what you are
    #  doing.
    #
    MP2      => $MP2,
    MOD_PERL => $Mod_perl_version


);


sub local_constant_load {

    my ($class, $constant_hr)=@_;
    debug("class $class, constant_hr %s", Dumper($constant_hr));
    my $local_constant_cn=local_constant_cn();
    debug("local_constant_cn $local_constant_cn");
    my $local_hr=(-f $local_constant_cn) && (
        do($local_constant_cn)
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


    #  Set via environment vars first
    #
    foreach my $key (keys %{$constant_hr}) {
        if (my $val=$ENV{$key}) {
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
        $constant_hr->{'WEBDYNE_CONTENT_TYPE_PLAIN'}=sprintf("%s; charset=$charset", $constant_hr->{'WEBDYNE_CONTENT_TYPE_PLAIN'})
            unless $constant_hr->{'WEBDYNE_CONTENT_TYPE_PLAIN'}=~/charset=/;
    }


    #  Done - return constant hash ref
    #
    $constant_hr;

}


sub local_constant_cn {


    #  Where local constants reside
    #
    my $local_constant_fn='webdyne.pm';
    my $local_constant_cn;
    if ($^O=~/MSWin[32|64]/) {
        my $dn=$ENV{'WEBDYNE_HOME'} || $ENV{'WEBDYNE'} || $ENV{'WINDIR'};
        $local_constant_cn=
            File::Spec->catfile($dn, $local_constant_fn)
    }
    else {
        $local_constant_cn=File::Spec->catfile(
            File::Spec->rootdir(), 'etc', $local_constant_fn
            )
    }
    return $local_constant_cn;

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


#  Export constants to namespace, place in export tags
#
require Exporter;
@ISA=qw(Exporter);
&local_constant_load(__PACKAGE__, \%Constant);
foreach (keys %Constant) {${$_}=$Constant{$_}}
@EXPORT=map {'$' . $_} keys %Constant;
@EXPORT_OK=@EXPORT;
%EXPORT_TAGS=(all => [@EXPORT_OK]);
$_=\%Constant;
