# WebFetch
# ABSTRACT: Perl module to download/fetch and save information from the Web
# This module hierarchy is infrastructure for downloading ("fetching") information from
# various sources around the Internet or the local system in order to
# present them for display, or to export local information to other sites
# on the Internet
#
# Copyright (c) 1998-2022 Ian Kluft. This program is free software; you can
# redistribute it and/or modify it under the terms of the GNU General Public
# License Version 3. See  https://www.gnu.org/licenses/gpl-3.0-standalone.html

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use strict;
use warnings;
use utf8;
## use critic (Modules::RequireExplicitPackage)

package WebFetch;
$WebFetch::VERSION = '0.15.1';

use Carp qw(croak);
use Getopt::Long;
use Readonly;
use Scalar::Util qw(reftype);
use LWP::UserAgent;
use HTTP::Request;
use DateTime;
use DateTime::Format::ISO8601;
use DateTime::Locale;
use Date::Calc;
use WebFetch::Data::Config;

#
# constants
#

# defualt supported output formats
# more may be added by plugin modules
Readonly::Array my @WebFetch_formatters => qw( output:html output:xml output:wf );

# defualy modules for input and output
Readonly::Hash my %default_modules => (
    "input" => {
        "rss"        => "WebFetch::Input::RSS",
        "sitenews"   => "WebFetch::Input::SiteNews",
        "perlstruct" => "WebFetch::Input::PerlStruct",
        "atom"       => "WebFetch::Input::Atom",
        "dump"       => "WebFetch::Input::Dump",
    },
    "output" => {
        "rss"        => "WebFetch::Output:RSS",
        "atom"       => "WebFetch::Output:Atom",
        "tt"         => "WebFetch::Output:TT",
        "perlstruct" => "WebFetch::Output::PerlStruct",
        "dump"       => "WebFetch::Output::Dump",
    }
);

# parameters which are redirected into a sub-hash
Readonly::Hash my %redirect_params => (
    locale    => "datetime_settings",
    time_zone => "datetime_settings",
    notable   => "style",
    para      => "style",
    ul        => "style",
);

#
# exceptions/errors
#
use Try::Tiny;
use Exception::Class (
    'WebFetch::Exception',
    'WebFetch::TracedException' => {
        isa => 'WebFetch::Exception',
    },

    'WebFetch::Exception::DataWrongType' => {
        isa         => 'WebFetch::TracedException',
        alias       => 'throw_data_wrongtype',
        description => "provided data must be a WebFetch::Data::Store",
    },

    'WebFetch::Exception::IncompatibleClass' => {
        isa         => 'WebFetch::Exception',
        alias       => 'throw_incompatible_class',
        description => "class method called for class outside WebFetch hierarchy",
    },

    'WebFetch::Exception::GetoptError' => {
        isa         => 'WebFetch::Exception',
        alias       => 'throw_getopt_error',
        description => "software error during command line processing",
    },

    'WebFetch::Exception::Usage' => {
        isa         => 'WebFetch::Exception',
        alias       => 'throw_cli_usage',
        description => "command line processing failed",
    },

    'WebFetch::Exception::ParameterError' => {
        isa         => 'WebFetch::Exception',
        alias       => 'throw_param_error',
        description => "parameter error",
    },

    'WebFetch::Exception::Save' => {
        isa         => 'WebFetch::Exception',
        alias       => 'throw_save_error',
        description => "an error occurred while saving the data",
    },

    'WebFetch::Exception::NoSave' => {
        isa         => 'WebFetch::Exception',
        alias       => 'throw_no_save',
        description => "unable to save: no data or nowhere to save it",
    },

    'WebFetch::Exception::NoHandler' => {
        isa         => 'WebFetch::Exception',
        alias       => 'throw_no_handler',
        description => "no handler was found",
    },

    'WebFetch::Exception::MustOverride' => {
        isa         => 'WebFetch::TracedException',
        alias       => 'throw_abstract',
        description => "A WebFetch function was called which is " . "supposed to be overridden by a subclass",
    },

    'WebFetch::Exception::NetworkGet' => {
        isa         => 'WebFetch::Exception',
        description => "Failed to access RSS feed",
    },

    'WebFetch::Exception::ModLoadFailure' => {
        isa         => 'WebFetch::Exception',
        alias       => 'throw_mod_load_failure',
        description => "failed to load a WebFetch Perl module",
    },

    'WebFetch::Exception::ModRunFailure' => {
        isa         => 'WebFetch::Exception',
        alias       => 'throw_mod_run_failure',
        description => "failed to run a WebFetch module",
    },

    'WebFetch::Exception::ModNoRunModule' => {
        isa         => 'WebFetch::Exception',
        alias       => 'throw_no_run',
        description => "no module was found to run the request",
    },

    'WebFetch::Exception::AutoloadFailure' => {
        isa         => 'WebFetch::TracedException',
        alias       => 'throw_autoload_fail',
        description => "AUTOLOAD failed to handle function call",
    },

);

# initialize class variables
my %modules;
our $AUTOLOAD;

sub debug_mode
{
    my @args = @_;

    # check if any arguments were provided
    # counting parameters allows us to handle undef if provided as a value (can't do that with "defined" test)
    if ( scalar @args == 0 ) {

        # if no new value provided, return debug configuration value
        return WebFetch->config('debug') ? 1 : 0;
    }

    # set debug mode from provided value
    my $debug_mode = $args[0] ? 1 : 0;
    WebFetch->config( debug => $debug_mode );
    return $debug_mode;
}

# print parameters to STDERR if debug mode is enabled
sub debug
{
    my @args       = @_;
    my $debug_mode = debug_mode();
    if ($debug_mode) {
        print STDERR "debug: " . join( " ", @args ) . "\n";
    }
    return $debug_mode;
}

# module registry read-accessor
# for testing and internal use only (inhibit critic warning because it is not unused - tests use it)
## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _module_registry
{
    my ( $class, $key ) = @_;
    if ( not $class->isa("WebFetch") ) {
        throw_incompatible_class("invalid _module_registry() call for '$class': not in the WebFetch hierarchy");
    }
    if ( exists $modules{$key} ) {
        return $modules{$key};
    }
    return;
}
## critic (Subroutines::ProhibitUnusedPrivateSubroutines)

# return WebFetch (or subclass) version number
sub version
{
    my $class = shift;

    if ( not defined $class ) {
        throw_incompatible_class("invalid version() call on undefined value");
    }
    if ( not $class->isa("WebFetch") ) {
        throw_incompatible_class("invalid version() call for '$class': not in the WebFetch hierarchy");
    }
    {
        ## no critic (TestingAndDebugging::ProhibitNoStrict)
        no strict 'refs';
        if ( defined ${ $class . "::VERSION" } ) {
            return ${ $class . "::VERSION" };
        }
    }
    if ( defined $WebFetch::VERSION ) {
        return $WebFetch::VERSION;
    }
    return "00-dev";
}

# wrapper for WebFetch::Data::Config read/write accessor
sub config
{
    my ( $class, $key, $value ) = @_;
    if ( not $class->isa("WebFetch") ) {
        throw_incompatible_class("invalid config() call for '$class': not in the WebFetch hierarchy");
    }
    return WebFetch::Data::Config->accessor( $key, $value );
}

# wrapper for WebFetch::Data::Config existence-test method
sub has_config
{
    my ( $class, $key ) = @_;
    if ( not $class->isa("WebFetch") ) {
        throw_incompatible_class("invalid has_config() call for '$class': not in the WebFetch hierarchy");
    }
    return WebFetch::Data::Config->contains($key);
}

# wrapper for WebFetch::Data::Config existence-test method
sub del_config
{
    my ( $class, $key ) = @_;
    if ( not $class->isa("WebFetch") ) {
        throw_incompatible_class("invalid del_config() call for '$class': not in the WebFetch hierarchy");
    }
    return WebFetch::Data::Config->del($key);
}

sub import_config
{
    my ( $class, $hashref ) = @_;
    if ( not $class->isa("WebFetch") ) {
        throw_incompatible_class("invalid import_config() call for '$class': not in the WebFetch hierarchy");
    }

    # import config entries
    foreach my $key (%$hashref) {
        WebFetch::Data::Config->accessor( $key, $hashref->{$key} );
    }
    return;
}

sub keys_config
{
    my ($class) = @_;
    if ( not $class->isa("WebFetch") ) {
        throw_incompatible_class("invalid import_config() call for '$class': not in the WebFetch hierarchy");
    }
    my $instance = WebFetch::Data::Config->instance();
    return keys %$instance;
}

sub module_register
{
    my ( $module, @capabilities ) = @_;

    # each string provided is a capability the module provides
    foreach my $capability (@capabilities) {

        # import configuration entries if any entry in @capabilities is a hashref
        if ( ref $capability eq 'HASH' ) {
            WebFetch->import_config($capability);
            next;
        }

        # A ":" if present delimits a group of capabilities
        # such as "input:rss" for and "input" capability of "rss"
        if ( $capability =~ /([^:]+):([^:]+)/x ) {

            # A ":" was found so process a 2nd-level group entry
            my $group  = $1;
            my $subcap = $2;
            if ( not exists $modules{$group} ) {
                $modules{$group} = {};
            }
            if ( not exists $modules{$group}{$subcap} ) {
                $modules{$group}{$subcap} = [];
            }
            push @{ $modules{$group}{$subcap} }, $module;
        } else {

            # just a simple capbility name so store it
            if ( not exists $modules{$capability} ) {
                $modules{$capability} = [];
            }
            push @{ $modules{$capability} }, $module;
        }
    }
    return;
}

