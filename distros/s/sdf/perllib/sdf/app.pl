# $Id$
$VERSION{''.__FILE__} = '$Revision$';
#
# >>Title::     Application Framework Library
#
# >>Copyright::
# Copyright (c) 1992-1996, Ian Clatworthy (ianc@mincom.com).
# You may distribute under the terms specified in the LICENSE file.
#
# >>History::
# -----------------------------------------------------------------------
# Date      Who     Change
# 24-Oct-98 ianc    _AppConfigLibDir() Mac patch (from David Schooley)
# 29-Feb-96 ianc    SDF 2.000
# -----------------------------------------------------------------------
#
# >>Purpose::
# This library provides a common application framework
# for [[Perl]] scripts.
#
# >>Description::
# !include "app.sdf"
#
# >>Limitations::
# On MS-DOS using BigPerl v2 or v3, redirecting STDOUT after {{Y:AppProcess}}
# doesn't work.
#
# >>Resources::
# 
# >>Implementation::
#

# Save these ASAP. $_app_path is a temporary variable which is
# copied to its public counterpart ($app_path) below. $app_path is
# defined below so that $app_path, $app_dir and $app_name can
# be documented together.
$_app_start = time;
$_app_path = $0;

BEGIN {
  require "locale.pm" if $] >= 5.004;
}
require "sdf/name.pl";
require "sdf/misc.pl";
require "sdf/table.pl";

######### Constants #########

# Configuration parameters
@_APP_DETAILED_HELP = (
    'Help',
    'Type',
    'Array',
    'Parameter',
    'Initial',
    'Default',
);

#
# >>Description::
# {{Y:$APP_STDIN_ARGS}} is the pseudo argument (default '+') which
# causes standard input to be processed as a list of arguments.
# Some scripts may wish to use another symbol (i.e. '+' might
# be required as a genuine argument), or disable this behaviour
# altogether. See {{Y:AppProcess}}.
#
$APP_STDIN_ARGS = '+';

# Tables of configuration parameters, associated routines, and help
%_APP_CONFIG_FN = (
    'calltree',     "_AppConfigCallTree",
    'inifile',      "_AppConfigInifile",
    'libdir',       "_AppConfigLibDir",
    'noecho',       "_AppConfigNoEcho",
    'parts',        "_AppConfigParts",
    'product',      "_AppConfigProduct",
    'test',         "_AppConfigTest",
    'time',         "_AppConfigTime",
    'version',      "_AppConfigVersion",
);
%_APP_CONFIG_HELP = (
    'calltree',     "display call tree leading to application exit",
    'inifile',      "initialisation file to load",
    'libdir',       "library/configuration directory",
    'noecho',       "disable argument echoing",
    'parts',        "display program parts and versions",
    'product',      "product name",
    'test',         "verify outputs",
    'time',         "time program execution",
    'version',      "program version",
);


######### Variables #########

#
# >>Description::
# {{Y:$app_path}}, {{Y:$app_dir}} and {{Y:$app_name}} are the full
# pathname, directory and name of the application respectively.
#
$app_path= $_app_path;
(
$app_dir,
$app_name
) = &NameSplit($app_path);

#
# >>Description::
# {{Y:$app_lib_dir}} is the library directory for this application,
# i.e. the directory containing configuration files. The default
# value is the {{Y:$app_dir}}. This directory is typically set by
# searching the Perl library path for the {{libdir}} configuration
# parameter, if any.
#
$app_lib_dir = $app_dir;

# >>Description::
# {{Y:@app_exit_routines}} is the stack of routines to be executed
# on program termination. If you want a routine to be called
# on termination (normal and abnormal), push the name of the
# routine onto this stack. These routines will be executed when
# {{Y:AppExit}} is called. It is thus advisable to ensure that
# {{Y:AppExit}} is NOT called within an exit routine.
#
@app_exit_routines = ();

#
# >>Description::
# {{Y:%app_config}} contains the application's configuration parameters.
%app_config = ();

#
# >>Description::
# {{@app_option}} defines the options supported by the application.
# The default options are {{help}}, {{out_ext}} and {{log_ext}}.
# To append to these, push your arguments onto the array.
# For example:
#
# V: push(@app_option,
# V:      'report|STR|report file',
# V: );
#
# If the script will never have a need for 'per file' output
# or errors, assign {{Y:@app_option_core}}
# to {{Y:@app_option}} before appending your script-specific options.
# For example:
#
# V: @app_option = @app_option_core;
# V: push(@app_option,
# V:      'report|STR|report file',
# V: );
#
# To obtain a concise description of each option, use the help
# option with no parameter. Alternatively, detailed help
# on a given option can be obtained by suppying the option
# name as a parameter.
#
# By default, output goes to standard output and diagnostics
# goes to standard error. These rules can be changed by
# specifying the {{out_ext}} and {{log_ext}} options
# respectively (and calling {{Y:AppProcess}} to process arguments).
# If a string is supplied to these options, it
# is treated as the extension of the file to send things to
# for each file. If supplied without a parameter, the
# extensions default to {{out}} and {{log}} respectively.
# A minus character (-) or an equals character (=) can be
# used to indicate standard output or standard error
# respectively.
#
@app_option_core = (
    'Option|Spec|Help',
    'help|STR;;|display help on options',
);
@app_option = (
    @app_option_core,
    'out_ext|STR;;out|output file extension',
    'log_ext|STR;;log|log file extension',
);