# module selection - choose WebFetch module based on selected file format
# for WebFetch internal use only
sub module_select
{
    my $capability  = shift;
    my $is_optional = shift;

    debug "module_select($capability,$is_optional)";

    # parse the capability string
    my ( $group, $topic );
    if ( $capability =~ /([^:]*):(.*)/x ) {
        $group = $1;
        $topic = $2;
    } else {
        $topic = $capability;
    }

    # check for modules to handle the specified source_format
    my ( @handlers, %handlers );

    # consider whether a group is in use (single or double-level scan)
    if ($group) {

        # double-level scan

        # if the group exists, search in it
        if (    ( exists $modules{$group}{$topic} )
            and ( ref $modules{$group}{$topic} eq "ARRAY" ) )
        {
            # search group for topic
            foreach my $handler ( @{ $modules{$group}{$topic} } ) {
                if ( not exists $handlers{$handler} ) {
                    push @handlers, $handler;
                    $handlers{$handler} = 1;
                }
            }

            # otherwise check the defaults
        } elsif ( exists $default_modules{$group}{$topic} ) {

            # check default handlers
            my $def_handler = $default_modules{$group}{$topic};
            if ( not exists $handlers{$def_handler} ) {
                push @handlers, $def_handler;
                $handlers{$def_handler} = 1;
            }
        }
    } else {

        # single-level scan

        # if the topic exists, the search is a success
        if (    ( exists $modules{$topic} )
            and ( ref $modules{$topic} eq "ARRAY" ) )
        {
            @handlers = @{ $modules{$topic} };
        }
    }

    # check if any handlers were found for this format
    if ( not @handlers and not $is_optional ) {
        throw_no_handler("handler not found for $capability");
    }

    debug "module_select: " . join( " ", @handlers );
    return @handlers;
}

# satisfy POD coverage test - but don't put this function in the user manual

# if no input or output format was specified, but only 1 is registered, pick it
# $group parameter should be config group to search, i.e. "input" or "output"
# returns the format string which will be provided
sub singular_handler
{
    my $group = shift;

    debug "singular_handler($group)";
    my $count = 0;
    my $last_entry;
    foreach my $entry ( keys %{ $modules{$group} } ) {
        if ( ref $modules{$group}{$entry} eq "ARRAY" ) {
            my $entry_count = scalar @{ $modules{$group}{$entry} };
            $count += $entry_count;
            if ( $count > 1 ) {
                return;
            }
            if ( $entry_count == 1 ) {
                $last_entry = $entry;
            }
        }
    }

    # if there's only one registered, that's the one to use
    debug "singular_handler: count=$count last_entry=$last_entry";
    return $count == 1 ? $last_entry : undef;
}

# Find and run all the fetch_main functions in packages under WebFetch.
# This eliminates the need for the sub-packages to export their own
# fetch_main(), which users found conflicted with each other when
# loading more than one WebFetch-derived module.

# fetch_main - try/catch wrapper for fetch_main2 to catch and display errors
sub main::fetch_main
{

    # run fetch_main2 in a try/catch wrapper to handle exceptions
    try {
        &WebFetch::fetch_main2;
    } catch {

        # process any error/exception that we may have gotten
        my $ex = $_;

        # determine if there's an error message available to display
        my $pkg = __PACKAGE__;
        if ( ref $ex ) {
            if ( my $ex_cap = Exception::Class->caught("WebFetch::Exception") ) {
                if ( $ex_cap->isa("WebFetch::TracedException") ) {
                    warn $ex_cap->trace->as_string, "\n";
                }

                croak "$pkg: " . $ex_cap->error . "\n";
            }
            if ( $ex->can("stringify") ) {

                # Error.pm, possibly others
                croak "$pkg: " . $ex->stringify . "\n";
            } elsif ( $ex->can("as_string") ) {

                # generic - should work for many classes
                croak "$pkg: " . $ex->as_string . "\n";
            } else {
                croak "$pkg: unknown exception of type " . ( ref $ex ) . "\n";
            }
        } else {
            croak "pkg: $_\n";
        }
    };

    # success
    return 0;
}

# Search for modules which have registered "cmdline" capability.
# Collect command-line options and usage info from modules.
sub collect_cmdline
{
    my ( @mod_options, @mod_usage );
    if ( ( exists $modules{cmdline} ) and ( ref $modules{cmdline} eq "ARRAY" ) ) {
        foreach my $cli_mod ( @{ $modules{cmdline} } ) {

            # obtain ref to module symbol table for backward compatibility with old @Options/$Usage interface
            my $symtab;
            {
                ## no critic (TestingAndDebugging::ProhibitNoStrict)
                no strict 'refs';
                $symtab = \%{ $cli_mod . "::" };
            }

            # get command line options - try WebFetch config first (preferred), otherwise module symtab (deprecated)
            if ( WebFetch->has_config("Options") ) {
                push @mod_options, WebFetch->config("Options");
            } elsif ( ( exists $symtab->{Options} )
                and int @{ $symtab->{Options} } )
            {
                push @mod_options, @{ $symtab->{Options} };
            }

            # get command line usage - try WebFetch config first (preferred), otherwise module symtab (deprecated)
            if ( WebFetch->has_config("Usage") ) {
                push @mod_usage, WebFetch->config("Usage");
            } elsif ( ( exists $symtab->{Usage} )
                and defined ${ $symtab->{Usage} } )
            {
                push @mod_usage, ${ $symtab->{Usage} };
            }
        }
    }
    return ( \@mod_options, \@mod_usage );
}

# mainline which fetch_main() calls in an exception catching wrapper
sub fetch_main2
{

    # search for modules which have registered "cmdline" capability
    # collect their command line options
    my ( @mod_options, @mod_usage );
    {
        my ( $mod_options_ref, $mod_usage_ref ) = collect_cmdline();
        @mod_options = @$mod_options_ref;
        @mod_usage   = $mod_usage_ref;
    }

    # process command line
    my ( $options_result, %options );
    try {
        $options_result = GetOptions(
            \%options, "dir:s",         "group:s",    "mode:s", "source=s", "source_format:s",
            "dest=s",  "dest_format:s", "fetch_urls", "quiet",  "debug",    @mod_options
        )
    } catch {
        throw_getopt_error("command line processing failed: $_");
    };
    if ( not $options_result ) {
        throw_cli_usage( "usage: $0 --dir dirpath "
                . "[--group group] [--mode mode] "
                . "[--source file] [--source_format fmt-string] "
                . "[--dest file] [--dest_format fmt-string] "
                . "[--fetch_urls] [--quiet] "
                . join( " ", @mod_usage ) );
    }

    # set debugging mode
    if ( ( exists $options{debug} ) and $options{debug} ) {
        WebFetch::debug_mode(1);
    }
    debug "fetch_main2";

    # if either source/input or dest/output formats were not provided,
    # check if only one handler is registered - if so that's the default
    if ( not exists $options{source_format} ) {
        if ( my $fmt = singular_handler("input") ) {
            $options{source_format} = $fmt;
        }
    }
    if ( not exists $options{dest_format} ) {
        if ( my $fmt = singular_handler("output") ) {
            $options{dest_format} = $fmt;
        }
    }

    # check for modules to handle the specified source_format
    my ( @handlers, %handlers );
    if (    ( exists $modules{input}{ $options{source_format} } )
        and ( ref $modules{input}{ $options{source_format} } eq "ARRAY" ) )
    {
        foreach my $handler ( @{ $modules{input}{ $options{source_format} } } ) {
            if ( not exists $handlers{$handler} ) {
                push @handlers, $handler;
                $handlers{$handler} = 1;
            }
        }
    }
    if ( exists $default_modules{ $options{source_format} } ) {
        my $handler = $default_modules{ $options{source_format} };
        if ( not exists $handlers{$handler} ) {
            push @handlers, $handler;
            $handlers{$handler} = 1;
        }
    }

    # check if any handlers were found for this input format
    if ( not @handlers ) {
        throw_no_handler( "input handler not found for " . $options{source_format} );
    }

    # run the available handlers until one succeeds or none are left
    my $run_count = 0;
    foreach my $pkgname (@handlers) {
        debug "running for $pkgname";
        try {
            &WebFetch::run( $pkgname, \%options )
        } catch {
            print STDERR "WebFetch: run exception: $_\n";
        } finally {
            if ( not @_ ) {
                $run_count++;
                last;
            }
        };
    }
    if ( $run_count == 0 ) {
        throw_no_run( "no handlers were able or available to process " . " source format" );
    }
    return 1;
}

# allocate a new object
sub new
{
    my ( $class, @args ) = @_;
    my $self = {};
    bless $self, $class;

    # initialize the object parameters
    $self->init(@args);

    # register WebFetch-provided formatters
    WebFetch->module_register(@WebFetch_formatters);

    # go fetch the data
    # this function must be provided by a derived module
    # non-fetching modules (i.e. data) must define $self->{no_fetch}=1
    if ( ( not exists $self->{no_fetch} ) or not $self->{no_fetch} ) {
        require WebFetch::Data::Store;
        if ( exists $self->{data} ) {
            $self->{data}->isa("WebFetch::Data::Store")
                or throw_data_wrongtype "object data must be " . "a WebFetch::Data::Store";
        } else {
            $self->{data} = WebFetch::Data::Store->new();
        }
        $self->fetch();
    }

    # the object has been created
    return $self;
}

# initialize attributes of new objects
sub init
{
    my ( $self, @args ) = @_;
    return if not @args;

    # convert parameter list to hash
    my %params = @args;

    # set parameters into $self with the set_param() method
    foreach my $key ( keys %params ) {
        $self->set_param( $key, $params{$key} );
    }
    return;
}

sub set_param
{
    my ( $self, $key, $value ) = @_;

    if ( exists $redirect_params{$key} ) {

        # reorganize parameters known to belong in a sub-hash
        # configure this in %redirect_params constant
        my $hash_name = $redirect_params{$key};

        # make sure we can move the parameter to the sub-hash
        if ( not $self->{$hash_name} ) {
            $self->{$hash_name} = {};
        } else {
            if ( reftype( $self->{$hash_name} ) ne "HASH" ) {
                throw_param_error( "unable to redirect '$key' parameter into '$hash_name' "
                        . "because it already exists and is not a hash" );
            }
        }

        # set the value in the destination sub-hash
        $self->{$hash_name}{$key} = $value;
    } else {

        # if not intercepted, set the value directly to the key name
        $self->{$key} = $value;
    }
    return;
}

sub mod_load
{
    my $pkg = shift;

    # make sure we have the run package loaded
    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    try {
        eval "require $pkg" or croak $@;
    } catch {
        throw_mod_load_failure("failed to load $pkg: $_");
    };
    return;
}

# command-line handling for WebFetch-derived classes
sub run
{
    my $run_pkg     = shift;
    my $options_ref = shift;
    my $obj;

    debug "entered run for $run_pkg";
    my $test_probe_ref =
        ( ( exists $options_ref->{test_probe} ) and ( ref $options_ref->{test_probe} eq "HASH" ) )
        ? $options_ref->{test_probe}
        : undef;

    # make sure we have the run package loaded
    mod_load $run_pkg;

    # Note: in order to add WebFetch-embedding capability, the fetch
    # routine saves its raw data without any HTML/XML/etc formatting
    # in @{$obj->{data}} and data-to-savable conversion routines in
    # %{$obj->{actions}}, which contains several structures with key
    # names matching software processing features.  The purpose of
    # this is to externalize the captured data so other software can
    # use it too.

    # create the new object
    # this also calls the $obj->fetch() routine for the module which
    # has inherited from WebFetch to do this
    debug "run before new";
    try {
        $obj = $run_pkg->new(%$options_ref);
    } catch {
        throw_mod_run_failure( "module run failure in $run_pkg: " . $_ );
    };
    if ($test_probe_ref) {
        $test_probe_ref->{webfetch} = $obj;
    }

    # if the object had data for the WebFetch-embedding API,
    # then data processing is external to the fetch routine
    # (This externalizes the data for other software to capture it.)
    debug "run before output";
    my $dest_format = $obj->{dest_format};
    if ( not exists $obj->{actions} ) {
        $obj->{actions} = {};
    }
    if ( ( exists $obj->{data} ) ) {
        if ( exists $obj->{dest} ) {
            if ( not exists $obj->{actions}{$dest_format} ) {
                $obj->{actions}{$dest_format} = [];
            }
            push @{ $obj->{actions}{$dest_format} }, [ $obj->{dest} ];
        }

        # perform requested actions on the data
        $obj->do_actions();
    } else {
        throw_no_save("save failed: no data or nowhere to save it");
    }

    debug "run before save";
    my $result      = $obj->save();
    my $result_code = $result ? 0 : 1;
    if ($test_probe_ref) {
        $test_probe_ref->{result} = $result_code;
    }

    # check for errors, throw exception to report errors per savable item
    if ( not $result ) {
        my @errors;
        foreach my $savable ( @{ $obj->{savable} } ) {
            ( ref $savable eq "HASH" ) or next;
            if ( exists $savable->{error} ) {
                push @errors, "file: " . $savable->{file} . "error: " . $savable->{error};
            }
        }
        if ($test_probe_ref) {
            $test_probe_ref->{errors} = \@errors;
        }
        if (@errors) {
            throw_save_error( "error saving results in " . $obj->{dir} . "\n" . join( "\n", @errors ) . "\n" );
        }
    }

    return $result_code;
}

sub do_actions
{
    my ($self) = @_;
    debug "in WebFetch::do_actions";

    # we *really* need the data and actions to be set!
    # otherwise assume we're in WebFetch 0.09 compatibility mode and
    # $self->fetch() better have created its own savables already
    if ( ( not exists $self->{data} ) or ( not exists $self->{actions} ) ) {
        return;
    }

    # loop through all the actions
    foreach my $action_spec ( keys %{ $self->{actions} } ) {
        my $handler_ref;

        # check for modules to handle the specified dest_format
        my $action_handler = "fmt_handler_" . $action_spec;
        if ( exists $modules{output}{$action_spec} ) {
            foreach my $class ( @{ $modules{output}{$action_spec} }, ref $self ) {
                if ( my $func_ref = $class->can($action_handler) ) {
                    $handler_ref = $func_ref;
                    last;
                }
            }
        }

        if ( defined $handler_ref ) {

            # loop through action spec entries (parameter lists)
            foreach my $entry ( @{ $self->{actions}{$action_spec} } ) {

                # parameters must be in an ARRAY ref
                if ( ref $entry ne "ARRAY" ) {
                    warn "warning: entry in action spec " . "\""
                        . $action_spec . "\""
                        . "expected to be ARRAY, found "
                        . ( ref $entry )
                        . " instead "
                        . "- ignored\n";
                    next;
                }

                # everything looks OK - call the handler
                &$handler_ref( $self, @$entry );

                # if there were errors, the handler should
                # have created a savable entry which
                # contains only the error entry so that
                # it will be reported by $self->save()
            }
        } else {
            warn "warning: action \"$action_spec\" specified but "
                . "$action_handler}() method not accessible in "
                . ( ref $self )
                . " or output classes - ignored\n";
        }
    }
    return;
}

# placeholder for fetch routines by derived classes
sub fetch
{
    throw_abstract "fetch is an abstract function and must be overridden by a subclass";
}

# utility function to get the contents of a URL
sub get
{
    my ( $self, $source ) = @_;

    if ( not defined $source ) {
        $source = $self->{source};
    }
    debug "get(" . $source . ")\n";

    # send request, capture response
    my $ua = LWP::UserAgent->new;
    $ua->agent( "WebFetch/" . WebFetch->version() . " " . $ua->agent );
    my $request  = HTTP::Request->new( GET => $source );
    my $response = $ua->request($request);

    # abort on failure
    if ( $response->is_error ) {
        WebFetch::Exception::NetworkGet->throw( "The request received an error: " . $response->as_string );
    }

    # return the content
    my $content = $response->content;
    return \$content;
}

# utility function to generate WebFetch Export format
# which WebFetch users can read with the WebFetch::General module
# wf_export() is grandfathered out of Subroutines::ProhibitManyArgs restriction since it predates perlcritic/PBP
## no critic ( Subroutines::ProhibitManyArgs )
sub wf_export
{
    my ( $self, $filename, $fields, $lines, $comment, $param ) = @_;
    my @export_out;
    my $delim = "";    # blank line is delimeter

    debug "entered wf_export, output to $filename\n";

    # validate parameters
    if ( not ref $fields or ref $fields ne "ARRAY" ) {
        die "WebFetch: export error: fields parameter is not an " . "array reference\n";
    }
    if ( not ref $lines or ref $lines ne "ARRAY" ) {
        die "WebFetch: export error: lines parameter is not an " . "array reference\n";
    }
    if ( ( defined $param ) and ref $param ne "HASH" ) {
        die "WebFetch: export error: param parameter is not an " . "hash reference\n";
    }

    # generate output header
    push @export_out, "[WebFetch export]";
    push @export_out, "Version: " . WebFetch->version();
    push @export_out, "# This was generated by the Perl5 WebFetch " . WebFetch->version() . " module.";
    push @export_out, "# WebFetch info can be found at " . "http://www.webfetch.org/";
    if ( defined $comment ) {
        push @export_out, "#";
        foreach my $c_line ( split( "\n", $comment ) ) {
            push @export_out, "# $c_line";
        }
    }

    # generate contents, each field has items in RFC822-like style
    foreach my $line (@$lines) {
        push @export_out, $delim;
        my ( $field, $item );
        for ( $field = 0 ; $field <= $#{@$fields} ; $field++ ) {
            $item = $line->[$field];
            ( defined $item ) or last;
            $item =~ s/\n\n+/\n/sgox;       # remove blank lines
            $item =~ s/^\n+//ox;            # remove leading newlines
            $item =~ s/\n+$//ox;            # remove trailing newlines
            $item =~ s/\n/\\\n    /sgox;    # escape newlines with "\"
            push @export_out, $fields->[$field] . ": $item";
        }
    }

    # store contents
    $self->raw_savable( $filename, join( "\n", @export_out ) . "\n" );
    return;
}
## critic ( Subroutines::ProhibitManyArgs )

# accessors & utilities for use by html_gen
sub _style_para    { my $self = shift; return ( exists $self->{style}{para} )    ? $self->{style}{para}    : 0; }
sub _style_notable { my $self = shift; return ( exists $self->{style}{notable} ) ? $self->{style}{notable} : 0; }
sub _style_ul      { my $self = shift; return ( exists $self->{style}{ul} )      ? $self->{style}{ul}      : 0; }

sub _style_bullet
{
    my $self = shift;
    return 1
        if not exists $self->{style}{para}
        and not exists $self->{style}{ul}
        and not exists $self->{style}{bullet};
    return ( exists $self->{style}{bullet} ) ? $self->{style}{bullet} : 0;
}

sub _html_gen_tag
{
    my ( $self, $tag, %params ) = @_;
    my $close_tag = 0;
    if ( exists $params{_close} ) {
        $close_tag = $params{_close} ? 1 : 0;
        delete $params{_close};
    }
    my $css_class = exists $self->{css_class} ? $self->{css_class} : "webfetch";
    return
          "<$tag class=\"$css_class-$tag\" "
        . join( " ", grep { "$_=\"" . $params{$_} . "\"" } keys %params )
        . ( $close_tag ? "/" : "" ) . ">";
}
sub _html_gen_untag { my ( $self, $tag ) = @_; return "</$tag>"; }