#
# >>Description::
# {{Y:app_msg_table}} defines the known message types. Each type
# is defined by the attributes in the table below.
#
# !block table
# Attribute:Description
# Type:message type name
# Severity:application exit code caused by this message
# Layout:format of message text
# !endblock
#
# # Now that TableParse is used, adding new messages is
# # more complicated that it use to be so it's no longer supported..
# #
# #   If you wish to support additional message types in your
# #   application, simply append them to this table and rebuild
# #   {{%app_msg_index}} using {{Y:TableIndex}}.
#
# {{Layout}} can include the symbols given in the table below.
#
# !block table
# Symbol:Description
# $text:user text
# $type:message type
# $app_name:application name
# $ARGV:current argument name (usually a file name)
# $app_context:current "context" (e.g. 'line ')
# $.:current line number
# $app_lineno:current line number (if $. is 0)
# !endblock
#
# The standard message types are explained in the table below.
#
# !block table; format=325; groups
# Tag                Severity  Description
# current object:
# object             0          general information
# warning            8          something you should know
# error              16         something you should fix
# abort              24         cannot precede processing
# whole application:
# app                0          general information
# app_warning        10         something you should know
# app_error          18         something you should fix
# fatal              32         cannot precede processing
# non-user messages:
# debug              0          debugging diagnostics - ignore
# failed             64         internal check failed - notify developer
# !endblock
#
# All messages are output to the standard error stream
# with a newline appended and prefixed as follows:
#
# * {{object}} messages by the current object name
# * {{warning}}, {{error}} and {{abort}} by current object name, line number and message type
# * {{app}} messages by the application name
# * {{app_warning}} messages by the application name and 'warning'
# * {{app_error}} messages by the application name and 'error'
# * {{fatal}} messages by the application name and 'fatal'
# * {{debug}} by application name and 'debug'
# * {{failed}} by application name and 'internal failure'
#
# Most applications only use {{fatal}}, {{abort}}, {{error}} and {{warning}}.
# {{fatal}} is used when an application decides to terminate.
# (e.g. when an option is illegal.) {{abort}} is used when
# an application decides not be precede any further on the
# current object (e.g. too many errors encountered). {{error}}
# is used when a serious error is detected in processing the
# current object. {{warning}} is used when a minor error or
# possible error is detected. Typically, an application
# continues processing the current object when an error or
# warning is encountered but errors prevent further
# passes on the object while warnings do not.
#
@app_msg_table = &TableParse (
    'Type       Severity  Layout',
    'object     0         $ARGV: $text\n',
    'warning    8         $ARGV $type, $app_context$.: $text\n',
    'error      16        $ARGV $type, $app_context$.: $text\n',
    'abort      24        $ARGV $type, $app_context$.: $text\n',
    'tst_object 0         # $ARGV: $text\n',
    'tst_warning8         # $ARGV $type, $app_context$.: $text\n',
    'tst_error  16        # $ARGV $type, $app_context$.: $text\n',
    'tst_abort  24        # $ARGV $type, $app_context$.: $text\n',
    '.warning   8         $ARGV $type, $app_context$app_lineno: $text\n',
    '.error     16        $ARGV $type, $app_context$app_lineno: $text\n',
    '.abort     24        $ARGV $type, $app_context$app_lineno: $text\n',
    'app        0         $app_name: $text\n',
    'app_warning10        $app_name warning: $text\n',
    'app_error  18        $app_name error: $text\n',
    'fatal      32        $app_name $type: $text\n',
    'debug      0         $app_name $type: $text\n',
    'failed     64        $app_name internal failure: $text\n',
);

#
# >>Description::
# {{Y:app_context}} and {{Y:app_lineno}} are the context and line number
#  used in error messages. {{Y:app_lineno}} is only used if $. is 0.
#
$app_context = 'line ';
$app_lineno = 0;

#
# >>Description::
# {{Y:%app_msg_index}} is the index into the message table.
# (Most programmers have no need for this, but it's provided
# in case someone does want it.)
#
@_app_msg_dupl = ();
%app_msg_index = &TableIndex(*app_msg_table, *_app_msg_dupl, 'Type');

# Message type log and exit code
@_app_msg_type = ();
$_app_exit_code = 0;

# Usage message buffer and counter
$_app_usage = "";
$_app_usage_cnt = 0;

# display timing flag
$_app_timing = 0;

# enable/disable argument echoing flags - if neither if set, echoing
# occurs if and only if there is more than one argument
$_app_echo = 0;
$_app_noecho = 0;

# Aliases - null-separated lists of options and associated help, if any
%_app_alias = ();
%_app_alias_help = ();

#
# >>Description::
# {{Y:app_product_name}} and {{Y:app_product_version}} are the application
# name and version respectively. These are typically set during execution
# of the {{AppInit}} routine.)
#
$app_product_name = '';
$app_product_version = '';

#
# >>Description::
# {{Y:app_trace_level}} is the highest level of trace messages output by
# {{Y:AppTrace}} for each tracing group.
#
%app_trace_level = ();

# Initialisation file handler
$_app_ini_handler = '';

# Test counter
$_app_test_counter = 0;

######### Routines #########

#
# >>Description::
# {{Y:AppMsg}} outputs a message. The format of the message is
# determined by the {{type}} parameter which should be
# defined in {{Y:app_msg_table}}. If the type is
# unknown, behaviour is undefined.
# If {{calltree}} is set, a call tree is dumped after the
# message is output.
#
# If a message layout includes the current line number ($.)
# and it is 0, {{Y:AppMsg}} uses the dot-version (e.g. ".error")
# of the message instead.
#
# The messages output via {{Y:AppMsg}} influence the exit
# code returned to the operating system by {{Y:AppExit}}.
# If you wish to influence this but not output a message,
# specify a {{type}} parameter without a {{text}} parameter.
#
sub AppMsg {
    local($type, $text, $calltree) = @_;
#   local();
    local(%type, $msg, $code);

    # lookup message type
    %type = &TableLookup(*app_msg_table, *app_msg_index, $type);
    if ($. == 0 && $type{'Layout'} =~ /\$\./) {
        %type = &TableLookup(*app_msg_table, *app_msg_index, ".$type");
    }
        
    # output message to stream after stripping any trailing
    # newlines and formatting
    if ($text) {
        $text =~ s/\n+$//;
        $msg = eval sprintf('"%s"', $type{'Layout'});
	if ($type eq 'tst_object') {
            printf  "%s", $msg;   # so make test output is not cluttered
        } else {
            printf STDERR ("%s", $msg);
	}
    }

    # Dump the call tree, if requested
    &AppShowCallTree() if $calltree;

    # log message
    $code = $type{'Severity'};
    $_app_exit_code = $code if $code > $_app_exit_code;
    push(@_app_msg_type, $type);
}