# utility function to generate HTML output
sub html_gen
{
    my ( $self, $filename, $format_func, $links ) = @_;

    # generate summary HTML links
    my $link_count = 0;
    my @result;

    if ( not $self->_style_notable() ) {
        push @result, $self->_html_gen_tag("center");
        push @result, $self->_html_gen_tag("table");
        push @result, $self->_html_gen_tag("tr");
        push @result, $self->_html_gen_tag( "td", valign => 'top' );
    }
    if ( $self->_style_ul() ) {
        push @result, $self->_html_gen_tag("ul");
    }
    $self->font_start( \@result );
    if ( @$links >= 0 ) {
        foreach my $entry (@$links) {
            push @result,
                (
                  $self->_style_ul()
                ? $self->_html_gen_tag("li")
                : ( $self->_style_bullet() ? "&#149;&nbsp;" : "" )
                ) . &$format_func(@$entry);
            if ( ++$link_count >= $self->{num_links} ) {
                last;
            }
            if (    ( exists $self->{table_sections} )
                and not $self->_style_para()
                and not $self->_style_notable()
                and $link_count == int( ( $self->{num_links} + 1 ) / $self->{table_sections} ) )
            {
                $self->font_end( \@result );
                push @result, $self->_html_gen_untag("td");
                push @result, $self->_html_gen_tag( "td", width => '45%', valign => 'top' );
                $self->font_start( \@result );
            } else {
                if ( $self->_style_para() ) {
                    push @result, $self->_html_gen_tag( "p", _close => 1 );
                } elsif ( $self->_style_bullet() ) {
                    push @result, $self->_html_gen_tag( "br", _close => 1 );
                }
            }
        }
    } else {
        push @result,
              "<i>(There are technical difficulties with "
            . "this information source.  "
            . "Please check again later.)</i>";
    }
    $self->font_end( \@result );
    if ( $self->_style_ul() ) {
        push @result, $self->_html_gen_untag("ul");
    }
    if ( not $self->_style_notable() ) {
        push @result, $self->_html_gen_untag("td");
        push @result, $self->_html_gen_untag("tr");
        push @result, $self->_html_gen_untag("table");
        push @result, $self->_html_gen_untag("center");
    }

    $self->html_savable( $filename, join( "\n", @result ) . "\n" );
    return;
}

# internal-use function font_start, used by html_gen
sub font_start
{
    my ( $self, $result ) = @_;

    if ( ( defined $self->{font_size} ) or ( defined $self->{font_face} ) ) {
        push @$result,
              "<font"
            . ( ( defined $self->{font_size} ) ? " size=" . $self->{font_size}          : "" )
            . ( ( defined $self->{font_face} ) ? " face=\"" . $self->{font_face} . "\"" : "" ) . ">";
    }
    return;
}

# internal-use function font_end, used by html_gen
sub font_end
{
    my ( $self, $result ) = @_;

    if ( ( defined $self->{font_size} ) or ( defined $self->{font_face} ) ) {
        push @$result, "</font>";
    }
    return;
}

# utility function to make a savable record for HTML text
sub html_savable
{
    my ( $self, $filename, $content ) = @_;

    $self->raw_savable( $filename,
              "<!--- begin text generated by "
            . "Perl5 WebFetch "
            . WebFetch->version()
            . " - do not manually edit --->\n"
            . "<!--- WebFetch can be found at "
            . "http://www.webfetch.org/ --->\n"
            . $content
            . "<!--- end text generated by "
            . "Perl5 WebFetch "
            . WebFetch->version()
            . " - do not manually edit --->\n" );
    return;
}

# utility function to make a savable record for raw text
sub raw_savable
{
    my ( $self, $filename, $content ) = @_;

    if ( not exists $self->{savable} ) {
        $self->{savable} = [];
    }
    push(
        @{ $self->{savable} },
        {
            'file'    => $filename,
            'content' => $content,
            ( ( exists $self->{group} ) ? ( 'group' => $self->{group} ) : () ),
            ( ( exists $self->{mode} )  ? ( 'mode'  => $self->{mode} )  : () )
        }
    );
    return;
}

sub direct_fetch_savable
{
    my ( $self, $url ) = @_;

    if ( not exists $self->{savable} ) {
        $self->{savable} = [];
    }
    my $filename = $url;
    $filename =~ s=[;?].*==x;
    $filename =~ s=^.*/==x;
    push(
        @{ $self->{savable} },
        {
            'url'   => $url,
            'file'  => $filename,
            'index' => 1,
            ( ( exists $self->{group} ) ? ( 'group' => $self->{group} ) : () ),
            ( ( exists $self->{mode} )  ? ( 'mode'  => $self->{mode} )  : () )
        }
    );
    return;
}

sub no_savables_ok
{
    my $self = shift;

    push(
        @{ $self->{savable} },
        {
            'ok_empty' => 1,
        }
    );
    return;
}

# check conditions are met to perform a save()
# internal method used by save()
sub _save_precheck
{
    my $self = shift;

    # check if we have attributes needed to proceed
    if ( not exists $self->{"dir"} ) {
        croak "WebFetch: directory path missing - required for save\n";
    }
    if ( not exists $self->{savable} ) {
        croak "WebFetch: nothing to save\n";
    }
    if ( ref( $self->{savable} ) ne "ARRAY" ) {
        croak "WebFetch: cannot save - savable is not an array\n";
    }
    return;
}

# convert link fields to savables
# internal method used by save()
sub _save_fetch_urls
{
    my $self = shift;

    # if fetch_urls is defined, turn link fields in the data to savables
    if ( ( exists $self->{fetch_urls} ) and $self->{fetch_urls} ) {
        my $entry;
        $self->data->reset_pos;
        while ( $entry = $self->data->next_record() ) {
            my $url = $entry->url;
            if ( defined $url ) {
                $self->direct_fetch_savable( $entry->url );
            }
        }
    }
    return;
}

# write new content for save operation
# internal method used by save()
sub _save_write_content
{
    my ( $self, $savable, $new_content ) = @_;

    # write content to the "new content" file
    ## no critic (InputOutput::RequireBriefOpen)
    my $new_file;
    if ( not open( $new_file, ">:encoding(UTF-8)", "$new_content" ) ) {
        $savable->{error} = "cannot open $new_content: $!";
        return 0;
    }
    if ( not print $new_file $savable->{content} ) {
        $savable->{error} = "failed to write to " . $new_content . ": $!";
        close $new_file;
        return 0;
    }
    if ( not close $new_file ) {

        # this can happen with NFS errors
        $savable->{error} = "failed to close " . $new_content . ": $!";
        return 0;
    }
    return 1;
}

# save previous main content as old backup
# internal method used by save()
sub _save_main_to_backup
{
    my ( $self, $savable, $main_content, $old_content ) = @_;

    # move the main content to the old content - now it's a backup
    if ( -f $main_content ) {
        if ( not rename $main_content, $old_content ) {
            $savable->{error} = "cannot rename " . $main_content . " to " . $old_content . ": $!";
            return 0;
        }
    }
    return 1;
}

# chgrp and chmod the "new content" before final installation
# internal method used by save()
sub _save_file_mode
{
    my ( $self, $savable, $new_content ) = @_;

    # chgrp the "new content" before final installation
    if ( exists $savable->{group} ) {
        my $gid = $savable->{group};
        if ( $gid !~ /^[0-9]+$/ox ) {
            $gid = ( getgrnam($gid) )[2];
            if ( not defined $gid ) {
                $savable->{error} = "cannot chgrp " . $new_content . ": " . $savable->{group} . " does not exist";
                return 0;
            }
        }
        if ( not chown $>, $gid, $new_content ) {
            $savable->{error} = "cannot chgrp " . $new_content . " to " . $savable->{group} . ": $!";
            return 0;
        }
    }

    # chmod the "new content" before final installation
    if ( exists $savable->{mode} ) {
        if ( not chmod oct( $savable->{mode} ), $new_content ) {
            $savable->{error} = "cannot chmod " . $new_content . " to " . $savable->{mode} . ": $!";
            return 0;
        }
    }
    return 1;
}

# check if content is already in index file
# internal method used by save()
sub _save_check_index
{
    my ( $self, $savable ) = @_;

    # if a URL was provided and index flag is set, use index file
    my %id_index;
    my ( $timestamp, $filename );
    my $was_in_index = 0;
    if ( ( exists $savable->{url} ) and ( exists $savable->{index} ) ) {
        require DB_File;
        tie %id_index, 'DB_File', $self->{dir} . "/id_index.db", &DB_File::O_CREAT | &DB_File::O_RDWR, oct(640);
        if ( exists $id_index{ $savable->{url} } ) {
            ( $timestamp, $filename ) =
                split /#/x, $id_index{ $savable->{url} };
            $was_in_index = 1;
        } else {
            $timestamp = time;
            $id_index{ $savable->{url} } =
                $timestamp . "#" . $savable->{file};
        }
        untie %id_index;
    }

    # For now, we consider it done if the file was in the index.
    # Future options would be to check if URL was modified.
    if ($was_in_index) {
        return 0;
    }
    return 1;
}

# if a URL was provided and no content, get content from URL
# internal method used by save()
sub _save_fill_empty_from_url
{
    my ( $self, $savable ) = @_;

    # if a URL was provided and no content, get content from URL
    if ( ( not exists $savable->{content} ) and ( exists $savable->{url} ) ) {
        try {
            $savable->{content} = ${ $self->get( $savable->{url} ) };
        } catch {
            return 0;
        };
    }
    return 1;
}

# print errors from save operation
# internal method used by save()
sub _save_report_errors
{
    my ($self) = @_;

    # loop through savable to report any errors
    my $err_count = 0;
    foreach my $savable ( @{ $self->{savable} } ) {
        if ( exists $savable->{error} ) {
            print STDERR "WebFetch: failed to save " . $savable->{file} . ": " . $savable->{error} . "\n";
            $err_count++;
        }
    }
    if ($err_count) {
        croak "WebFetch: $err_count errors - fetch/save failed\n";
    }
    return;
}

# file-save routines for all WebFetch-derived classes
sub save
{
    my $self = shift;

    debug "entering save()\n";

    # check if we have attributes needed to proceed
    $self->_save_precheck();

    # if fetch_urls is defined, turn link fields in the data to savables
    $self->_save_fetch_urls();

    # loop through "savable" (grouped content and filename destination)
    foreach my $savable ( @{ $self->{savable} } ) {

        if ( exists $savable->{file} ) {
            debug "saving " . $savable->{file} . "\n";
        }

        # an output module may have handled a more intricate operation
        last if ( exists $savable->{ok_empty} );

        # verify contents of savable record
        if ( not exists $savable->{file} ) {
            $savable->{error} = "missing file name - skipped";
            next;
        }
        if (    ( not exists $savable->{content} )
            and ( not exists $savable->{url} ) )
        {
            $savable->{error} = "missing content or URL - skipped";
            next;
        }

        # generate file names
        my $new_content  = $self->{"dir"} . "/N" . $savable->{file};
        my $main_content = $self->{"dir"} . "/" . $savable->{file};
        my $old_content  = $self->{"dir"} . "/O" . $savable->{file};

        # make sure the Nxx "new content" file does not exist yet
        if ( -f $new_content ) {
            if ( not unlink $new_content ) {
                $savable->{error} = "cannot unlink " . $new_content . ": $!";
                next;
            }
        }

        # if a URL was provided and index flag is set, use index file
        if ( not $self->_save_check_index($savable) ) {

            # done since it was found in the index
            next;
        }

        # if a URL was provided and no content, get content from URL
        if ( not $self->_save_fill_empty_from_url($savable) ) {

            # error occurred - available in $savable->{error}
            next;
        }

        # write content to the "new content" file
        if ( not $self->_save_write_content( $savable, $new_content ) ) {

            # error occurred - available in $savable->{error}
            next;
        }

        # remove the "old content" file to get it out of the way
        if ( -f $old_content ) {
            if ( not unlink $old_content ) {
                $savable->{error} = "cannot unlink " . $old_content . ": $!";
                next;
            }
        }

        # move the main content to the old content - now it's a backup
        if ( not $self->_save_main_to_backup( $savable, $main_content ), $old_content ) {

            # error occurred - available in $savable->{error}
            next;
        }

        # chgrp and chmod the "new content" before final installation
        if ( not $self->_save_file_mode( $savable, $new_content ) ) {

            # error occurred - available in $savable->{error}
            next;
        }

        # move the new content to the main content - final install
        if ( -f $new_content ) {
            if ( not rename $new_content, $main_content ) {
                $savable->{error} = "cannot rename " . $new_content . " to " . $main_content . ": $!";
                next;
            }
        }
    }

    # loop through savable to report any errors
    $self->_save_report_errors();

    # success if we got here
    return 1;
}

sub parse_date
{
    my @args = @_;
    my %opts;
    if ( ref $args[0] eq "HASH" ) {
        %opts = %{ shift @args };
    }
    my $stamp = shift @args;
    my $result;

    # use regular expressions to check simple date formats YYYY-MM-DD and YYYYMMDD

    # check YYYY-MM-DD date format
    # save it as a date-only array which can be fed to DateTime->new(), so gen_timestamp() will only use the date
    if ( $stamp =~ /^ (\d{4}) - (\d{2}) - (\d{2}) \s* $/x ) {
        $result = [ year => int($1), month => int($2), day => int($3), %opts ];

        # check YYYYMMDD format for backward compatibility: no longer ISO 8601 compliant since 2004 update
        # save it as a date-only array which can be fed to DateTime->new(), so gen_timestamp() will only use the date
    } elsif ( $stamp =~ /^ (\d{4}) (\d{2}) (\d{2}) \s* $/x ) {
        $result = [ year => int($1), month => int($2), day => int($3), %opts ];
    }

    # check ISO 8601
    # catch any exceptions thrown by the DateTime::Format::ISO8601 constructor and leave $result undefined
    # save it as a DateTime object
    if ( not defined $result ) {
        try {
            $result = DateTime::Format::ISO8601->parse_datetime( $stamp, $opts{locale} );
            if ( exists $opts{time_zone}
                and $result->time_zone() eq "floating" )
            {
                $result->set_time_zone( $opts{time_zone} );
            }
        };
    }

    # check Unix date format and other misc processing from Date::Calc's Parse_Date()
    # save it as a date-only array which can be fed to DateTime->new(), so gen_timestamp() will only use the date
    if ( not defined $result ) {
        my @date;
        try {
            @date = Date::Calc::Parse_Date( $stamp, $opts{locale} );
        };
        if (@date) {
            $result =
                [ year => $date[0], month => $date[1], day => $date[2], %opts ];
        }
    }

    # return parsed result, or undef if all parsing methods failed
    return $result;
}

sub gen_timestamp
{
    my @args = @_;
    my %opts;
    if ( ref $args[0] eq "HASH" ) {
        %opts = %{ shift @args };
    }

    my $datetime;
    my $date_only = 0;    # boolean flag: true = use date only, false = full timestamp
    if ( ref $args[0] ) {
        if ( ref $args[0] eq "DateTime" ) {
            $datetime = $args[0];
            if ( exists $opts{locale} ) {
                try {
                    $datetime->set_locale( $opts{locale} );
                };
            }
            if ( exists $opts{time_zone} ) {
                try {
                    $datetime->set_time_zone( $opts{time_zone} );
                };
            }
        } elsif ( ref $args[0] eq "ARRAY" ) {
            my %dt_opts = @{ $args[0] };
            foreach my $key ( keys %opts ) {

                # if provided, use %opts as DateTime defaults for locale, time_zone and any other keys found
                if ( not exists $dt_opts{$key} ) {
                    $dt_opts{$key} = $opts{$key};
                }
            }
            $datetime  = DateTime->new(%dt_opts);
            $date_only = 1;
        }
    }

    # generate locale-specific timestamp string
    my $dt_locale = $datetime->locale();
    if ($date_only) {
        return $datetime->format_cldr( $dt_locale->date_format_full );
    }
    return $datetime->format_cldr( $dt_locale->datetime_format_full );
}

sub anchor_timestr
{
    my @args = @_;
    my %opts;
    if ( ref $args[0] eq "HASH" ) {
        %opts = %{ shift @args };
    }

    my $datetime;
    my $date_only = 0;    # boolean flag: true = use date only, false = full timestamp
    if ( ref $args[0] ) {
        if ( ref $args[0] eq "DateTime" ) {
            $datetime = $args[0];
            if ( exists $opts{time_zone} ) {
                try {
                    $datetime->set_time_zone( $opts{time_zone} );
                };
            }
        } elsif ( ref $args[0] eq "ARRAY" ) {
            my %dt_opts = @{ $args[0] };
            foreach my $key ( keys %opts ) {

                # if provided, use %opts as DateTime defaults for locale, time_zone and any other keys found
                if ( not exists $dt_opts{$key} ) {
                    $dt_opts{$key} = $opts{$key};
                }
            }
            $datetime  = DateTime->new(%dt_opts);
            $date_only = 1;
        }
    }

    # generate anchor timestamp string
    return "undated" if not defined $datetime;
    if ($date_only) {
        return $datetime->ymd('-');
    }
    return $datetime->ymd('-') . "-" . $datetime->hms('-');
}

#
# shortcuts to data object functions
#

sub data { my $self = shift; return $self->{data}; }
sub wk2fname { my ( $self, @args ) = @_; return $self->{data}->wk2fname(@args) }

sub fname2fnum
{
    my ( $self, @args ) = @_;
    return $self->{data}->fname2fnum(@args);
}
sub wk2fnum { my ( $self, @args ) = @_; return $self->{data}->wk2fnum(@args) }

#
# format handler functions
# these do not have their own POD docs, but are defined in the
# $obj->do_actions() docs above
#

# HTML format handler
sub fmt_handler_html
{
    my ( $self, $filename, $params ) = @_;
    my $records = $self->{data}{records};

    # if we need to filter or sort, make a copy of the data records
    if (   ( defined $params->{filter_func} )
        or ( defined $params->{sort_func} ) )
    {
        # filter/select items in the table if filter function exists
        my $i;
        if ( ( defined $params->{filter_func} )
            and ref $params->{filter_func} eq "CODE" )
        {
            # create the new table
            $records = [];

            for ( $i = 0 ; $i < scalar( @{ $self->{data}{records} } ) ; $i++ ) {
                if ( &{ $params->{filter_func} }( @{ $self->{data}{records}[$i] } ) ) {
                    unshift @$records, $self->{data}{records}[$i];
                }
            }
        } else {

            # copy all the references in the table over
            # don't mess with the data itself
            $records = [ @{ $self->{data}{records} } ];
        }

        # sort the table if sort/compare function is present
        if ( ( defined $params->{sort_func} )
            and ref $params->{sort_func} eq "CODE" )
        {
            $records = [ sort { &{ $params->{sort_func} }( $a, $b ) } @$records ];
        }
    }

    if ( ( defined $params->{format_func} )
        and ref $params->{format_func} eq "CODE" )
    {
        $self->html_gen( $filename, $params->{format_func}, $records );
        return;
    }

    # get local copies of the values from wk2fnum so that we can
    # take advantage of closure scoping to grab these values instead
    # of doing a table lookup for every value every time the format
    # function iterates over every data item
    my ( $title_fnum, $url_fnum, $date_fnum, $summary_fnum, $comments_fnum ) = (
        $self->wk2fnum("title"), $self->wk2fnum("url"), $self->wk2fnum("date"), $self->wk2fnum("summary"),
        $self->wk2fnum("comments"),
    );

    # generate the html and formatting function
    # This does a lot of conditional inclusion of well-known fields,
    # depending on their presence in a give data record.
    # The $_[...] notation is used to grab the data because this
    # anonymous function will be run once for every record in
    # @{$self->{data}{records}} with the data array/record passed
    # to it as the function's parameters.
    $self->html_gen(
        $filename,
        sub {
            return ""
                . (
                ( defined $title_fnum )
                ? (
                    ( defined $url_fnum )
                    ? "<a href=\"" . $_[$url_fnum] . "\">"
                    : ""
                    )
                    . $_[$title_fnum]
                    . (
                    ( defined $url_fnum )
                    ? "</a>"
                    : ""
                    )
                : (
                    ( defined $summary_fnum )
                    ? $_[$summary_fnum]
                    : ""
                )
                )
                . (
                ( defined $comments_fnum )
                ? " (" . $_[$comments_fnum] . ")"
                : ""
                );
        },
        $records
    );
    return;
}