#
# >>Description::
# {{Y:AppMsgCounts}} returns the number of each message type
# found. If you are interested in the message counts since
# a particular point in time, a starting index to begin the
# counting from can be specified.
#
sub AppMsgCounts {
    local($start_index) = @_;
    local(%count);

    for (@_app_msg_type[$start_index .. $#_app_msg_type]) {
        $count{$_}++;
    }
    return %count;
}

#
# >>Description::
# {{Y:AppMsgNextIndex}} returns the next index to be used
# in the message log. The value returned can be used as
# the {{start_index}} parameter to the {{Y:AppMsgCounts}} routine.
#
sub AppMsgNextIndex {
#   local() = @_;
    local($index);
    return $#_app_msg_type + 1;
}

#
# >>Description::
# {{Y:AppExit}} exits the current application. If a message
# is specified, it is first output via {{Y:AppMsg}}. The
# exit code returned to the operating system is dependent
# on the messages output by {{Y:AppMsg}}.
# If {{calltree}} is set, a call tree is dumped after the
# message is output.
#
sub AppExit {
    local($type, $text, $calltree) = @_;
#   local();
    local($fn);

    # Output message, if any
    &AppMsg($type, $text) if $type;

    # Dump the call tree, if requested
    &AppShowCallTree() if $calltree;
    
    # Execute any requested exit routines
    while ($fn = pop(@app_exit_routines)) {
        eval {&$fn};
    }
        
    # Output timing info, if requested
    if ($_app_timing) {
        if ($NAME_OS eq 'unix') {
            printf "execution time: %.2f seconds\n", (times)[0];
        }
        else {
            printf "execution time: %d seconds\n", time - $_app_start;
        }
    }

    # Note: If we're in test mode, return 0
    exit( $_app_test_counter > 0 ? 0 : $_app_exit_code);
}

#
# >>Description::
# {{Y:AppTrace}} outputs a trace message if {{group}} tracing is supported and
# for that group, the trace level is >= {{level}}. The default group is
# called {{user}}.
#
sub AppTrace {
    local($group, $level, $msg) = @_;
#   local();

    $group = 'user' if $group eq '';
    if ($app_trace_level{$group} >= $level) {
        printf STDERR ("%s[%s-%d] %s\n", $app_name, $group, $level, $msg);
    }
}

#
# >>Description::
# {{Y:AppInit}} processes options and checks the argument count for a
# perl script. The supported options are defined by
# @app_option. Options must occur before arguments
# and begin with a - character for the short format
# or -- for the long format. Option processing is
# terminated when either an argument or the -- symbol
# is detected. If an environment variable of the
# form {{app_name}}OPTS is found, options are first
# processed from there.
#
# The expected number of arguments is derived
# from the format of the {{arguments}} parameter as
# illustrated by the table below.
#
# !block table; format=24
# Expected       Format
# 0              ""
# 0 or more      "..."
# 1              "file"
# 1 or more      "file ..."
# 2              "source destination"
# 2 or more      "pattern file ..."
# 2 or more      "file ... destination"
# !endblock
#
# The pattern "..." is used to detect if a variable number of
# arguments is permitted. If no arguments are supplied and
# one or more are expected, then a concise usage message is
# output. If an application does not require an argument,
# there is no way to output only a concise usage (use the
# help option instead). {{purpose}} is displayed as part of
# the usage message. {{product}} is an optional parameter.
# If it is supplied and a product of that name exists in the
# internal product version lookup table, the product version
# is included in the usage too. Note that the usage message
# always includes a script version, regardless of whether
# a product version is displayed or not.
#
# If {{Y:AppInit}} encounters an error, it outputs a usage
# message and returns 0. Otherwise, it returns 1.
#
sub AppInit {
    local($arguments, $purpose, $product, $ini_handler) = @_;
    local($ok);
    # my variables
    local(%opt_short, $env_opts, $usage_msg);
    # local variables
    local(@badoptions, @badaliases, @badparams);
    local(@opt_code, %opt_attr);
    local($param, $value);

    # treat product like any other configuration parameter
    if ($product ne '') {
        $app_config{'product'} = $product;
    }

    # Save the ini-file handler
    $_app_ini_handler = $ini_handler;

    # initialise lookup tables:
    # * %opt_attr contains the attribute values for each option
    # * @opt_code contains the list of short format codes
    # * %opt_short converts a long format name to a short format one
    %opt_attr = &_AppOptsIndex(*opt_code, *opt_short, @app_option);

    # process configuration parameters, ensuring that:
    # * the library directory, if any, is the first one processed
    # * the inifile, if any, is the last one processed
    if ($app_config{'libdir'}) {
        &_AppSetConfig('libdir', $app_config{'libdir'});
    }
    for $param (keys %app_config) {
        next if $param eq 'inifile';
        next if $param eq 'libdir';
        unless (&_AppSetConfig($param, $app_config{$param})) {
            &AppExit("failed", "bad app_config key '$param'");
        }
    }
    if ($app_config{'inifile'}) {
        &_AppSetConfig('inifile', $app_config{'inifile'});
    }

    # prepend options in the environment variable ${name}OPTS
    $env_opts = "${app_name}OPTS";
    $env_opts =~ tr/[a-z]/[A-Z]/;
    unshift(@ARGV, split(/ /, $ENV{$env_opts}));

    # apply the default alias, if any
    if (defined($_app_alias{$app_name})) {
        unshift(@ARGV, split("\000", $_app_alias{$app_name}));
        $purpose = $_app_alias_help{$app_name};
    }

    # process the options
    option:
    while (@ARGV) {
        local($opt_prefix, $opt_text, $opt_code);
        local($rest, %opt, $action);

        # check for the options terminator
        $_ = $ARGV[0];
#print "argument: $_<\n";
        if ($_ eq '--') {
            shift(@ARGV);
            last option;
        }

        # Get next option:
        # * $opt_code is the short version (set for short AND long)
        # * $rest is the remainder of the text in this argument

        # aliases begin with '+'
        if (/^\+(.+)$/) {
            if (!defined($_app_alias{$1})) {
                push(@badaliases, $1);
            }
            shift(@ARGV);
            unshift(@ARGV, split("\000", $_app_alias{$1}));
            next option;
        }

        # configuration parameters begin with '-.'
        elsif (/^\-\.(.+)$/) {
            $param = $1;
            if ($param =~ /^(\w+)[:=](.*)$/) {
                $param = $1;
                $value = $2;
            }
            else {
                $value = 1;
            }
            shift(@ARGV);
            unless (&_AppSetConfig($param, $value)) {
                push(@badparams, $1);
            }
            next option;
        }

        # long options begin with '--'
        elsif (/^\-\-(.+)$/) {
            $opt_text = $1;
            if ($opt_text =~ /^(\w+)[:=](.*)$/) {
                $opt_text = $1;
                $rest = $2;
            }
            else {
                $rest = '';
            }
            $opt_code = $opt_short{$opt_text};

            # if full name not given, check for shortest unique format
            unless ($opt_code) {
                local(@matches);
                    
                @matches = grep(/^$opt_text/, keys %opt_short);
                $opt_code = $opt_short{$matches[0]} if $#matches == 0;
            }
        }

        # short options begin with '-'
        elsif (/^\-(.)(.*)$/) {
            $opt_code = $1;
            $rest = $2;
        }

        # if reach here, must be an argument
        else {
            last option;
        }

        # check option exists
        %opt = &_AppOption($opt_code);
        unless (%opt) {
            push(@badoptions, $_);
            shift(@ARGV);
            next option;
        }

        # get parameter & process according to type
        # ($opt_text is passed as a boolean to indicate long or short format)
        ($action, $usage_msg) = &_AppOptProcess($rest, $opt_text, %opt);
        last option if $usage_msg;
        eval $action;
        if ($@) {
            &AppExit('failed', "option action '$action' error: '$@'");
        }
    }

    # Reset usage variables
    $_app_usage = &_AppBuildUsage($arguments, $purpose);
    $_app_usage_cnt = 0;

    # Check usage and return
    return &_AppCheckUsage($arguments, $usage_msg, *badoptions, *badaliases,
      *badparams);
}

#
# >>_Description::
# {{Y:_AppOptsIndex}} builds an index of option attributes.
# %opt_attr is a lookup table with the option code as the key
# @opt_code is the set of short format option codes.
# %opt_short converts a long format option name to a short format one.
# @opt_strings is assumed to be a set of Tbl strings ready for parsing
# by {{Y:TableParse}} into records.
#
sub _AppOptsIndex {
    local(*opt_code, *opt_short, @opt_strings) = @_;
    local(%opt_attr);
    local(@opt_table);
    local(@field, %o, $code, $name);
    local($required, $type, $array, $validate, $init, $default);
    local($str, $n, $v);

    # Parse the option strings into records
    @opt_table = &TableParse(@opt_strings);

    @opt_code = ();
    %opt_short = ();
    @field = &TableFields(shift(@opt_table));
    for $o (@opt_table) {
        %o = &TableRecSplit(*field, $o);

        # determine option code & long name
        if ($o{'Option'} =~ /;/) {
            $o{'Option'} = $`;
            $code = $';
        }
        else {
            $code = substr($o{'Option'}, 0, 1);
        }
        $name = $o{'Option'};

        # check option code & name are unique
        if (grep(/^$code$/, @opt_code)) {
            &AppExit("failed", "option code '$code' not unique");
        }
        elsif ($opt_short{$name}) {
            &AppExit("failed", "option name '$name' not unique");
        }
        $o{'Code'} = $code;

        # determine type-related attributes
        ($type, $init, $default) = split(/;/, $o{'Spec'});
        $array = '';
        $validate = '';
        $required = '';
        if ($type ne 'BOOL') {
            $required = ($o{'Spec'} =~ /;.*;/) ? 'maybe' : 'yes';
            if ($type =~ /^(\w+)\-/) {
                $type = $1;
                $validate = $';
            }
            if ($type =~ /(LIST|HASH)$/) {
                $type = $`;
                $array = $1;
            }
        }
        $o{'Parameter'} = $required if $required;
        $o{'Type'} = $type;
        $o{'Array'} = $array if $array;
        $o{'Initial'} = $init;
        $o{'Default'} = $default if $required eq 'maybe';
        $o{'Validate'} = $validate if $validate;

        # some semantic checks
        unless (grep(/^$type$/, 'BOOL', 'STR', 'INT', 'NUM',
          'ROUTINE')) {
            &AppExit("failed", "unknown option type '$type' for option '$code'");
        }
        if ($type eq 'ROUTINE' && ! $validate) {
            &AppExit('failed', "unknown routine for option '$name'");
        }

        # initialise option, if required
        if ($init) {
            local($action);
            $action = &_AppAction($init, 1, %o);
            eval $action;
            if ($@) {
                &AppExit('failed', "action '$action' error: '$@'");
            }
        }

        # save this option
        $str = '';
        $str .= "$n=$v\000" while ($n, $v) = each %o;
        $opt_attr{$code} = $str;
#print "code:$code<\n";
#print "data:$opt_attr{$code}<\n";
        push(@opt_code, $code);
        $opt_short{$name} = $code;
    }

    # Return result
    return %opt_attr;
}

#
# >>_Description::
# {{Y:_AppOption}} returns the attributes of an option.
#
sub _AppOption {
    local($opt_code) = @_;
    local(%opt);
    local($nv);

    for $nv (split(/\000/, $opt_attr{$opt_code})) {
        $opt{$`} = $' if $nv =~ /\=/;
    }

    # Return result
    return %opt;
}

#
# >>_Description::
# {{Y:_AppOptProcess}} processes an option, updating the ARGV array
# as it goes. If {{long}} is true, the option is processed as a long
# option, otherwise short.
#
sub _AppOptProcess {
    local($rest, $long, %opt) = @_;
    local($action, $usage_msg);
    local($param, $required, $default_used, $missing);

    if ($long) {
        shift(@ARGV);
        $param = $rest;
    }
    else {

        # handle required parameter
        $required = $opt{'Parameter'};
        if ($required eq 'yes') {
            shift(@ARGV);
            if ($rest) {
                $param = $rest;
            }
            elsif (@ARGV) {
                $param = shift(@ARGV);
            }
            else {
                $missing = $opt{'Option'};
            }
        }

        # handle optional parameter
        elsif ($required eq 'maybe') {
            shift(@ARGV);
            if ($rest) {
                $param = $rest;
            }
            else {
                $param = $opt{'Default'};
                $default_used = 1;
            }
        }

        # handle no parameter
        else {
            if ($rest) {
                $ARGV[0] = "-$rest";
            }
            else {
                shift(@ARGV);
            }
        }
    }

    # Get action (if all ok)
    if ($missing) {
        $usage_msg = "parameter required for option $missing";
    }
    else {
        $param = 1 if $opt{'Type'} eq 'BOOL';
        $action = &_AppAction($param, $default_used, %opt);

    }

    # Return result
    return ($action, $usage_msg);
}

#
# >>_Description::
# {{Y:_AppAction}} returns a Perl expression to be eval'ed.
# For arrays, if $init is true, the array is initialised
# to the value specified, otherwise, the value is appended.
#
sub _AppAction {
    local($value, $init, %opt) = @_;
    local($action);
    local($id);

    $id = $opt{'Option'};
    if ($opt{'Type'} eq 'ROUTINE') {
        # Pass parameter as string
        $value =~ s/(['\\])/\\$1/g;
        $value = "'$value'";
        $action = "&$opt{'Validate'}($value)";
    }
    elsif ($opt{'Array'} eq 'LIST') {
        if ($opt{'Type'} eq 'STR') {
            local(@value);
            @value = split(/,/, $value);
            for $v (@value) {
                $v =~ s/(['\\])/\\$1/g;
                $v = "'$v'";
            }
            $value = join(',', @value);
        }
        if ($init) {
            $action = "\@$id = ($value)";
        }
        else {
            $action = "push(\@$id, $value)";
        }
    }
    elsif ($opt{'Array'} eq 'HASH') {
        local(@key, @value, $key, $v);
        @key = split(/,/, $value);
        for $k (@key) {
            if ($k =~ /^(\w+)[:=]/) {
                $k = "'$1'";
                $v = $';
                if ($opt{'Type'} eq 'STR') {
                    $v =~ s/(['\\])/\\$1/g;
                    $v = "'$v'";
                }
            }
            else {
                $k = "'$k'";
                $v = 1;
            }
            push(@value, $v);
        }
        $key = join(',', @key);
        $value = join(',', @value);
        $action = '@' . $id . "{$key} = ($value)";
        $action = "undef %$id;" . $action if $init;
    }
    else {
        if ($opt{'Type'} eq 'STR') {
            $value =~ s/(['\\])/\\$1/g;
            $value = "'$value'";
        }
        $action = "\$$id = $value";
    }

    # Return result
    return $action;
}               

#
# >>_Description::
# _AppCheckUsage() checks if a usage message is required. If it is,
# it outputs one together with any necessary supporting messages.
# It returns 1 if things are fine.
#
sub _AppCheckUsage {
    local($arguments, $usage_msg, *badoptions, *badaliases, *badparams) = @_;
    local($ok);
    local(%badvalue, %opt, $check, $min, $max, @ok);
    local($args_reqd, $args_variable, $args_left, $arg_missing);

    # validate options
    %badvalue = ();
    check:
    for $opt (@opt_code) {
        %opt = &_AppOption($opt);
        if ($opt{'Validate'} && $opt{'Type'} ne 'ROUTINE') {

            # build the check string
            if ($opt{'Type'} eq 'STR') {
                $check = 'grep(/^$value$/, ' .
                  $opt{"Validate"} . ')';
            }
            else {
                ($min, $max) = split(/,/, $opt{'Validate'});
                if ($min eq '' && $max ne '') {
                    $check = '$value <= $max';
                }
                elsif ($min ne '' && $max eq '') {
                    $check = '$min <= $value';
                }
                elsif ($min ne '' && $max ne '') {
                    $check = '$min <= $value && $value <= $max';
                }
                else {
                    next check;
                }
            }

            # check the value(s)
            if ($opt{'Array'} eq 'LIST') {
                for $value (eval "\@$opt{'Option'}") {
                    if ($opt{'Type'} eq 'STR') {
                        $value =~ s/(\W)/\\$1/g;
                    }
                    unless (eval $check) {
                        $badvalue{$opt{'Option'}} = $value;
                        next check;
                    }
                }
            }
            elsif ($opt{'Array'} eq 'HASH') {
                for $value (eval "values \%$opt{'Option'}") {
                    if ($opt{'Type'} eq 'STR') {
                        $value =~ s/(\W)/\\$1/g;
                    }
                    unless (eval $check) {
                        $badvalue{$opt{'Option'}} = $value;
                        next check;
                    }
                }
            }
            else {
                $value = eval "\$$opt{'Option'}";
                if ($opt{'Type'} eq 'STR') {
                    $value =~ s/(\W)/\\$1/g;
                }
                unless (eval $check) {
                    $badvalue{$opt{'Option'}} = $value;
                }
            }
        }
    }
    
    # check the argument count
    $args_reqd = split(/ /, $arguments);
    if ($args_variable = ($arguments =~ /\.\.\./)) {
        $args_reqd--;
    }
    $args_left = scalar(@ARGV);
    if (! $usage_msg) {
        if ($args_reqd && $args_left == 0) {
            $arg_missing = 1;
        }
        elsif ($args_variable && $args_left < $args_reqd) {
            $arg_missing = 1;
            $usage_msg = "at least $args_reqd arguments required" .
              " - $args_left supplied";
        }
        elsif (! $args_variable && $args_left != $args_reqd) {
            $arg_missing = 1;
            $usage_msg = "$args_reqd arguments required" .
              " - $args_left supplied";
        }
    }

    # Output usage, if required
    $ok = 1;
    if (defined $help || $usage_msg || @badoptions || @badaliases ||
      @badparams || %badvalue || $arg_missing) {
        &AppPrintUsage();
        $ok = 0;
    }

    # Output help on option requested or all options/aliases
    # if the option requested does not exist, show the options/aliases
    if (@badoptions || @badaliases || defined $help) {
        %opt = &_AppOption($help);
        if (%opt) {
            printf "Detailed help on option: -%s,--%s\n\n", $help,
              $opt{'Option'};
            printf "%-10.10s %s\n", 'Attribute', 'Value';
            for $attr (@_APP_DETAILED_HELP) {
                if (defined $opt{$attr}) {
                    printf "%-10.10s %s\n", $attr,
                      $opt{$attr};
                }
            }
            if ($opt{'Validate'} && $opt{'Type'} ne 'ROUTINE') {
                if ($opt{'Type'} eq 'STR') {
                    @ok = eval "$opt{'Validate'}";
                    printf "%-10.10s %s\n", 'Legal',
                      join(', ', @ok);
                }
                else {
                    ($min, $max) = split(/,/,
                      $opt{'Validate'});
                    printf "%-10.10s %d..%d\n", 'Range',
                      $min, $max;
                }
            }
        }
        else {
            print "options:\n";
            for $opt (@opt_code) {
                %opt = &_AppOption($opt);
                printf "-%s, --%-15.15s %s\n", $opt,
                  $opt{'Option'}, $opt{'Help'};
            }
            if ($_app_alias{$app_name} eq '' && %_app_alias_help) {
                print "aliases:\n";
                for $opt (sort keys %_app_alias_help) {
                    printf "+%-15.15s %s\n", $opt,
                      $_app_alias_help{$opt};
                }
            }
        }
    }

    # Print configuration parameters
    if (@badparams) {
        print "configuration parameters:\n";
        for $opt (sort keys %_APP_CONFIG_HELP) {
            printf "%-10.10s %s\n", $opt, $_APP_CONFIG_HELP{$opt};
        }
    }

    # Print bad options
    if (@badoptions) {
        print "\n";
        for $opt (@badoptions) {
            &AppMsg('fatal', "unknown or non-unique option '$opt'");
        }
    }

    # Print bad aliases
    if (@badaliases) {
        print "\n";
        for $opt (@badaliases) {
            &AppMsg('fatal', "unknown alias '$opt'");
        }
    }

    # Print bad configuration parameters
    if (@badparams) {
        print "\n";
        for $opt (@badparams) {
            &AppMsg('fatal', "unknown configuation parameter '$opt'");
        }
    }

    # Print bad values
    if (%badvalue) {
        for $value (sort keys %badvalue) {
            &AppMsg('fatal', sprintf("bad %s value '%s'",
              $value, $badvalue{$value}));
        }
    }

    # Print usage message
    if ($usage_msg) {
        &AppMsg('fatal', $usage_msg);
    }

    # Return result
    return $ok;
}

#
# >>Description::
# {{Y:AppPrintUsage}} outputs the usage header message build during the
# last call to {{Y:AppInit}}. Only the first call to this routine
# (after {{Y:AppInit}} is called) will print the message. This
# allows programmers to do additional validation after {{Y:AppInit}}
# returns and know that only one usage header message will be output.
# 
sub AppPrintUsage {
#   local() = @_;
#   local();
    if ($_app_usage_cnt++ == 0) {
        print $_app_usage;
    }
}

#
# >>_Description::
# {{Y:_AppBuildUsage}} builds and returns a usage message, based on the
# options defined in @app_option.
#
sub _AppBuildUsage {
    local($arguments, $purpose) = @_;
    local($text);
    local($usage);
    local(%o, $required, $code, $desc, $version);
    local($product_info);

    # build usage string - application name and aliases
    $text = $app_name;
    if ($_app_alias{$app_name} eq '' && %_app_alias) {
        $text .= " [+alias]";
    }

    # build usage string - options
    for $opt (@opt_code) {
        %o = &_AppOption($opt);
        $required = $o{'Parameter'};

        # determine usage
        $code = $o{'Code'};
        $desc = $o{'Option'};
        $desc .= ",.." if $o{'Array'};
        if ($required eq 'yes') {
            $usage = "$code $desc";
        }
        elsif ($required eq 'maybe') {
            $usage = $code . "[$desc]";
        }
        else {
            $usage = "$code";
        }
        $text .= " [-$usage]";
    }

    # Get version:
    # * use public one if available, otherwise physical version
    # * strip RCS/SCCS stuff
    $version = $VERSION{'PUBLIC'};
    $version = $VERSION{$app_path} unless $version;
    if ($version =~ /^\$\w+: (.*)\$$/) {
        $version = $1;
    }
    elsif ($version =~ /^\@\(\#\)\s*(.*)$/) {
        $version = $1;
    }

    # Get product info, if any
    $product_info = '';
    if ($app_product_name) {
        $product_info = "    ($app_product_name $app_product_version)";
    }

    # Return result
    return "usage  : $text $arguments\n".
           "purpose: $purpose\n".
           "version: $version$product_info\n";
}

#
# >>_Description::
# {{Y:_AppSetConfig}} sets a configuration parameter.
# It returns true if the parameter is known.
#
sub _AppSetConfig {
    local($param, $value) = @_;
    local($ok);
    local($fn);

    # process the associated action
    $fn = $_APP_CONFIG_FN{$param};
    if ($fn) {
        $app_config{$param} = $value;
        eval {&$fn($value)};
        &AppExit('fatal', $@) if $@;
    }

    # Return result
    return $fn;
}

#
# >>_Description::
# {{Y:_AppConfigLibDir}} sets the library directory.
#
sub _AppConfigLibDir {
    local($value) = @_;
#   local();
    local($inc);
    my $nom_path;

    # Search the library path for the nominated directory
    for $inc (@INC) {
	$nom_path = "$inc/$value";
	$nom_path =~ s#:*/+#:#g if $^O eq 'MacOS';
        if (-d $nom_path) {
            $app_lib_dir = $nom_path;
            return;
        }
    }
}

#
# >>_Description::
# {{Y:_AppConfigInifile}} loads an inifile.
#
sub _AppConfigInifile {
    local($value) = @_;
#   local();
    local($fname);
    local(%inidata, $section, %config);
    local($product);
    local($alias_name, $alias_help, @alias_opts);
    local($next_inifile, $param);

    # Find the file
    $fname = &NameFind($value, ".", $app_lib_dir);
    if ($fname eq '') {
        &AppExit("fatal", "initialisation file '$value' not found");
    }

    # Fetch the file
    %inidata = &_AppFetchInifile($fname);

    # Get the configuration for later processing
    %config = &AppSectionValues($inidata{'Configuration'});
    delete $inidata{'Configuration'};

    # If this is also the product ini-file, process it accordingly
    $product = $app_config{'product'};
    $product =~ tr/A-Z/a-z/;
    if ($value eq "$product.ini") {
        &_AppProductIni($fname, *inidata);
    }

    # Process the standard data
    for $section (sort keys %inidata) {
        if ($section =~ /^Alias\s+(\w+)/) {
            $alias_name = $1;
            ($alias_help) = ($' =~ /^\s*:\s*(.*)$/);
            @alias_opts = &_AppSectionList($inidata{$section});
            for $param (@alias_opts) {
                $param = "--$param";
            }
            &_AppStoreAlias($alias_name, $alias_help, @alias_opts);

            # Remove the processed data from the configuration file
            delete $inidata{$section};
        }
    }

    # Process the user data
    if ($_app_ini_handler) {
        eval {&$_app_ini_handler($fname, *inidata)};
    }

    # Warn about the unknown sections
    for $section (sort keys %inidata) {
        &AppMsg("warning", "unknown section '$section' in initialisation file '$fname'");
    }

    # Process the configuration
    $next_inifile = $config{'inifile'};
    delete $config{'inifile'};
    for $param (keys %config) {
        &_AppSetConfig($param, $config{$param});
    }
    if ($next_inifile ne '') {
        &_AppSetConfig('inifile', $next_inifile);
    }
}

#
# >>_Description::
# {{Y:_AppFetchInifile}} fetches an inifile.
# Each section is returned as an entry in {{%data}}.
# Within each section, lines are terminated by a newline.
#
sub _AppFetchInifile {
    local($inifile) = @_;
    local(%data);
    local($section, $_);

    # Open the file
    unless (open(INIFILE, $inifile)) {
        &AppExit("fatal", "unable to open initialisation file '$inifile'");
    }

    # Read the data
    while (<INIFILE>) {

        # skip blank and comment lines
        s/^\s+//;
        s/\s+$//;
        next if /^$/ || /^#/ || /^;/;

        # change the section or add data to the current section
        if (/^\[(.*)\]$/) {
            $section = $1;
        }
        else {
            $data{$section} .= "$_\n";
        }
    }

    # Close the file
    close(INIFILE);

    # Return result
    return %data;
}

#
# >>_Description::
# {{Y:_AppSectionList}} converts an inifile section into a list.
#
sub _AppSectionList {
    local($text) = @_;
    local(@data);

    # Return result
    return split("\n", $text);
}

#
# >>Description::
# {{Y:AppSectionValues}} converts an inifile section into a set of
# name-value pairs.
#
sub AppSectionValues {
    local($strs) = @_;
    local(%values);
    local($line);

    # process the lines
    for $line (split("\n", $strs)) {
        if ($line =~ /^\s*([\w\.]+)\s*\=\s*(.*)\s*$/) {
            $values{$1} = $2;
        }
    }

    # Return result
    return %values;
}

#
# >>_Description::
# {{Y:_AppStoreAlias}} stores an alias.
#
sub _AppStoreAlias {
    local($name, $help, @options) = @_;
#   local();

    $_app_alias{$name} = join("\000", @options);
    $_app_alias_help{$name} = $help;
}

#
# >>_Description::
# {{Y:_AppConfigVersion}} sets the version number of a script.
#
sub _AppConfigVersion {
    local($value) = @_;
#   local();

    $VERSION{'PUBLIC'} = $value;
}

#
# >>_Description::
# {{Y:_AppConfigProduct}} makes this script part of the nominated product.
#
sub _AppConfigProduct {
    local($value) = @_;
#   local();
    local($inifile);
    local($fname);
    local($section);

    # Save the product name
    $app_product_name = $value;

    # Get the product ini-file
    $value =~ tr/A-Z/a-z/;
    $inifile = &NameJoin('', $value, 'ini');

    # Skip processing it if it's going to be done later
    return if $inifile eq $app_config{'inifile'};

    # Load and process the ini-file data
    $fname = &NameFind($inifile, ".", $app_lib_dir);
    if ($fname eq '') {
        &AppExit("fatal", "initialisation file '$value' not found");
    }
    %inidata = &_AppFetchInifile($fname);
    &_AppProductIni($fname, *inidata);


    # Ignore aliases in the product ini-file data
    for $section (sort keys %inidata) {
        if ($section =~ /^Alias\s+(\w+)/) {
            delete $inidata{$section};
        }
    }

    # Process the user data
    if ($_app_ini_handler) {
        eval {&$_app_ini_handler($fname, *inidata)};

        # Warn about the unknown sections - but only if the application
        # has an ini file handler (otherwise, warnings are produced for
        # commands which share a product ini file)
        for $section (sort keys %inidata) {
            &AppMsg("warning", "unknown section '$section' in initialisation file '$fname'");
        }
    }
}

#
# >>_Description::
# {{Y:_AppProductIni}} processes the product-specific ini-file data.
#
sub _AppProductIni {
    local($fname, *inidata) = @_;
#   local();
    local($section, %values, $key);

    # Process the infile
    for $section (keys %inidata) {
        if ($section eq 'Product') {
            %values = &AppSectionValues($inidata{$section});
            for $key (keys %values) {
                if ($key eq 'version') {
                    $app_product_version = $values{$key};
                }
                else {
                    &AppMsg("warning", "unknown [Product] parameter '$key' in initialisation file '$fname'");
                }
            }

            # Remove the processed data from the configuration file
            delete $inidata{$section};
        }
    }
}

#
# >>_Description::
# {{Y:_AppConfigTest}} enables verification of the output files.
# If value is a number, Perl-style test output is generated and
# the first test has that number. Otherwise, the value is the name
# of the verification routine to use.
#
sub _AppConfigTest {
    local($value) = @_;
#   local();

    # Ensure output and log file are generated & disable argument echoing
    unshift(@ARGV, '-o', '-l');
    $_app_noecho = 1;

    # The default test handler is _AppVerifyOutputs
    if ($value =~ /^\d+$/) {
	$_app_test_fn = '_AppVerifyOutputs';
	$_app_test_counter = $value;
    }
    else {
        $_app_test_fn = $value;
    }
}

#
# >>_Description::
# {{Y:_AppConfigNoEcho}} disables argument echoing.
#
sub _AppConfigNoEcho {
    local($value) = @_;
#   local();

    $_app_noecho = 1;
}

#
# >>_Description::
# {{Y:_AppConfigTime}} enables timing the execution of a program.
#
sub _AppConfigTime {
    local($value) = @_;
#   local();

    $_app_timing = 1;
}

#
# >>_Description::
# {{Y:_AppConfigParts}} enables the display (upon exit) of the
# components (and their versions) making up this application.
#
sub _AppConfigParts {
    local($value) = @_;
#   local();

    push(@app_exit_routines, "AppShowParts");
}

#
# >>_Description::
# {{Y:_AppConfigCallTree}} enables the display (upon exit) of the
# call tree of routines.
#
sub _AppConfigCallTree {
    local($value) = @_;
#   local();

    push(@app_exit_routines, "AppShowCallTree");
}

#
# >>_Description::
# {{Y:_AppVerifyOutputs}} compares {{outfile}} and {{logfile}} to
# verified files in the {{checked}} directory. Files which match are
# deleted. Files which do not match are kept so that the developer
# can diff the errors.
#
sub _AppVerifyOutputs {
    local($infile, $outfile, $logfile) = @_;
#   local();

    # Verify the output file
    &_AppVerifyFile($outfile, &NameJoin("checked", $outfile), 'output');
 
    # Verify the log file
    &_AppVerifyFile($logfile, &NameJoin("checked", $logfile), 'log');
}

#
# >>_Description::
# {{Y:_AppVerifyFile}} compares a test file against a checked file.
#
sub _AppVerifyFile {
    local($test, $check, $type) = @_;
    local($ok);
    local($testdata, $checkdata);

    # Get the data from the test file
    unless (open(TESTFILE, $test)) {
        &AppMsg("tst_error", "unable to open $type data file '$test' for testing");
        return 0;
    }
    $testdata = join('', <TESTFILE>);
    close TESTFILE;

    # Get the data from the check file
    unless (open(CHECKFILE, $check)) {
        &AppMsg("tst_error", "unable to open $type check file '$check' for testing");
        return 0;
    }
    $checkdata = join('', <CHECKFILE>);
    close CHECKFILE;

    # Compare the data
    if ($testdata eq $checkdata) {
        &AppMsg("tst_object", "$type file ok");
	printf "ok %d\n", $_app_test_counter++;
        unlink $test;
        return 1;
    }
    else {
        &AppMsg("tst_object", "$type file FAILED");
	printf "not ok %d\n", $_app_test_counter++;
        return 0;
    }
}

#
# >>Description::
# {{Y:AppShowParts}} displays the versions of components making up
# this application and exits. To support this facility, each library
# should include a line of the form:
#
# .     $VERSION{__FILE__} = "x.y"
#
# Strings containing SCCS or RCS stuff have the baggage stripped.
# For example:
#
# * '@(#) 3.2' is displayed as '3.2'
# * '$Revision: 1.27 $' is displayed as '3.3'
#
# {{Y:AppShowParts}} is usually called via the '.parts' special
# help option. However, certain application code might have a
# need to call it directly.
#
sub AppShowParts {
#   local = @_;
#   local();
    local($version);

    for (sort keys %VERSION) {
        $version = $VERSION{$_};
        if ($version =~ /^\$\w+: (.*)\$$/) {
            $version = $1;
        }
        elsif ($version =~ /^\@\(\#\)\s*(.*)$/) {
            $version = $1;
        }
        printf "%-16s %s\n", $version, $_;
    }
}

#
# >>Description::
# {{Y:AppShowCallTree}} displays the call tree (excluding the call
# to itself). The routine is usually called indirectly:
#
# * via {{Y:AppMsg}} or {{Y:AppExit}} ({{calltree}} parameter set), or
# * via the .calltree special help parameter
#
# Like {{Y:AppShowComponents}}, certain application code may wish to
# call {{Y:AppShowCallTree}} directly.
#
sub AppShowCallTree {
#   local() = @_;
#   local();
    local($i,$p,$f,$l,$s,$h,$a,@a,@sub);

    for ($i = 1; ($p,$f,$l,$s,$h,$w) = caller($i); $i++) {
        @a = @DB'args;
        for (@a) {
            if (/^StB\000/ && length($_) == length($_main{'_main'})) {
                $_ = sprintf("%s",$_);
            }
            else {
                s/'/\\'/g;
                s/([^\0]*)/'$1'/ unless /^-?[\d.]+$/;
            s/([\200-\377])/sprintf("M-%c",ord($1)&0177)/eg;
                s/([\0-\37\177])/sprintf("^%c",ord($1)^64)/eg;
            }
        }
        $w = $w ? '@ = ' : '$ = ';
        $a = $h ? '(' . join(', ', @a) . ')' : '';
        push(@sub, "$f $l: $w&$s$a\n");
    }
    print STDERR "CALL TREE IS..\n";
    for ($i=0; $i <= $#sub; $i++) {
        print STDERR $sub[$i];
    }
    print STDERR "END CALL TREE.\n";
}

#
# >>Description::
# {{Y:AppProcess}} processes each argument on the command-line.
# In particular, it does the following for each argument:
#
# * if the argument is '+', processes each line of standard input
#   as an argument
# * if a file matching an argument is not found, but {{default_ext}} is
#   supplied and adding that extension results in a file being found,
#   then {{default_ext}} is added as an extension to the argument
# * echos the argument to standard error if there is more than one
# * if $out_ext is set, opens an output file for the current
#   argument and redirects STDOUT to it
# * if $log_ext is set, opens a log file for the current
#   argument and redirects STDERR to it
# * calls {{arg_process_fn}}
# * close the output and log files, returning STDOUT and STDERR back
#   to their initial state
# * calls {{arg_post_process_fn}}, if any
#
# Note that {{arg_post_process}}
# is optional - it is only used in scripts which need to
# do additional processing on an file {{after}} output streams
# have been closed.
#
# {{arg_process_fn}} has the following interface:
#
# V:     $err = &arg_process_fn($arg)
#
# {{arg_post_process_fn}} has the following interface:
#
# V:     $err = &arg_post_process_fn($arg, $arg_err)
#
# where {{arg_err}} is the error code returned by {{arg_process_fn}}.
# {{Y:AppProcess}} returns the highest error code it encounters from
# the user processing functions it calls.
#
# If you need to disable the special meaning of '+', set the
# {{Y:APP_STDIN_ARGS}} configuration constant to an empty string.
# Likewise, you can change the character used by setting it
# to another value, although this is not recommended given the
# consistency implications.
#
sub AppProcess {
    local($arg_process_fn, $arg_post_process_fn, $default_ext) = @_;
    local($app_err);
    local($echo_args, $stdin_read, @stdin_args);
    local($dir, $base, $ext, $outfile, $logfile);
    local($base_ext);
    local($arg_err, $post_err);

    # Decide if we should echo arguments
    $echo_args = @ARGV > 1 && !$_app_noecho;

    # Loop through the arguments
    argument:
    while ($ARGV = shift(@ARGV)) {

        # Process stdin as a list of arguments, if requested
        if (! $stdin_read && $ARGV eq $APP_STDIN_ARGS) {

            # append the arguments to the front of ARGV
            @stdin_args = <STDIN>;
            chop(@stdin_args);
            unshift(@ARGV, @stdin_args);

            # update echoing accordingly
            $echo_args || ($echo_args = @ARGV > 1 && !$_app_noecho);

            $stdin_read = 1;
            next argument;
        }

        # Append the default extension, if necessary and supplied
        if (! -f $ARGV && $default_ext ne '') {
            $base_ext = &NameJoin('', $ARGV, $default_ext);
            $ARGV = $base_ext if -f $base_ext;
        }

        # init the per argument stuff
        $arg_err = 0;
        ($dir, $base, $ext) = &NameSplit($ARGV);

        # echo the argument name
        if ($echo_args || $_app_echo) {
            print STDERR "$ARGV:\n";
        }

        # decide on output and log streams
        $outfile = '';
        $logfile = '';
        if ($out_ext && -f $ARGV && $out_ext ne '-') {
            if ($out_ext eq '=') {
                $outfile = "&STDERR";
            }
            else {
                $outfile = &NameJoin('', $base, $out_ext);
            }
        }
        if ($log_ext && -f $ARGV && $log_ext ne '=') {
            if ($log_ext eq '-') {
                $logfile = "&STDOUT";
            }
            else {
                $logfile = &NameJoin('', $base, $log_ext);
            }
        }
            
        # if required, redirect output and log streams
        if ($outfile) {
            unless (open(APP_OUT, ">&STDOUT")) {
                print STDERR "failed to save stdout: $!";
            }
            unless (open(STDOUT, "> $outfile")) {
                print STDERR "failed to redirect stdout: $!";
            }
        }
        if ($logfile) {
            unless (open(APP_ERR, ">&STDERR")) {
                print STDERR "failed to save stderr: $!";
            }
            unless (open(STDERR, "> $logfile")) {
                print APP_ERR "failed to redirect stderr: $!";
            }
        }

        # process each argument
        $arg_err = &$arg_process_fn($ARGV);

        # if required, close the output/log files
        if ($logfile) {
            unless (close(STDERR)) {
                print APP_ERR "failed to close stderr: $!";
            }
            unless (open(STDERR, ">&APP_ERR")) {
                print STDERR "failed to re-open stderr: $!";
            }
        }
        if ($outfile) {
            unless (close(STDOUT)) {
                print STDERR "failed to close stdout: $!";
            }
            unless (open(STDOUT, ">&APP_OUT")) {
                print STDERR "failed to re-open stdout: $!";
            }
        }

        # do the post processing, if any
        if ($arg_post_process_fn) {
            $post_err = &$arg_post_process_fn($ARGV, $arg_err);
        }

        # do the test function, if any
        if ($_app_test_fn) {
            &$_app_test_fn($ARGV, $outfile, $logfile);
        }

        # update the overall error code
        $app_err = $arg_err if $arg_err > $app_err;
        $app_err = $post_err if $post_err > $app_err;
    }

    # return result
    return $app_err;
}

# package return value
1;