# XML format handler
# This generates a "standalone" XML document with its own built-in DTD
# to define the fields.
# Note: we couldn't use XML::Writer because it only writes to a filehandle
# and we need to do some more complicated stuff here.
sub fmt_handler_xml
{
    my ( $self, $filename ) = @_;
    my ( @xml, $field, $indent );

    # generate XML prolog/heading with a dynamically-generated XML DTD
    $indent = " " x 4;
    push @xml, "<?xml version=\"1.0\" standalone=\"yes\" ?>";
    push @xml, "";
    push @xml, "<!DOCTYPE webfetch_dynamic [";
    push @xml, $indent . "<!ELEMENT webfetch_dynamic (record*)>";
    push @xml, $indent . "<!ELEMENT record (" . join( ", ", @{ $self->{data}{fields} } ) . ")>";
    for ( $field = 0 ; $field < scalar @{ $self->{data}{fields} } ; $field++ ) {
        push @xml, $indent . "<!ELEMENT " . $self->{data}{fields}[$field] . "(#PCDATA)>";
    }
    push @xml, "]>";
    push @xml, "";

    # generate XML content
    push @xml, "<webfetch_dynamic>";
    foreach my $record ( @{ $self->{data}{records} } ) {
        push @xml, $indent . "<record>";
        for ( $field = 0 ; $field < scalar @{ $self->{data}{fields} } ; $field++ ) {
            push @xml,
                  ( $indent x 2 ) . "<"
                . $self->{data}{fields}[$field] . ">"
                . $record->[$field] . "</"
                . $self->{data}{fields}[$field] . ">";
        }
        push @xml, $indent . "</record>";
    }
    push @xml, "</webfetch_dynamic>";

    # store the XML text as a savable
    $self->raw_savable( $filename, join( "\n", @xml ) . "\n" );
    return;
}

# WebFetch::General format handler
sub fmt_handler_wf
{
    my ( $self, $filename ) = @_;

    $self->wf_export(
        $filename,
        $self->{data}{fields},
        $self->{data}{records},
        "Exported from " . ( ref $self ) . "\n" . "fields are " . join( ", ", @{ $self->{data}{fields} } ) . "\n"
    );
    return;
}

# RDF format handler
sub fmt_handler_rdf
{
    my ( $self, $filename, $site_title, $site_link, $site_desc, $image_title, $image_url ) = @_;

    # get the field numbers for the well-known fields for title and url
    my ( $title_fnum, $url_fnum, );
    $title_fnum = $self->wk2fnum("title");
    $url_fnum   = $self->wk2fnum("url");

    # if title or url is missing, we have to abort with an error message
    if ( ( not defined $title_fnum ) or ( not defined $url_fnum ) ) {
        my %savable = (
            "file"  => $filename,
            "error" => "cannot RDF export with missing fields: "
                . ( ( not defined $title_fnum ) ? "title " : "" )
                . ( ( not defined $url_fnum )   ? "url "   : "" )
        );
        if ( not defined $self->{savable} ) {
            $self->{savable} = [];
        }
        push @{ $self->{savable} }, \%savable;
        return;
    }

    # check if we can shortcut the array processing
    my $data;
    if ( $title_fnum == 0 and $url_fnum == 1 ) {
        $data = $self->{data}{records};
    } else {

        # oh well, the fields weren't in the right order
        # extract a copy that contains title and url fields
        $data = [];
        foreach my $entry ( @{ $self->{data}{records} } ) {
            push @$data, [ $entry->[$title_fnum], $entry->[$url_fnum] ];
        }
    }
    $self->ns_export( $filename, $data, $site_title, $site_link, $site_desc, $image_title, $image_url );
    return;
}

# autoloader catches calls to unknown functions
# redirect to the class which made the call, if the function exists
## no critic (ClassHierarchies::ProhibitAutoloading)
sub AUTOLOAD
{
    my ( $self, @args ) = @_;
    my $name = $AUTOLOAD;
    my $type = ref($self)
        or throw_autoload_fail "AUTOLOAD failed on $name: self is not an object";

    $name =~ s/.*://x;    # strip fully-qualified portion, just want function

    # decline all-caps names - reserved for special Perl functions
    my ( $package, $filename, $line ) = caller;
    ( $name =~ /^[A-Z]+$/x ) and return;
    debug __PACKAGE__ . "::AUTOLOAD $name";

    # check for function in caller package
    # (WebFetch may hand an input module's object to an output module)
    if ( not $package->can($name) ) {

        # throw exception for unknown function/method
        throw_autoload_fail "function $name not found - called by $package ($filename line $line)";
    }

    # make an alias of the sub
    {
        ## no critic (TestingAndDebugging::ProhibitNoStrict)
        no strict 'refs';
        *{ __PACKAGE__ . "::" . $name } = \&{ $package . "::" . $name };
    }
    my $retval;
    try {
        $retval = $self->$name(@args);
    } catch {
        my $e = Exception::Class->caught();
        ref $e
            ? $e->rethrow
            : throw_autoload_fail "failure in " . "autoloaded function: " . $e;
    };
    return $retval;
}
## critic (ClassHierarchies::ProhibitAutoloading)

1;

=pod

=encoding UTF-8

=head1 NAME

WebFetch - Perl module to download/fetch and save information from the Web

=head1 VERSION

version 0.15.1

=head1 SYNOPSIS

  use WebFetch;

=head1 DESCRIPTION

The WebFetch module is a framework for downloading and saving
information from the web, and for saving or re-displaying it.
It provides a generalized interface for saving to a file
while keeping the previous version as a backup.
This is mainly intended for use in a cron-job to acquire
periodically-updated information.

WebFetch allows the user to specify a source and destination, and
the input and output formats.  It is possible to write new Perl modules
to the WebFetch API in order to add more input and output formats.

The currently-provided input formats are Atom, RSS, WebFetch "SiteNews" files
and raw Perl data structures.

The currently-provided output formats are RSS, WebFetch "SiteNews" files,
the Perl Template Toolkit, and export into a TWiki site.

Some modules which were specific to pre-RSS/Atom web syndication formats
have been deprecated.  Those modules can be found in the CPAN archive
in WebFetch 0.10.  Those modules are no longer compatible with changes
in the current WebFetch API.

=head1 INSTALLATION

After unpacking and the module sources from the tar file, run

C<perl Makefile.PL>

C<make>

C<make install>

Or from a CPAN shell you can simply type "C<install WebFetch>"
and it will download, build and install it for you.

If you need help setting up a separate area to install the modules
(i.e. if you don't have write permission where perl keeps its modules)
then see the Perl FAQ.

To begin using the WebFetch modules, you will need to test your
fetch operations manually, put them into a crontab, and then
use server-side include (SSI) or a similar server configuration to 
include the files in a live web page.

=head2 MANUALLY TESTING A FETCH OPERATION

Select a directory which will be the storage area for files created
by WebFetch.  This is an important administrative decision -
keep the volatile automatically-generated files in their own directory
so they'll be separated from manually-maintained files.

Choose the specific WebFetch-derived modules that do the work you want.
See their particular manual/web pages for details on command-line arguments.
Test run them first before committing to a crontab.

=head2 SETTING UP CRONTAB ENTRIES

If needed, see the manual pages for crontab(1), crontab(5) and any
web sites or books on Unix system administration.

Since WebFetch command lines are usually very long, the user may prefer
to make one or more scripts as front-ends so crontab entries aren't so big.

Try not to run crontab entries too often - be aware if the site you're
accessing has any resource constraints, and how often their information
gets updated.  If they request users not to access a feed more often
than a certain interval, respect it.  (It isn't hard to find violators
in server logs.)  If in doubt, try every 30 minutes until more information
becomes available.

=head1 WebFetch FUNCTIONS AND METHODS

The following function definitions assume B<C<$obj>> is a blessed
reference to a module that is derived from (inherits from) WebFetch.

=over 4

=item WebFetch->version()

Return the version number of WebFetch, or for any subclass which inherits the method.

When running code within a source-code development workspace, it returns "00-dev" to avoid warnings
about undefined values.
Release version numbers are assigned and added by the build system upon release,
and are not available when running directly from a source code repository.

=item WebFetch->config( $key, [$value])

This class method is the read/write accessor to WebFetch's key/value configuration store.
If $value is not provided (or is undefied) then this is a read accessor, returning the value of the
configuration entry named by $key.
If $value is defined then this is a write accessor, assigning $value to the configuration entry named by $key.

=item WebFetch->has_config($key)

This class method returns a boolean value which is true if the configuration entry named by $key exists
in the WebFetch key/value configuration store. Otherwise it returns false.

=item WebFetch->del_config($key)

This class method deletes the configuration entry named by $key.

=item WebFetch->import_config(\%hashref)

This class method imports all the key/value pairs from %hashref into the WebFetch configuration.

=item WebFetch->keys_config()

This class method returns a list of the keys in the WebFetch configuration store.
This method was made for testing purposes. That is currently its only foreseen use case.

=item WebFetch::module_register( $module, @capabilities );

This function allows a Perl module to register itself with the WebFetch API
as able to perform various capabilities.

For subclasses of WebFetch, it can be called as a class method.
   C<__PACKAGE__-&gt;module_register( @capabilities );>

For the $module parameter, the Perl module should provide its own
name, usually via the __PACKAGE__ string.

@capabilities is an array of strings as needed to list the
capabilities which the module performs for the WebFetch API.

If any entry of @capabilities is a hash reference, its key/value
pairs are all imported to the WebFetch configuration, and becomes accessible via
the I<config()> method. For more readable code, a hashref parmeter should not be used more than once.
Though that would work. Also for readability, it is recommended to make the hashref the first
parameter when this feature is used.

Except for the config hashref, parameters must be strings as follows.

The currently-recognized capabilities are "cmdline", "input" and "output".
"filter", "save" and "storage" are reserved for future use.  The
function will save all the capability names that the module provides, without
checking whether any code will use it.

For example, the WebFetch::Output::TT module registers itself like this:
   C<__PACKAGE__-&gt;module_register( "cmdline", "output:tt" );>
meaning that it defines additional command-line options, and it provides an
output format handler for the "tt" format, the Perl Template Toolkit.

=item fetch_main

This function is exported into the main package.
For all modules which registered with an "input" capability for the requested
file format at the time this is called, it will call the run() function on
behalf of each of the packages.

=item $obj = WebFetch::new( param => "value", [...] )

Generally, the new function should be inherited and used from a derived
class.  However, WebFetch provides an AUTOLOAD function which will catch
wayward function calls from a subclass, and redirect it to the appropriate
function in the calling class, if it exists.

The AUTOLOAD feature is needed because, for example, when an object is
instantiated in a WebFetch::Input::* class, it will later be passed to
a WebFetch::Output::* class, whose data method functions can be accessed
this way as if the WebFetch object had become a member of that class.

=item $obj->init( ... )

This is called from the C<new> function that modules inherit from WebFetch.
If subclasses override it, they should still call it before completion.
It takes "name" => "value" pairs which are all placed verbatim as
attributes in C<$obj>.

=item $obj->set_param(key, value)

This sets a value under the given key in the WebFetch object.

Some keys are intercepted to be grouped into their own sub-hierarchy.
The keys "locale" and "time_zone" are placed in a "datetime_settings" hash under the object.

If the parameter is one of the intercepted values but the destination hierarchy already exists as a
non-hash value, then it throws an exception.

The method does not return a value. If it doens't throw an exception, other outcomes are success.

=item WebFetch::mod_load ( $class )

This specifies a WebFetch module (Perl class) which needs to be loaded.
In case of an error, it throws an exception.

=item WebFetch::run

This function can be called by the C<main::fetch_main> function
provided by WebFetch or by another user function.
This handles command-line processing for some standard options,
calling the module-specific fetch function and WebFetch's $obj->save
function to save the contents to one or more files.

The command-line processing for some standard options are as follows:

=over 4

=item --dir I<directory>

(required) the directory in which to write output files

=item --group I<group>

(optional) the group ID to set the output file(s) to

=item --mode I<mode>

(optional) the file mode (permissions) to set the output file(s) to

=item --save_file I<save-file-path>

(optional) save a copy of the fetched info
in the file named by this parameter.
The contents of the file are determined by the C<--dest_format> parameter.
If C<--dest_format> isn't defined but only one module has registered a
file format for saving, then that will be used by default.

=item --quiet

(optional) suppress printed warnings for HTTP errors
I<(applies only to modules which use the WebFetch::get() function)>
in case they are not desired for cron outputs

=item --debug

(optional) print verbose debugging outputs,
only useful for developers adding new WebFetch-based modules
or finding/reporting a bug in an existing module

=back

Modules derived from WebFetch may add their own command-line options
that WebFetch::run() will use by defining a WebFetch configuration entry
called "Options",
containing the name/value pairs defined in Perl's Getopts::Long module.
Derived modules can also add to the command-line usage error message by
defining a configuration entry called "Usage" with a string of the additional
parameters, as they should appear in the usage message.
See the WebFetch->module_register() and WebFetch->config() class methods
for setting configuration entries.

For backward compatibility, WebFetch also looks for @Options and $Usage
in the calling module's symbol table if they aren't found in the WebFetch
configuration. However this method is deprecated and should not be used in
new code. Perl coding best practices have evolved to recommend against using
package variables in the years since the API was first defined.

=item $obj->do_actions

I<C<do_actions> was added in WebFetch 0.10 as part of the
WebFetch Embedding API.>
Upon entry to this function, $obj must contain the following attributes:

=over 4

=item data

is a reference to a hash containing the following three (required)
keys:

=over 4

=item fields

is a reference to an array containing the names of the fetched data fields
in the order they appear in the records of the I<data> array.
This is necessary to define what each field is called
because any kind of data can be fetched from the web.

=item wk_names

is a reference to a hash which maps from
a key string with a "well-known" (to WebFetch) field type
to a field name used in this table.
The well-known names are defined as follows:

=over 4

=item title

a one-liner banner or title text
(plain text, no HTML tags)

=item url

URL or file path (as appropriate) to the news source

=item id

unique identifier string for the entry

=item date

a date stamp (and optional timestamp),
which must be program-readable as L<ISO 8601|https://en.wikipedia.org/wiki/ISO_8601>
date/time format (via L<DateTime::Format::ISO8601>),
Unix date command output (via L<Date::Calc>'s Parse_Date() function)
or as "YYYY-MM-DD" date string format.
For backward compatibility, "YYYYMMDD" format is also accepted,
though technically that format was deprecated from ISO 8601 in 2004.
If the date cannot be parsed by these methods,
either translate it to ISO 8601 when your module captures it
or do not define this well-known field.

=item summary

a paragraph of summary text in HTML

=item comments

number of comments/replies at the news site
(plain text, no HTML tags)

=item author

a name, handle or login name representing the author of the news item
(plain text, no HTML tags)

=item category

a word or short phrase representing the category, topic or department
of the news item
(plain text, no HTML tags)

=item location

a location associated with the news item
(plain text, no HTML tags)

=back

The field names for this table are defined in the I<fields> array.

The hash only maps for the fields available in the table.
If no field representing a given well-known name is present
in the data fields,
that well-known name key must not be defined in this hash.

=item records

an array containing the data records.
Each record is itself a reference to an array of strings which are
the data fields.
This is effectively a two-dimensional array or a table.

Only one table-type set of data is permitted per fetch operation.
If more are needed, they should be arranged as separate fetches
with different parameters.

=back

=item actions

is a reference to a hash.
The hash keys are names for handler functions.
The WebFetch core provides internal handler functions called
I<fmt_handler_html> (for HTML output), 
I<fmt_handler_xml> (for XML output), 
I<fmt_handler_wf> (for WebFetch::General format), 
However, WebFetch modules may provide additional
format handler functions of their own by prepending
"fmt_handler_" to the key string used in the I<actions> array.

The values are array references containing
I<"action specs">,
which are themselves arrays of parameters
that will be passed to the handler functions
for generating output in a specific format.
There may be more than one entry for a given format if multiple outputs
with different parameters are needed.

The presence of values in this field mean that output is to be
generated in the specified format.
The presence of these would have been chosed by the WebFetch module that
created them - possibly by default settings or by a command-line argument
that directed a specific output format to be used.

For each valid action spec,
a separate "savable" (contents to be placed in a file)
will be generated from the contents of the I<data> variable.

The valid (but all optional) keys are

=over 4

=item html

the value must be a reference to an array which specifies all the
HTML generation (html_gen) operations that will take place upon the data.
Each entry in the array is itself an array reference,
containing the following parameters for a call to html_gen():

=over 4

=item filename

a file name or path string
(relative to the WebFetch output directory unless a full path is given)
for output of HTML text.

=item params

a hash reference containing optional name/value parameters for the
HTML format handler.

=over 4

=item filter_func

(optional)
a reference to code that, given a reference to an entry in
@{$self->{data}{records}},
returns true (1) or false (0) for whether it will be included in the
HTML output.
By default, all records are included.

=item sort_func

(optional)
a reference to code that, given references to two entries in
@{$self->{data}{records}},
returns the sort comparison value for the order they should be in.
By default, no sorting is done and all records (subject to filtering)
are accepted in order.

=item format_func

(optional)
a refernce to code that, given a reference to an entry in
@{$self->{data}{records}},
stores a savable representation of the string.

=back

=back

=back

Additional valid keys may be created by modules that inherit from WebFetch
by supplying a method/function named with "fmt_handler_" preceding the
string used for the key.
For example, for an "xyz" format, the handler function would be
I<fmt_handler_xyz>.
The value (the "action spec") of the hash entry
must be an array reference.
Within that array are "action spec entries",
each of which is a reference to an array containing the list of
parameters that will be passed verbatim to the I<fmt_handler_xyz> function.

When the format handler function returns, it is expected to have
created entries in the $obj->{savables} array
(even if they only contain error messages explaining a failure),
which will be used by $obj->save() to save the files and print the
error messages.

For coding examples, use the I<fmt_handler_*> functions in WebFetch.pm itself.

=back

=item $obj->fetch

B<This function must be provided by each derived module to perform the
fetch operaton specific to that module.>
It will be called from C<new()> so you should not call it directly.
Your fetch function should extract some data from somewhere
and place of it in HTML or other meaningful form in the "savable" array.

TODO: cleanup references to WebFetch 0.09 and 0.10 APIs.

Upon entry to this function, $obj must contain the following attributes:

=over 4

=item dir

The name of the directory to save in.
(If called from the command-line, this will already have been provided
by the required C<--dir> parameter.)

=item savable

a reference to an array where the "savable" items will be placed by
the $obj->fetch function.
(You only need to provide an array reference -
other WebFetch functions can write to it.)

In WebFetch 0.10 and later,
this parameter should no longer be supplied by the I<fetch> function
(unless you wish to use 0.09 backward compatibility)
because it is filled in by the I<do_actions>
after the I<fetch> function is completed
based on the I<data> and I<actions> variables
that are set in the I<fetch> function.
(See below.)

Each entry of the savable array is a hash reference with the following
attributes:

=over 4

=item file

file name to save in

=item content

scalar w/ entire text or raw content to write to the file

=item group

(optional) group setting to apply to file

=item mode

(optional) file permissions to apply to file

=back

Contents of savable items may be generated directly by derived modules
or with WebFetch's C<html_gen>, C<html_savable> or C<raw_savable>
functions.
These functions will set the group and mode parameters from the
object's own settings, which in turn could have originated from
the WebFetch command-line if this was called that way.

=back

Note that the fetch functions requirements changed in WebFetch 0.10.
The old requirement (0.09 and earlier) is supported for backward compatibility.

I<In WebFetch 0.09 and earlier>,
upon exit from this function, the $obj->savable array must contain
one entry for each file to be saved.
More than one array entry means more than one file to save.
The WebFetch infrastructure will save them, retaining backup copies
and setting file modes as needed.

I<Beginning in WebFetch 0.10>, the "WebFetch embedding" capability was introduced.
In order to do this, the captured data of the I<fetch> function 
had to be externalized where other Perl routines could access it.  
So the fetch function now only populates data structures
(including code references necessary to process the data.)

Upon exit from the function,
the following variables must be set in C<$obj>:

=over 4

=item data

is a reference to a hash which will be used by the I<do_actions> function.
(See above.)

=item actions

is a reference to a hash which will be used by the I<do_actions> function.
(See above.)

=back

=item $obj->get

This WebFetch utility function will get a URL and return a reference
to a scalar with the retrieved contents.
Upon entry to this function, C<$obj> must contain the following attributes: 

=over 4

=item source

the URL to get

=item quiet

a flag which, when set to a non-zero (true) value,
suppresses printing of HTTP request errors on STDERR

=back

=item $obj->wf_export ( $filename, $fields, $links, [ $comment, [ $param ]] )

I<In WebFetch 0.10 and later, this should be used only in
format handler functions.  See do_handlers() for details.>

This WebFetch utility function generates contents for a WebFetch export
file, which can be placed on a web server to be read by other WebFetch sites.
The WebFetch::General module reads this format.
$obj->wf_export has the following parameters:

=over 4

=item $filename

the file to save the WebFetch export contents to;
this will be placed in the savable record with the contents
so the save function knows were to write them

=item $fields

a reference to an array containing a list of the names of the data fields
(in each entry of the @$lines array)

=item $lines

a reference to an array of arrays;
the outer array contains each line of the exported data;
the inner array is a list of the fields within that line
corresponding in index number to the field names in the $fields array

=item $comment

(optional) a Human-readable string comment (probably describing the purpose
of the format and the definitions of the fields used) to be placed at the
top of the exported file

=item $param

(optional) a reference to a hash of global parameters for the exported data.
This is currently unused but reserved for future versions of WebFetch.

=back

=item $obj->html_gen( $filename, $format_func, $links )

I<In WebFetch 0.10 and later, this should be used only in
format handler functions.  See do_handlers() for details.>

This WebFetch utility function generates some common formats of
HTML output used by WebFetch-derived modules.
The HTML output is stored in the $obj->{savable} array,
for which all the files in that array can later be saved by the
$obj->save function.
It has the following parameters:

=over 4

=item $filename

the file name to save the generated contents to;
this will be placed in the savable record with the contents
so the save function knows were to write them

=item $format_func

a refernce to code that formats each entry in @$links into a
line of HTML

=item $links

a reference to an array of arrays of parameters for C<&$format_func>;
each entry in the outer array is contents for a separate HTML line
and a separate call to C<&$format_func>

=back

Upon entry to this function, C<$obj> must contain the following attributes: 

=over 4

=item num_links

number of lines/links to display

=item savable

reference to an array of hashes which this function will use as
storage for filenames and contents to save
(you only need to provide an array reference - the function will write to it)

See $obj->fetch for details on the contents of the C<savable> parameter

=item table_sections

(optional) if present, this specifies the number of table columns to use;
the number of links from C<num_links> will be divided evenly between the
columns

=item style

(optional) a hash reference with style parameter names/values
that can modify the behavior of the funciton to use different HTML styles.
The recognized values are enumerated with WebFetch's I<--style> command line
option.
(When they reach this point, they are no longer a comma-delimited string -
WebFetch or another module has parsed them into a hash with the style
name as the key and the integer 1 for the value.)

=item url

(optional) an alternative URL to fetch from.
In WebFetch modules that fetch from a URL, this will override the default URL
in the module.
In other modules, it has no effect but its presence won't cause an error.

=back

=item $obj->html_savable( $filename, $content )

I<In WebFetch 0.10 and later, this should be used only in
format handler functions.  See do_actions() for details.>

This WebFetch utility function stores pre-generated HTML in a new entry in
the $obj->{savable} array, for later writing to a file.
It's basically a simple wrapper that puts HTML comments
warning that it's machine-generated around the provided HTML text.
This is generally a good idea so that neophyte webmasters
(and you know there are a lot of them in the world :-)
will see the warning before trying to manually modify
your automatically-generated text.

See $obj->fetch for details on the contents of the C<savable> parameter

=item $obj->raw_savable( $filename, $content )

I<In WebFetch 0.10 and later, this should be used only in
format handler functions.  See do_actions() for details.>

This WebFetch utility function stores any raw content and a filename
in the $obj->{savable} array,
in preparation for writing to that file.
(The actual save operation may also automatically include keeping
backup files and setting the group and mode of the file.)

See $obj->fetch for details on the contents of the C<savable> parameter

=item $obj->direct_fetch_savable( $filename, $source )

I<This should be used only in format handler functions.
See do_actions() for details.>

This adds a task for the save function to fetch a URL and save it
verbatim in a file.  This can be used to download links contained
in a news feed.

=item $obj->no_savables_ok

This can be used by an output function which handles its own intricate output
operation (such as WebFetch::Output::TWiki).  If the savables array is empty,
it would cause an error.  Using this function drops a note in it which
basically says that's OK.

=item $obj->save

This WebFetch utility function goes through all the entries in the
$obj->{savable} array and saves their contents,
providing several services such as keeping backup copies, 
and setting the group and mode of the file, if requested to do so.

If you call a WebFetch-derived module from the command-line run()
or fetch_main() functions, this will already be done for you.
Otherwise you will need to call it after populating the
C<savable> array with one entry per file to save.

Upon entry to this function, C<$obj> must contain the following attributes: 

=over 4

=item dir

directory to save files in

=item savable

names and contents for files to save

=back

See $obj->fetch for details on the contents of the C<savable> parameter

=item WebFetch::parse_date([{locale => "locale", time_zone => "time zone"}], $raw_time_str)

This parses a time string into a time or date structure which can be used by gen_timestamp() or anchor_timestr().

If the string can be parsed as a simple date in the format of YYYY-MM-DD or YYYYMMDD, it returns an array of
parameters which can be passed to DateTime->new(). Given in this context, gen_timestamp() or anchor_timestr()
recognize that means this is only a date with no time. (DateTime would fill in a time for midnight, which could be
shifted by hours if a timezone is added, making a date-only condition nearly impossible to detect.)

If the time can be parsed by L<DateTime::Format::ISO8601>, that result is returned.

If the time can be parsed by L<Date::Calc>'s Parse_Date(), a date-only array result is returned as above.

If the string can't be parsed, it returns undef;

=item WebFetch::gen_timestamp([{locale => "locale", time_zone => "time zone"}], $time_ref)

This takes a reference received from I<parse_date()> above and returns a string with the date in current locale format.

=item anchor_timestr([{time_zone => "time zone"}], $time_ref)

This takes a reference received from I<parse_date()> above and returns a timestamp string which can be used
as a hypertext link anchor, such as in HTML.
The string will be the numbers from the date, and possible time of day, delimited by dashes '-'.
If a time zone is provided, it will be used.

For example, August 5, 2022 at 19:30 becomes "2022-08-05-19-30-00".

=item AUTOLOAD functionality

When a WebFetch input object is passed to an output class, operations
on $self would not usually work.  WebFetch subclasses are considered to be
cooperating with each other.  So WebFetch provides AUTOLOAD functionality
to catch undefined function calls for its subclasses.  If the calling 
class provides a function by the name that was attempted, then it will
be redirected there.

=back

=head2 WRITING WebFetch-DERIVED MODULES

The easiest way to make a new WebFetch-derived module is to start
from the module closest to your fetch operation and modify it.
Make sure to change all of the following:

=over 4

=item fetch function

The fetch function is the meat of the operation.
Get the desired info from a local file or remote site and place the
contents that need to be saved in the C<savable> parameter.

=item module name

Be sure to catch and change them all.

=item file names

The code and documentation may refer to output files by name.

=item module parameters

Change the URL, number of links, etc as necessary.

=item command-line parameters

If you need to add command-line parameters, set both the
B<Options> and B<Usage> configuration parameters when your module calls I<module_register()>.
Don't forget to add documentation for your command-line options
and remove old documentation for any you removed.

When adding documentation, if the existing formatting isn't enough
for your changes, there's more information about
Perl's
POD ("plain old documentation")
embedded documentation format at
http://www.cpan.org/doc/manual/html/pod/perlpod.html

=item authors

Do not modify the names unless instructed to do so.
The maintainers have discretion whether one's contributions are significant enough to qualify as a co-author.

=back

Please consider contributing any useful changes back to the WebFetch
project at C<maint@webfetch.org>.

=head1 ACKNOWLEDGEMENTS

WebFetch was written by Ian Kluft
Send patches, bug reports, suggestions and questions to
C<maint@webfetch.org>.

Some changes in versions 0.12-0.13 (Aug-Sep 2009) were made for and
sponsored by Twiki Inc (formerly TWiki.Net).

=head1 LICENSE

WebFetch is Open Source software licensed under the GNU General Public License Version 3.
See L<https://www.gnu.org/licenses/gpl-3.0-standalone.html>.

=head1 SEE ALSO

Included in WebFetch module: 
L<WebFetch::Input::PerlStruct>,
L<WebFetch::Input::SiteNews>,
L<WebFetch::Output::Dump>,
L<WebFetch::Data::Config>,
L<WebFetch::Data::Record>,
L<WebFetch::Data::Store>

Modules separated to contain external module dependencies:
L<WebFetch::Input::Atom>,
L<WebFetch::Input::RSS>,
L<WebFetch::Output::TT>,
L<WebFetch::Output::TWiki>,

Source code repository:
L<https://github.com/ikluft/WebFetch>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/WebFetch/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/WebFetch/pulls>

=head1 AUTHOR

Ian Kluft <https://github.com/ikluft>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998-2022 by Ian Kluft.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

__END__
# remainder of POD docs follow

