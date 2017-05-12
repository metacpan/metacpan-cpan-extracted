# 
# DataService.pm
# 
# This is a framework for building data service applications.
# 
# Author: Michael McClennen <mmcclenn@cpan.org>


use strict;

require 5.012;

=head1 NAME

Web::DataService - a framework for building data service applications for the Web

=head1 VERSION

Version 0.254

=head1 SYNOPSIS

This module provides a framework for you to use in building data service
applications for the World Wide Web.  Such applications sit between a data
storage and retrieval system on one hand and the Web on the other, and fulfill
HTTP-based data requests.  Each valid request is handled by fetching or
storing the appropriate data using the backend data system and serializing the
output in a format such as JSON, CSV, or XML.

Using the methods provided by this module, you start by defining a set of data
service elements: output formats, output blocks, vocabularies, and parameter
rules, followed by a set of data service nodes representing the various
operations to be provided by your service.  Each of these objects is
configured by a set of attributes, optionally including documentation strings.
You continue by writing one or more modules whose methods will carry out the
core part of each data service operation: talking to the backend data system
to fetch and/or store the relevant data, based on the parameter values
provided in a data service request.

The Web::DataService code then takes care of most of the work necessary for
handling each request, including checking the parameter values, determining
the response format, calling your operation method at the appropriate time,
and serializing the result.  It also generates appropriate error messages when
necessary.  Finally, it auto-generates documentation pages for each operation
based on the elements you have defined, so that your data service is always
fully and correctly documented.

A Web::DataService application is built on top of a "foundation framework"
that provides the basic functionality of parsing HTTP requests and
constructing responses.  At the present time, the only one that can be used is
L<Dancer>.  However, we plan to add compatibility with other frameworks such
as Mojolicious and Catalyst soon.

=cut

package Web::DataService;

our $VERSION = '0.254';

use Carp qw( carp croak confess );
use Scalar::Util qw( reftype blessed weaken );
use POSIX qw( strftime );
use HTTP::Validate;

use Web::DataService::Node;
use Web::DataService::Set;
use Web::DataService::Format;
use Web::DataService::Vocabulary;
use Web::DataService::Ruleset;
use Web::DataService::Render;
use Web::DataService::Output;
use Web::DataService::Execute;
use Web::DataService::Document;

use Web::DataService::Request;
use Web::DataService::IRequest;
use Web::DataService::IDocument;
use Web::DataService::PodParser;

use Moo;
use namespace::clean;

with 'Web::DataService::Node', 'Web::DataService::Set',
     'Web::DataService::Format', 'Web::DataService::Vocabulary',
     'Web::DataService::Ruleset', 'Web::DataService::Render',
     'Web::DataService::Output', 'Web::DataService::Execute',
     'Web::DataService::Document';


our (@CARP_NOT) = qw(Web::DataService::Request Moo);

HTTP::Validate->VERSION(0.45);


our @HTTP_METHOD_LIST = ('GET', 'HEAD', 'POST', 'PUT', 'DELETE');

our @DEFAULT_METHODS = ('GET', 'HEAD');

our %SPECIAL_FEATURE = (format_suffix => 1, documentation => 1, 
			doc_paths => 1, send_files => 1, strict_params => 1, 
			stream_output => 1);

our @FEATURE_STANDARD = ('format_suffix', 'documentation', 'doc_paths', 
			 'send_files', 'strict_params', 'stream_output');

our @FEATURE_ALL = ('format_suffix', 'documentation', 'doc_paths', 
		    'send_files', 'strict_params', 'stream_output');

our %SPECIAL_PARAM = (selector => 'v', format => 'format', path => 'op', 
		      document => 'document', show => 'show',
		      limit => 'limit', offset => 'offset', 
		      count => 'count', vocab => 'vocab', 
		      datainfo => 'datainfo', linebreak => 'lb', 
		      header => 'header', save => 'save');

our @SPECIAL_STANDARD = ('show', 'limit', 'offset', 'header', 'datainfo', 
			 'count', 'vocab', 'linebreak', 'save');

our @SPECIAL_SINGLE = ('selector', 'path', 'format', 'show', 'header', 
		       'datainfo', 'vocab', 'linebreak', 'save');

our @SPECIAL_ALL = ('selector', 'path', 'document', 'format', 'show',
		    'limit', 'offset', 'header', 'datainfo', 'count', 
		    'vocab', 'linebreak', 'save');

my (@DI_KEYS) = qw(data_provider data_source data_license license_url
		   documentation_url data_url access_time title);


# Execution modes

our ($DEBUG, $ONE_REQUEST, $CHECK_LATER, $QUIET);


# Variables for keeping track of data service instances

my (%KEY_MAP, %PREFIX_MAP);
our (@WDS_INSTANCES);
our ($FOUNDATION);


# Attributes of a Web::DataService object

has name => ( is => 'ro', required => 1,
	      isa => \&_valid_name );

has parent => ( is => 'ro', init_arg => '_parent' );

has features => ( is => 'ro', required => 1 );

has special_params => ( is => 'ro', required => 1 );

has templating_plugin => ( is => 'lazy', builder => sub { $_[0]->_init_value('templating_plugin') } );

has backend_plugin => ( is => 'lazy', builder => sub { $_[0]->_init_value('backend_plugin') } );

has title => ( is => 'lazy', builder => sub { $_[0]->_init_value('title') } );

has version => ( is => 'lazy', builder => sub { $_[0]->_init_value('version') } );

has path_prefix => ( is => 'lazy', builder => sub { $_[0]->_init_value('path_prefix') } );

has path_re => ( is => 'lazy', builder => sub { $_[0]->_init_value('path_re') } );

has key => ( is => 'lazy', builder => sub { $_[0]->_init_value('key') } );

has hostname => ( is => 'lazy', builder => sub { $_[0]->_init_value('hostname') } );

has port => ( is => 'lazy', builder => sub { $_[0]->_init_value('port') } );

has generate_url_hook => ( is => 'rw', isa => \&_code_ref );

has ruleset_prefix => ( is => 'lazy', builder => sub { $_[0]->_init_value('ruleset_prefix') } );

has doc_suffix => ( is => 'lazy', builder => sub { $_[0]->_init_value('doc_suffix') } );

has doc_index => ( is => 'lazy', builder => sub { $_[0]->_init_value('doc_index') } );

has doc_template_dir => ( is => 'lazy', builder => sub { $_[0]->_init_value('doc_template_dir') } );

has output_template_dir => ( is => 'lazy', builder => sub { $_[0]->_init_value('output_template_dir') } );

has data_source => ( is => 'lazy', builder => sub { $_[0]->_init_value('data_source') } );

has data_provider => ( is => 'lazy', builder => sub { $_[0]->_init_value('data_provider') } );

has data_license => ( is => 'lazy', builder => sub { $_[0]->_init_value('data_license') } );

has license_url => ( is => 'lazy', builder => sub { $_[0]->_init_value('license_url') } );

has contact_name => ( is => 'lazy', builder => sub { $_[0]->_init_value('contact_name') } );

has contact_email => ( is => 'lazy', builder => sub { $_[0]->_init_value('contact_email') } );

has validator => ( is => 'ro', init_arg => undef );


# Validator methods for the data service attributes.

sub _valid_name {

    die "not a valid name"
	unless $_[0] =~ qr{ ^ [\w.:][\w.:-]* $ }xs;
}


sub _code_ref {

    die "must be a code ref"
	unless ref $_[0] && reftype $_[0] eq 'CODE';
}


# BUILD ( )
# 
# This method is called automatically after object initialization.

sub BUILD {

    my ($self) = @_;
    
    local($Carp::CarpLevel) = 1;	# We shouldn't have to do this, but
                                        # Moo and Carp don't play well together.
    
    # If no path prefix was defined, make it the empty string.
    
    $self->{path_prefix} //= '';
    
    # Process the feature list
    # ------------------------
    
    # These may be specified either as a listref or as a string with
    # comma-separated values.
    
    my $features_value = $self->features;
    my @features = ref $features_value eq 'ARRAY' ? @$features_value : split /\s*,\s*/, $features_value;
    
 ARG:
    foreach my $o ( @features )
    {
	next unless defined $o && $o ne '';
	
	my $feature_value = 1;
	my $key = $o;
	
	# If 'standard' was specified, enable the standard set of features.
	# (But don't override any that have already been set or cleared
	# explicitly.)
	
	if ( $o eq 'standard' )
	{
	    foreach my $p ( @FEATURE_STANDARD )
	    {
		$self->{feature}{$p} //= 1;
	    }
	    
	    next ARG;
	}
	
	# If we get an argument that looks like 'no_feature', then disable
	# the feature.
	
	elsif ( $o =~ qr{ ^ no_ (\w+) $ }xs )
	{
	    $key = $1;
	    $feature_value = 0;
	}
	
	# Now, complain if the user gives us something unrecognized.
	
	croak "unknown feature '$o'\n" unless $SPECIAL_FEATURE{$key};
	
	# Give this parameter the specified value (either on or off).
	# Parameters not mentioned default to off, unless 'standard' was
	# included.
	
	$self->{feature}{$key} = $feature_value;
    }
    
    # Process the list of special parameters
    # --------------------------------------
    
    # These may be specified either as a listref or as a string with
    # comma-separated values.
    
    my $special_value = $self->special_params;
    my @specials = ref $special_value eq 'ARRAY' ? @$special_value : split /\s*,\s*/, $special_value;
    
 ARG:
    foreach my $s ( @specials )
    {
	next unless defined $s && $s ne '';
	my $key = $s;
	my $name = $SPECIAL_PARAM{$s};
	my @aliases;
	
	# If 'standard' was specified, enable the "standard" set of parameters
	# with their default names (but don't override any that have already
	# been enabled).
	
	if ( $s eq 'standard' )
	{
	    foreach my $p ( @SPECIAL_STANDARD )
	    {
		$self->{special}{$p} //= $SPECIAL_PARAM{$p};
	    }
	    
	    next ARG;
	}
	
	# If we get an argument that looks like 'no_param', then disable
	# the parameter.
	
	elsif ( $s =~ qr{ ^ no_ (\w+) $ }xs )
	{
	    $key = $1;
	    $name = '';
	}
	
	# If we get an argument that looks like 'param=name', then enable the
	# feature 'param' but use 'name' as the accepted parameter name.
	
	elsif ( $s =~ qr{ ^ (\w+) = (\w+) (?: / ( \w [/\w]+ ) )? $ }xs )
	{
	    $key = $1;
	    $name = $2;
	    
	    if ( $3 )
	    {
		@aliases = grep { qr{ \w } } split(qr{/}, $3);
	    }
	}
	
	# Now, complain if the user gives us something unrecognized, or an
	# invalid parameter name.
	
	croak "unknown special parameter '$key'\n" unless $SPECIAL_PARAM{$key};
	croak "invalid parameter name '$name' - bad character\n" if $name =~ qr{[^\w/]};
	
	# Enable this parameter with the specified name.  If any aliases were
	# specified, then record them.
	
	$self->{special}{$key} = $name;
	$self->{special_alias}{$key} = \@aliases if @aliases;
    }
    
    # Make sure there are no feature or special parameter conflicts.
    
    croak "you may not specify the feature 'format_suffix' together with the special parameter 'format'"
	if $self->{feature}{format_suffix} && $self->{special}{format};
    
    croak "you may not specify the feature 'doc_paths' together with the special parameter 'document'"
	if $self->{feature}{doc_paths} && $self->{special}{document};
    
    $self->{feature}{doc_paths} = 0 unless $self->{feature}{documentation};
    
    # Check and configure the foundation plugin
    # -----------------------------------------
    
    $self->set_foundation;
    
    # From this point on, we will be able to read the configuration file
    # (assuming that a valid one is present).  So do so.
    
    $FOUNDATION->read_config($self);
    
    # Check and configure the templating plugin
    # -----------------------------------------
    
    # Note that unlike the foundation plugin, different data service instances
    # may use different templating plugins.
    
    # If a templating plugin was explicitly specified, either in the code
    # or in the configuration file, check that it is valid.
    
    if ( my $templating_plugin = $self->templating_plugin )
    {
	eval "require $templating_plugin" or croak $@;
	
	croak "$templating_plugin is not a valid templating plugin: cannot find method 'render_template'\n"
	    unless $templating_plugin->can('render_template');
    }
    
    # Otherwise, if 'Template.pm' has already been required then install the
    # corresponding plugin.
    
    elsif ( $INC{'Template.pm'} && ! defined $self->templating_plugin )
    {
	require Web::DataService::Plugin::TemplateToolkit or croak $@;
	$self->{templating_plugin} = 'Web::DataService::Plugin::TemplateToolkit';
    }
    
    # Otherwise, templating will not be available.
    
    else
    {
	if ( $self->{feature}{documentation} )
	{
	    unless ( $QUIET || $ENV{WDS_QUIET} )
	    {
		warn "WARNING: no templating engine was specified, so documentation pages\n";
		warn "    and templated output will not be available.\n";
	    }
	    $self->{feature}{documentation} = 0;
	    $self->{feature}{doc_paths} = 0;
	}
	
	$self->{templating_plugin} = 'Web::DataService::Plugin::Templating';
    }
    
    # If we have a templating plugin, instantiate it for documentation and
    # output.
    
    if ( defined $self->{templating_plugin} && 
	 $self->{templating_plugin} ne 'Web::DataService::Plugin::Templating' )
    {
	# Let the plugin do whatever initialization it needs to.
	
	$self->_init_plugin('templating_plugin');
	
	# If no document template directory was specified, use 'doc' if it
	# exists and is readable.
	
	my $doc_dir = $self->doc_template_dir;
	my $output_dir = $self->output_template_dir;
	
	unless ( defined $doc_dir )
	{
	    my $default = $ENV{PWD} . '/doc';
	    
	    if ( -r $default )
	    {
		$doc_dir = $default;
	    }
	    
	    elsif ( $self->{feature}{documentation} )
	    {
		unless ( $QUIET || $ENV{WDS_QUIET} )
		{
		    warn "WARNING: no document template directory was found, so documentation pages\n";
		    warn "    will not be available.  Try putting them in the directory 'doc',\n";
		    warn "    or specifying the attribute 'doc_template_dir'.\n";
		}
		$self->{feature}{documentation} = 0;
		$self->{feature}{doc_paths} = 0;
	    }
	}
	
	# If we were given a directory for documentation templates, initialize
	# an engine for evaluating them.
	
	if ( $doc_dir )
	{
	    $doc_dir = $ENV{PWD} . '/' . $doc_dir
		unless $doc_dir =~ qr{ ^ / }xs;
	    
	    croak "the documentation template directory '$doc_dir' is not readable: $!\n"
		unless -r $doc_dir;
	    
	    $self->{doc_template_dir} = $doc_dir;
	    
	    $self->{doc_engine} = 
		$self->{templating_plugin}->new_engine($self, { template_dir => $doc_dir });
	    
	    # If the attributes doc_header, doc_footer, etc. were not set,
	    # check for the existence of defaults.
	    
	    my $doc_suffix = $self->{template_suffix} || '';
	    
	    $self->{doc_defs} //= $self->check_doc("doc_defs${doc_suffix}");
	    $self->{doc_header} //= $self->check_doc("doc_header${doc_suffix}");
	    $self->{doc_footer} //= $self->check_doc("doc_footer${doc_suffix}");
	    $self->{doc_default_template} //= $self->check_doc("doc_not_found${doc_suffix}");
	    $self->{doc_default_op_template} //= $self->check_doc("doc_op_template${doc_suffix}");
	}
	
	# we were given a directory for output templates, initialize an
	# engine for evaluating them as well.
    
	if ( $output_dir )
	{
	    $output_dir = $ENV{PWD} . '/' . $output_dir
		unless $output_dir =~ qr{ ^ / }xs;
	    
	    croak "the output template directory '$output_dir' is not readable: $!\n"
		unless -r $output_dir;
	    
	    $self->{output_template_dir} = $output_dir;
	    
	    $self->{output_engine} =
		$self->{templating_plugin}->new_engine($self, { template_dir => $output_dir });
	}
    }
    
    # Check and configure the backend plugin
    # --------------------------------------
    
    # If a backend plugin was explicitly specified, check that it is valid.
    
    if ( my $backend_plugin = $self->backend_plugin )
    {
	eval "require $backend_plugin" or croak $@;
	
	croak "$backend_plugin is not a valid backend plugin: cannot find method 'get_connection'\n"
	    unless $backend_plugin->can('get_connection');
    }
    
    # Otherwise, if 'Dancer::Plugin::Database' is available then select the
    # corresponding plugin.
    
    elsif ( $INC{'Dancer.pm'} && $INC{'Dancer/Plugin/Database.pm'} && ! defined $self->backend_plugin )
    {
	$self->{backend_plugin} = 'Web::DataService::Plugin::Dancer';
    }
    
    # Otherwise, we get the stub backend plugin which will throw an exception
    # if called.  If you still wish to access a backend data system, then you
    # must either add code to the various operation methods to explicitly
    # connect to it use one of the available hooks.
    
    else
    {
	$self->{backend_plugin} = 'Web::DataService::Plugin::Backend';
    }
    
    # Let the backend plugin do whatever initialization it needs to.
    
    $self->_init_plugin('backend_plugin');
    
    # Register this instance so that we can select for it later
    # ---------------------------------------------------------
    
    $self->_register_instance;
    
    # Check and set some attributes
    # -----------------------------
    
    # The title must be non-empty, but we can't just label it 'required'
    # because it might be specified in the configuration file.
    
    my $title = $self->title;
    
    croak "you must specify a title, either as a parameter to the data service definition or in the configuration file\n"
	unless defined $title && $title ne '';
    
    # If no path_re was set, generate it from the path prefix.
    
    if ( ! $self->path_re )
    {
	my $prefix = $self->path_prefix;
	
	# If the prefix ends in '/', then generate a regexp that can handle
	# either the prefix as given or the prefix string without the final /
	# and without anything after it.
	
	if ( $prefix =~ qr{ (.*) [/] $ }xs )
	{
	    $self->{path_re} = qr{ ^ [/] $1 (?: [/] (.*) | $ ) }xs;
	}
	
	# Otherwise, generate a regexp that doesn't expect a / before the rest
	# of the path.
	
	else
	{
	    $self->{path_re} = qr{ ^ [/] $prefix (.*) }xs;
	}
    }
    
    # Create a default vocabulary, to be used in case no others are defined.
    
    $self->{vocab} = { 'null' => 
		       { name => 'null', use_field_names => 1, _default => 1, title => 'Null vocabulary',
			 doc_string => "This default vocabulary consists of the field names from the underlying data." } };
    
    $self->{vocab_list} = [ 'null' ];
    
    # We need to set defaults for 'doc_suffix' and 'index_name' so that we can
    # handle 'doc_paths' if it is enabled.  Application authors can turn
    # either of these off by setting the value to the empty string.
    
    $self->{doc_suffix} //= '_doc';
    $self->{doc_index} //= 'index';
    
    # Compute regexes from these suffixes.
    
    if ( $self->{doc_suffix} && $self->{doc_index} )
    {
	$self->{doc_path_regex} = qr{ ^ ( .* [^/] ) (?: $self->{doc_suffix} | / $self->{doc_index} | / ) $ }xs;
    }
    
    elsif ( $self->{doc_suffix} )
    {
	$self->{doc_path_regex} = qr{ ^ ( .* [^/] ) (?: $self->{doc_suffix} | / ) $ }xs;
    }
    
    elsif ( $self->{doc_index} )
    {
	$self->{doc_path_regex} = qr{ ^ ( .* [^/] ) (?: / $self->{doc_index} | / $ }xs;
    }
    
    # Create a new HTTP::Validate object so that we can do parameter
    # validations. 
    
    $self->{validator} = HTTP::Validate->new();
    
    $self->{validator}->validation_settings(allow_unrecognized => 1)
	unless $self->{feature}{strict_params};
    
    # Add a few other necessary fields.
    
    $self->{path_defs} = {};
    $self->{node_attrs} = {};
    $self->{attr_cache} = {};
    $self->{format} = {};
    $self->{format_list} = [];
    $self->{subservice} = {};
    $self->{subservice_list} = [];
}


# _init_value ( param )
# 
# Return the initial value for the specified parameter.  If it is already
# present as a direct attribute, return that.  Otherwise, look it up in the
# hash of values from the configuration file.  If those fail, check our parent
# (if we have a parent).

sub _init_value {
    
    my ($self, $param) = @_;
    
    die "empty configuration parameter" unless defined $param && $param ne '';
    
    # First check to see if we have this attribute specified directly.
    # Otherwise, check whether it is in our _config hash.  Otherwise,
    # if we have a parent then check its direct attributes and _config hash.
    # Otherwise, return undefined.
    
    my $ds_name = $self->name;
    
    return $self->{$param} if defined $self->{$param};
    return $self->{_config}{$ds_name}{$param} if defined $self->{_config}{$ds_name}{$param};
    return $self->{parent}->_init_value($param) if defined $self->{parent};
    return $self->{_config}{$param} if defined $self->{_config}{$param};
    
    return;
}


# _init_plugin ( plugin )
# 
# If the specified plugin has an 'initialize_service' method, call it with
# ourselves as the argument.

sub _init_plugin {

    my ($self, $plugin) = @_;
    
    return unless defined $self->{$plugin};
    
    no strict 'refs';
    
    if ( $self->{$plugin}->can('initialize_plugin') && ! ${"$self->{$plugin}::_INITIALIZED"} )
    {
	$self->{$plugin}->initialize_plugin($self);
	${"$self->{$plugin}::_INITIALIZED"} = 1;
    }
    
    if ( defined $self->{$plugin} && $self->{$plugin}->can('initialize_service') )
    {    
	$self->{$plugin}->initialize_service($self);
    }
}


# set_foundation ( plugin_module )
# 
# Initialize the foundation plugin.  If no name is given, try to determine the
# proper plugin based on the available modules.

sub set_foundation {

    my ($self, $plugin_module) = @_;
    
    # If an argument is specified and the foundation framework has already
    # been set, raise an exception.
    
    if ( defined $FOUNDATION && defined $plugin_module && $plugin_module ne $FOUNDATION )
    {
	croak "set_foundation: the foundation framework was already set to $FOUNDATION\n"
    }
    
    # If a plugin module is specified, require it.
    
    elsif ( $plugin_module )
    {
	eval "require $plugin_module" or croak $@;
	
	croak "class '$plugin_module' is not a valid foundation plugin: cannot find method 'read_config'\n"
	    unless $plugin_module->can('read_config');
	
	$FOUNDATION = $plugin_module;
    }
    
    # Otherwise, if 'Dancer.pm' has already been required then install the
    # corresponding plugin.
    
    elsif ( $INC{'Dancer.pm'} )
    {
	require Web::DataService::Plugin::Dancer or croak $@;
	$FOUNDATION = 'Web::DataService::Plugin::Dancer';
    }
    
    # Checks for other foundation frameworks will go here.
    
    # Otherwise, we cannot proceed.  Give the user some idea of what to do.
    
    else
    {
	croak "could not find a foundation framework: try installing Dancer and adding 'use Dancer;' to your application\n";
    }
    
    # Now initialize the plugin.
    
    no strict 'refs';
    
    if ( $FOUNDATION->can('initialize_plugin') && ! ${"${FOUNDATION}::_INITIALIZED"} )
    {
	$FOUNDATION->initialize_plugin();
	${"$FOUNDATION}::_INITIALIZED"} = 1;
    }
    
    if ( ref $self eq 'Web::DataService' && $FOUNDATION->can('initialize_service') )
    {    
	$FOUNDATION->initialize_service($self);
    }
}


# config_value ( param )
# 
# Return the value (if any) specified for this parameter in the configuration
# file.  If not found, check the configuration for our parent (if we have a
# parent).  This differs from _init_value above in that direct attributes are
# not checked.

sub config_value {

    my ($self, $param) = @_;
    
    die "empty configuration parameter" unless defined $param && $param ne '';
    
    # First check to see whether this parameter is in our _config hash.
    # Otherwise, if we have a parent then check its _config hash.  Otherwise,
    # return undefined.
    
    my $ds_name = $self->name;
    
    return $self->{_config}{$ds_name}{$param} if defined $self->{_config}{$ds_name}{$param};
    return $self->{parent}->config_value($param) if defined $self->{parent};
    return $self->{_config}{$param} if defined $self->{_config}{$param};
    
    return;
}


# has_feature ( name )
# 
# Return true if the given feature is set for this data service, undefined
# otherwise. 

sub has_feature {
    
    my ($self, $name) = @_;
    
    croak "has_feature: unknown feature '$name'\n" unless $SPECIAL_FEATURE{$name};
    return $self->{feature}{$name};
}


# special_param ( name )
# 
# If the given special parameter is enabled for this data service, return the
# parameter name.  Otherwise, return the undefined value.

sub special_param {
    
    my ($self, $name) = @_;
    
    croak "special_param: unknown special parameter '$name'\n" unless $SPECIAL_PARAM{$name};
    return $self->{special}{$name};
}


# valid_name ( name )
# 
# Return true if the given name is valid according to the Web::DataService
# specification, false otherwise.

sub valid_name {
    
    my ($self, $name) = @_;
    
    return 1 if defined $name && !ref $name && $name =~ qr{ ^ [\w][\w.:-]* $ }xs;
    return; # otherwise
}


# _register_instance ( )
# 
# Register this instance's key and path prefix so that the application code can
# later locate the appropriate service for handling each request.

sub _register_instance {

    my ($self) = @_;
    
    # Add this to the list of defined data service instances.
    
    push @WDS_INSTANCES, $self;
    
    # If the attribute 'key' was defined, add it to the key map.
    
    if ( my $key = $self->key )
    {
	croak "You cannot register two data services with the key '$key'\n"
	    if $KEY_MAP{$key};
	
	$KEY_MAP{$key} = $self;
    }
    
    # If the path prefix was defined, add it to the prefix map.
    
    if ( my $prefix = $self->path_prefix )
    {
	if ( defined $prefix && $prefix ne '' )
	{
	    $PREFIX_MAP{$prefix} = $self;
	}
    }
}


# select ( outer )
# 
# Return the data service instance that is appropriate for this request, or
# return an error if no instance could be matched.  This should be called as a
# class method.

sub select {
    
    my ($class, $outer) = @_;
    
    my $param;
    
    # Throw an error unless we have at least one data service instance to work with.
    
    croak "No data service instances have been defined" unless @WDS_INSTANCES;
    
    my $instance = $WDS_INSTANCES[0];
    
    # If the special parameter 'selector' is active, then we will use its
    # value to determine the appropriate data service instance.  We check the
    # first instance defined because all instances in this application should
    # either enable or disable this parameter alike.
    
    if ( $param = $instance->{special}{selector} )
    {
	my $key = $FOUNDATION->get_param($outer, $param);
	
	# If the parameter value matches a data service instance, return that.
	
	if ( defined $key && $KEY_MAP{$key} )
	{
	    return $KEY_MAP{$key};
	}
	
	# Otherwise, if the URL path is empty or just '/', return the first
	# instance defined.
	
	my $path = $FOUNDATION->get_request_path($outer);
	
	if ( !defined $path || $path eq '' || $path eq '/' )
	{
	    return $instance;
	}
	
	# Otherwise, return an error message specifying the proper values.
	
	my @keys = sort keys %KEY_MAP;
	my $good_values = join(', ', map { "v=$_" } @keys);
	
	if ( defined $key && $key ne '' )
	{
	    die "400 Invalid version '$key' - you must specify one of the following parameters: $good_values\n";
	}
	
	else
	{
	    die "400 You must specify a data service version using one of the following parameters: $good_values\n";
	}
    }
    
    # Otherwise, check the request path against each data service instance to
    # see if we can figure out which one to use by means of the regexes
    # stored in the path_re attribute.
    
    else
    {
	my $path = $FOUNDATION->get_request_path($outer);
	
	foreach my $ds ( @WDS_INSTANCES )
	{
	    if ( defined $ds->{path_re} && $path =~ $ds->{path_re} )
	    {
		return $ds;
	    }
	}
	
	# If none of the instances match this path, then throw a 404 (Not
	# Found) exception.
	
	my @prefixes = sort keys %PREFIX_MAP;
	my $good_values = join(', ', map { "/$_" } @prefixes);
	
	if ( @prefixes > 1 )
	{
	    die "404 The path '$path' is not valid.  Try a path starting with one of the following: $good_values\n";
	}
	
	elsif ( @prefixes == 1 )
	{
	    die "404 The path '$path' is not valid.  Try a path starting with $good_values\n";
	}
	
	else
	{
	    die "404 The path '$path' is not valid on this server.";
	}
    }
}



sub get_connection {
    
    my ($self) = @_;
    
    croak "get_connection: no backend plugin was loaded\n"
	unless defined $self->{backend_plugin};
    return $self->{backend_plugin}->get_connection($self);
}



sub set_mode {
    
    my ($self, @modes) = @_;
    
    foreach my $mode (@modes)
    {
	if ( $mode eq 'debug' )
	{
	    $DEBUG = 1 unless $QUIET || $ENV{WDS_QUIET};
	}
	
	elsif ( $mode eq 'one_request' )
	{
	    $ONE_REQUEST = 1;
	}
	
	elsif ( $mode eq 'late_path_check' )
	{
	    $CHECK_LATER = 1;
	}
	
	elsif ( $mode eq 'quiet' )
	{
	    $QUIET = 1;
	    $DEBUG = 0;
	}
    }
}


sub is_mode {

    my ($self, $mode) = @_;
    
    return 1 if $mode eq 'debug' && $DEBUG;
    return 1 if $mode eq 'one_request' && $ONE_REQUEST;
    return 1 if $mode eq 'late_path_check' && $CHECK_LATER;
    return 1 if $mode eq 'quiet' && $QUIET;
    return;
}


# generate_site_url ( attrs )
# 
# Generate a URL according to the specified attributes:
# 
# node		Generates a documentation URL for the specified data service node
# 
# op		Generates an operation URL for the specified data service node
# 
# path		Generates a URL for this exact path (with the proper prefix added)
# 
# format	Specifies the format to be included in the URL
# 
# params	Species the parameters, if any, to be included in the URL
# 
# fragment	Specifies a fragment identifier to add to the generated URL
# 
# type		Specifies the type of URL to generate: 'abs' for an
#		absolute URL, 'rel' for a relative URL, 'site' for
#		a site-relative URL (starts with '/').  Defaults to 'site'.

sub generate_site_url {

    my ($self, $attrs) = @_;
    
    # If the attributes were given as a string rather than a hash, unpack them.
    
    unless ( ref $attrs )
    {
	return '/' . $self->{path_prefix} unless defined $attrs && $attrs ne '' && $attrs ne '/';
	
	if ( $attrs =~ qr{ ^ (node|op|path) (abs|rel|site)? [:] ( [^#?]* ) (?: [?] ( [^#]* ) )? (?: [#] (.*) )? }xs )
	{
	    my $arg = $1;
	    my $type = $2 || 'site';
	    my $path = $3 || '/';
	    my $params = $4;
	    my $frag = $5;
	    my $format;
	    
	    if ( $arg ne 'path' && $path =~ qr{ (.*) [.] ([^.]+) $ }x )
	    {
		$path = $1; $format = $2;
	    }
	    
	    $attrs = { $arg => $path, type => $type, format => $format, 
		       params => $params, fragment => $frag };
	}
	
	else
	{
	    return $attrs;
	}
    }
    
    elsif ( ref $attrs ne 'HASH' )
    {
	croak "generate_site_url: the argument must be a hashref or a string\n";
    }
    
    # If a custom routine was specified for this purpose, call it.
    
    if ( $self->{generate_url_hook} )
    {
	return &{$self->{generate_url_hook}}($self, $attrs);
    }
    
    # Otherwise, construct the URL according to the feature set of this data
    # service.
    
    my $path = $attrs->{node} || $attrs->{op} || $attrs->{path} || '';
    my $format = $attrs->{format};
    my $type = $attrs->{type} || 'site';
    
    unless ( defined $path )
    {
	carp "generate_site_url: you must specify a URL path\n";
    }
    
    elsif ( ! $attrs->{path} && $path =~ qr{ (.*) [.] ([^.]+) $ }x )
    {
	$path = $1;
	$format = $2;
    }
    
    $format = 'html' if $attrs->{node} && ! (defined $format && $format eq 'pod');
    
    my @params = ref $attrs->{params} eq 'ARRAY' ? @{$attrs->{params}}
               : defined $attrs->{params}        ? split(/&/, $attrs->{params})
		                                 : ();
    
    my ($has_format, $has_selector);
    
    foreach my $p ( @params )
    {
	$has_format = 1 if $self->{special}{format} && $p =~ qr{ ^ $self->{special}{format} = \S }x;
	$has_selector = 1 if $self->{special}{selector} && $p =~ qr{ ^ $self->{special}{selector} = \S }xo;
    }
    
    # if ( defined $attrs->{node} && ref $attrs->{node} eq 'ARRAY' )
    # {
    # 	push @params, @{$attrs->{node}};
    # 	croak "generate_url: odd number of parameters is not allowed\n"
    # 	    if scalar(@_) % 2;
    # }
    
    # First, check if the 'fixed_paths' feature is on.  If so, then the given
    # documentation or operation path is converted to a parameter and the appropriate
    # fixed path is substituted.
    
    if ( $self->{feature}{fixed_paths} )
    {
	if ( $attrs->{node} )
	{
	    push @params, $self->{special}{document} . "=$path" unless $path eq '/';
	    $path = $self->{doc_url_path};
	}
	
	elsif ( $attrs->{op} )
	{
	    push @params, $self->{special}{op} . "=$path";
	    $path = $self->{operation_url_path};
	}
    }
    
    # Otherwise, we can assume that the URL paths will reflect the given path.
    # So next, check if the 'format_suffix' feature is on.
    
    if ( $self->{feature}{format_suffix} )
    {
	# If this is a documentation URL, then add the documentation suffix if
	# the "doc_paths" feature is on.  Also add the format.  But not if the
	# path is '/'.
	
	if ( $attrs->{node} && $path ne '/' )
	{
	    $path .= $self->{doc_suffix} if $self->{feature}{doc_paths};
	    $path .= ".$format";
	}
	
	# If this is an operation URL, we just add the format if one was
	# specified.
	
	elsif ( $attrs->{op} )
	{
	    $path .= ".$format" if $format;
	}
	
	# A path URL is not modified.
    }
    
    # Otherwise, if the feature 'doc_paths' is on then we still need to modify
    # the paths.
    
    elsif ( $self->{feature}{doc_paths} )
    {
	if ( $attrs->{node} && $path ne '/' )
	{
	    $path .= $self->{doc_suffix};
	}
    }
    
    # If the special parameter 'format' is enabled, then we need to add it
    # with the proper format name.
    
    if ( $self->{special}{format} && ! $has_format && ! $attrs->{path} )
    {
	# If this is a documentation URL, then add a format parameter unless
	# the format is either 'html' or empty.
	
	if ( $attrs->{node} && $format && $format ne 'html' )
	{
	    push @params, $self->{special}{format} . "=$format";
	}
	
	# If this is an operation URL, we add the format unless it is empty.
	
	elsif ( $attrs->{op} )
	{
	    push @params, $self->{special}{format} . "=$format" if $format;
	}
	
	# A path URL is not modified.
    }
    
    # If the special parameter 'selector' is enabled, then we need to add it
    # with the proper data service key.
    
    if ( $self->{special}{selector} && ! $has_selector )
    {
	my $key = $self->key;
	push @params, $self->{special}{selector} . "=$key";
    }
    
    # If the path is '/', then turn it into the empty string.
    
    $path = '' if $path eq '/';
    
    # Now assemble the URL.  If the type is not 'relative' then we start with
    # the path prefix.  Otherwise, we start with the given path.
    
    my $url;
    
    if ( $type eq 'rel' )
    {
	$url = $path;
    }
    
    elsif ( $type eq 'abs' )
    {
	$url = $self->{base_url} . $self->{path_prefix} . $path;
    }
    
    else
    {
	$url = '/' . $self->{path_prefix} . $path;
    }
    
    # Add the parameters and fragment, if any.
    
    if ( @params )
    {
	$url .= '?';
	my $sep = '';
	
	while ( @params )
	{
	    $url .= $sep . shift(@params);
	    $sep = '&';
	}
    }
    
    if ( $attrs->{fragment} )
    {
	$url .= "#$attrs->{fragment}";
    }
    
    # Return the resulting URL.
    
    return $url;
}


# node_link ( path, title )
# 
# Generate a link in POD format to the documentation for the given path.  If
# $title is defined, use that as the link title.  Otherwise, if the path has a
# 'doc_title' attribute, use that.
# 
# If something goes wrong, generate a warning and return the empty string.

sub node_link {
    
    my ($self, $path, $title) = @_;
    
    return 'I<L<unknown link|node:/>>' unless defined $path;
    
    # Generate a "node:" link for this path, which will be translated into an
    # actual URL later.
    
    if ( defined $title && $title ne '' )
    {
	return "L<$title|node:$path>";
    }
    
    elsif ( $title = $self->node_attr($path, 'title') )
    {
	return "L<$title|node:$path>";
    }
    
    else
    {
	return "I<L<$path|node:$path>>";
    }
}


# base_url ( )
# 
# Return the base URL for this data service, in the form "http://hostname/".
# If the attribute 'port' was specified for this data service, include that
# too.

sub base_url {
    
    my ($self) = @_;
    
    carp "CALL: base_url\n";
    
    #return $FOUNDATION->get_base_url;
    
    my $hostname = $self->{hostname} // '';
    my $port = $self->{port} ? ':' . $self->{port} : '';
    
    return "http://${hostname}${port}/";
}


# root_url ( )
# 
# Return the root URL for this data service, in the form
# "http://hostname/prefix/".

sub root_url {

    my ($self) = @_;
    
    carp "CALL: root_url\n";
    
    #return $FOUNDATION->get_base_url . $self->{path_prefix};
    
    my $hostname = $self->{hostname} // '';
    my $port = $self->{port} ? ':' . $self->{port} : '';
    
    return "http://${hostname}${port}/$self->{path_prefix}";
}


# execution_class ( primary_role )
# 
# This method is called to create a class in which we can execute requests.
# We need to create one of these for each primary role used in the
# application.
# 
# This class needs to have two roles composed into it: the first is
# Web::DataService::Request, which provides methods for retrieving the request
# parameters, output fields, etc.; the second is the "primary role", written
# by the application author, which provides methods to implement one or more
# data service operations.  We cannot simply use Web::DataService::Request as
# the base class, as different requests may require composing in different
# primary roles.  We cannot use the primary role as the base class, because
# then any method conflicts would be resolved in favor of the primary role.
# This would compromise the functionality of Web::DataService::Request, which
# needs to be able to call its own methods reliably.
# 
# The best way to handle this seems to be to create a new, empty class and
# then compose in both the primary role and Web::DataService::Request using a
# single 'with' request.  This way, an exception will be thrown if the two
# sets of methods conflict.  This new class will be named using the prefix
# 'REQ::', so that if the primary role is 'Example' then the new class will be
# 'REQ::Example'.
# 
# Any other roles needed by the primary role must also be composed in.  We
# also must check for an 'initialize' method in each of these roles, and call
# it if present.  As a result, we cannot simply rely on transitive composition
# by having the application author use 'with' to include one role inside
# another.  Instead, the role author must indicate additional roles as
# follows: 
# 
#     package MyRole;
#     use Moo::Role;
#     
#     our(@REQUIRES_ROLE) = qw(SubRole1 SubRole2);
# 
# Both the primary role and all required roles will be properly initialized,
# which includes calling their 'initialize' method if one exists.  This will
# be done only once per role, no matter how many contexts it is used in.  Each
# of the subsidiary roles will be composed one at a time into the request
# execution class.

sub execution_class {

    my ($self, $primary_role) = @_;
    
    no strict 'refs';
    
    croak "you must specify a non-empty primary role"
	unless defined $primary_role && $primary_role ne '';
    
    croak "you must first load the module '$primary_role' before using it as a primary role"
	unless $primary_role eq 'DOC' || %{ "${primary_role}::" };
    
    my $request_class = "REQ::$primary_role";
    
    # $DB::single = 1;
    
    # First check to see if this class has already been created.  Return
    # immediately if so.
    
    return $request_class if exists ${ "${request_class}::" }{_CREATED};
    
    # Otherwise create the new class and compose in Web::DataService::Request
    # and the primary role.  Then compose in any secondary roles, one at a time.
    
    my $secondary_roles = "";
    
    foreach my $role ( @{ "${primary_role}::REQUIRES_ROLE" } )
    {
	croak "create_request_class: you must first load the module '$role' \
before using it as a secondary role for '$primary_role'"
	    unless %{ "${role}::" };
	
	$secondary_roles .= "with '$role';\n";
    }
    
    my $string =  " package $request_class;
			use Try::Tiny;
			use Scalar::Util qw(reftype);
			use Carp qw(carp croak);
			use Moo;
			use namespace::clean;
			
			use base 'Web::DataService::Request';
			with 'Web::DataService::IRequest', '$primary_role';
			$secondary_roles
			
			our(\$_CREATED) = 1";
    
    my $result = eval $string;
    
    # Now initialize the primary role, unless of course it has already been
    # initialized.  This will also cause any uninitialized secondary roles to
    # be initialized.
    
    $self->initialize_role($primary_role) unless $primary_role eq 'DOC';
    
    return $request_class;
}


# documentation_class ( primary_role )
# 
# This method is called to create a class into which we can bless an object
# that represents a documentation request.  This will potentially be called
# once for each different primary role in the data service application, plus
# once to create a generic documentation class not based on any role.
# 
# The classes created here must include all of the methods necessary for
# generating documentation, including all of the methods in the indicated
# role(s).

sub documentation_class {

    my ($self, $primary_role) = @_;
    
    no strict 'refs';
    
    # First check to see if the necessary class has already been created.
    # Return immediately if so, because we have nothing left to do.  If no
    # primary role was specified, the name of the class will be "DOC".
    
    my $request_class = $primary_role ? "DOC::$primary_role" : "DOC";
    
    return $request_class if exists ${ "${request_class}::" }{_CREATED};
    
    # Make sure that a package corresponding to the specified primary role
    # actually exists.
    
    croak "you must first load the module '$primary_role' before using it as a primary role"
	if $primary_role && ! %{ "${primary_role}::" };
    
    # If the primary role has not yet been initialized, do so.  This will also
    # cause any uninitialized secondary roles to be initialized.
    
    $self->initialize_role($primary_role) if $primary_role;
    
    # Now create the new class and compose into it both
    # Web::DataService::Request and the primary role.  By doing these together
    # we will generate an error if there are any method conflicts between
    # these packages.  Also compose in any secondary roles, one at a time.
    # Any method conflicts here will be silently resolved in favor of the
    # primary role and/or Web::DataService::Request.
    
    my $primary_with = "";
    my $secondary_roles = "";
    
    if ( $primary_role )
    {
	$primary_with = ", '$primary_role'";
	
	foreach my $role ( @{ "${primary_role}::REQUIRES_ROLE" }  )
	{
	    croak "create_request_class: you must first load the module '$role' \
before using it as a secondary role for '$primary_role'"
		unless %{ "${role}::" };
	    
	    $secondary_roles .= "with '$role';\n";
	}
    }
    
    my $string =  " package $request_class;
			use Carp qw(carp croak);
			use Moo;
			use namespace::clean;
			
			use base 'Web::DataService::Request';
			with 'Web::DataService::IDocument' $primary_with;
			$secondary_roles
			
			our(\$_CREATED) = 1";
    
    my $result = eval $string;
    
    return $request_class;
}


# initialize_role ( role )
# 
# This method calls the 'initialize' method of the indicated role, but first
# it recursively processes every role required by that role.  The intialize
# method is only called once per role per execution of this program, no matter
# how many contexts it is used in.

sub initialize_role {
    
    my ($self, $role) = @_;
    
    no strict 'refs'; no warnings 'once';
    
    # If we have already initialized this role, there is nothing else we need
    # to do.
    
    return if $self->{role_init}{$role};
    $self->{role_init}{$role} = 1;
    
    # If this role requires one or more secondary roles, then initialize them
    # first (unless they have already been initialized).
    
    foreach my $required ( @{ "${role}::REQUIRES_ROLE" } )
    {
	$self->initialize_role($required);
    }
    
    # Now, if the role has an initialization routine, call it.  We need to do
    # this after the previous step because this role's initialization routine
    # may depend upon side effects of the required roles' initialization routines.
    
    if ( $role->can('initialize') )
    {
	print STDERR "Initializing $role for data service $self->{name}\n" if $DEBUG || $self->{DEBUG};
	$role->initialize($self);
    }
    
    my $a = 1; # we can stop here when debugging
}


# set_scratch ( key, value )
# 
# Store the specified value in the "scratchpad" for this data service, under
# the specified key.  This can be used to store data, configuration
# information, etc. for later use by data operation methods.

sub set_scratch {
    
    my ($self, $key, $value) = @_;
    
    return unless defined $key && $key ne '';
    
    $self->{scratch}{$key} = $value;
}


# get_scratch ( key, value )
# 
# Retrieve the value corresponding to the specified key from the "scratchpad" for
# this data service.

sub get_scratch {
    
    my ($self, $key, $value) = @_;
    
    return unless defined $key && $key ne '';
    
    return $self->{scratch}{$key};
}


# data_info ( )
# 
# Return the following pieces of information:
# - The name of the data source
# - The license under which the data is made available

sub data_info {
    
    my ($self) = @_;
    
    my $access_time = strftime("%a %F %T GMT", gmtime);
    
    my $title = $self->{title};
    my $data_provider = $self->data_provider;
    my $data_source = $self->data_source;
    my $data_license = $self->data_license;
    my $license_url = $self->license_url;
    
    my $result = { 
	title => $title,
	data_provider => $data_provider,
	data_source => $data_source,
	data_license => $data_license,
	license_url => $license_url,
	access_time => $access_time };
    
    return $result;
}


# data_info_keys
# 
# Return a list of keys into the data_info hash, in the proper order to be
# listed in a response message.

sub data_info_keys {
    
    return @DI_KEYS;
}


# contact_info ( )
# 
# Return the data service attributes "contact_name" and "contact_email",
# as a hash whose keys are "name" and "email".

sub contact_info {
    
    my ($self) = @_;
    
    my $result = { 
	name => $self->contact_name,
	email => $self->contact_email };
    
    return $result;
}


# get_base_path ( )
# 
# Return the base path for the current data service, derived from the path
# prefix.  For example, if the path prefix is 'data', the base path is
# '/data/'. 

# sub get_base_path {
    
#     my ($self) = @_;
    
#     my $base = '/';
#     $base .= $self->{path_prefix} . '/'
# 	if defined $self->{path_prefix} && $self->{path_prefix} ne '';
    
#     return $base;
# }


sub debug {

    my ($self) = @_;
    
    return $DEBUG || $self->{DEBUG};
}

=head1 MORE DOCUMENTATION

This documentation describes the methods of class Web::DataService.  For
additional documentation, see the following pages:

=over

=item L<Web::DataService::Request>

A description of the request-handling process, along with detailed
documentation of the methods that can be called with request objects.

=item L<Web::DataService::Introduction>

A detailed description of this module and its reasons for existence.

=item L<Web::DataService::Tutorial>

A step-by-step guide to the example application included with this
distribution.

=item L<Web::DataService::Configuration>

A detailed description of how to configure a data service using this
framework.  This page includes sub-pages for each different type of data
service element.

=item  L<Web::DataService::Documentation>

An overview of the elements available for use in documentation templates.

=back

=head1 METHODS

=head2 CONSTRUCTOR

=head3 new ( { attributes ... } )

This class method defines a new data service instance.  Calling it is generally the first step in configuring
a data service application.  The available attributes are described in
L<Web::DataService::Configuration/"Data service instantiation:>.  The attribute C<name> is required; the
others are optional, and some of them may be specified in the application configuration file instead.

Once you have a data service instance, the next step is to configure it by adding various data service
elements.  This is done by calling the methods listed below.

=head2 CONFIGURATION

The following methods are used to configure a data service application.  For a list of the available
attributes for each method, and an overview of the calling convention, see
L<Web::DataService::Configuration>.  For detailed instructions on how to set up a data service application,
see L<Web::DataService::Tutorial>.

=head3 set_foundation ( module_name )

You can call this as a class method if you wish to use a custom foundation
framework.  The argument must be the module name, which will be require'd.
This call must occur before any data services are defined.

=head3 define_vocab ( { attributes ... }, documentation ... )

Defines one or more
L<vocabularies|Web::DataService::Configuration::Vocabulary>, using the
specified attributes and documentation strings.  Each vocabulary represents a
different set of terms by which to label and express the returned data.

=head3 define_format ( { attributes ... }, documentation ... )

Defines one or more L<output formats|Web::DataService::Configuration::Format>,
using the specified attributes and documentation strings.  Each of these
formats represents a configuration of one of the available serialization
modules.

=head3 define_node ( { attributes ... }, documentation ... )

Defines one or more L<data service
nodes|Web::DataService::Configuration::Node>, using the specified attributes
and documentation strings.  Each of these nodes represents either an operation
provided by the data service or a page of documentation.

=head3 list_node ( { attributes ... }, documentation ... )

Adds one or more entries to a L<node list|Web::DataService::Configuration::Node/"Node Lists">,
which can be used to document lists of related nodes.  You can use this to
document node relationships that are not strictly hierarchical.

=head3 define_block ( block_name, { attributes ... }, documentation ... )

Defines an L<output block|Web::DataService::Configuration::Output> with the
given name, containing the specified output fields and documentation.

=head3 define_set ( set_name, { attributes ... }, documentation ... )

Defines a named L<set of values|Web::DataService::Configuration::Set>,
possibly with a mapping to some other list of values.  These can be used to
specify the acceptable values for request parameters, to translate data values
into different vocabularies, or to specify optional output blocks.

=head3 define_output_map ( set_name, { attributes ... }, documentation ... )

This method is an alias for C<define_set>.

=head3 define_ruleset ( ruleset_name, { attributes ... }, documentation ... )

Defines a L<parameter ruleset|Web::DataService::Configuration::Ruleset> with
the given name, containing the specified rules and documentation.  These are
used to validate parameter values.

=head2 EXECUTION

The following methods are available for you to use in the part of your code
that handles incoming requests.  This will typically be inside one or more
"route handlers" or "controllers" defined using the foundation framework.

=head3 handle_request ( outer, [ attrs ] )

A call to this method directs the Web::DataService framework to handle the
current L<request|Web::DataService::Request>.  Depending on how your
application is configured, one of the data service operation methods that you
have written may be called as part of this process.

You may call this either as a class method or an instance method.  In the
former case, if you have defined more than one data service instance, the
method will choose the appropriate instance based on either the path prefix or
selector parameter depending upon which features and special parameters you
have enabled.  If you know exactly which instance is the appropriate one, you
may instead call this method on it directly.

The first argument must be the "outer" request object, i.e. the one generated by
the foundation framework.  This allows the Web::DataService code to obtain
details about the request and to compose the response using the functionality
provided by that framework.  This method will create an "inner" object in a
subclass of L<Web::DataService::Request>, with attributes derived from the
current request and from the data service node that matches it.  If no data
service node matches the current request, a 404 error response will be
returned to the client.

You may provide a second optional argument, which must be a hashref of request
attributes (see
L<Web::DataService::Request|Web::DataService::Request/"Attribute accessors">).
These will be used to initialize the request object, overriding any
automatically determined attributes.

This method returns the result of the request (generally the body of the
response message), unless an error occurs.  In the latter case an exception
will be thrown, so your main application should include an appropriate handler
to generate a proper error response.  See the file
L<F<lib/Example.pm>|Web::DataService::Tutorial/"lib/Example.pm"> in the
tutorial example for more about this.

=head3 new_request ( outer, [ attrs ] )

If you wish more control over the request-handling process than is provided by
L<handle_request|/"handle_request ( outer, [ attrs ] )">, you may instead call
this method.  It returns an object blessed into a subclass of
Web::DataService::Request, as described above for C<handle_request>, but does
not execute it.

You can then examine and possibly alter any of the request attributes, before
calling the request's C<execute> method.  This method may, like
C<handle_request>, be called either as a class method or an instance method.

=head3 execute_request ( request )

This method may be called to execute a request.  The argument must belong to a
subclass of L<Web::DataService::Request>, created by a previous call to
L<new_request|/"new_request ( outer, [ attrs ] )">.  This method may, like
C<handle_request>, be called either as a class method or an instance method.

=head3 node_attr ( path, attribute )

Returns the specified attribute of the node with the specified path, if the
specified path and attribute are both defined.  Returns C<undef> otherwise.
You can use this to test whether a particular node is in fact defined, or to
retrieve any node attribute.

You will rarely need to call this method, since for any request the relevant
attributes of the matching node will be automatically used to instantiate the
request object.  In almost all cases, you will instead use the attribute
accessor methods of the request object.

=head3 config_value ( name )

Returns the value (if any) specified for this name in the application
configuration file.  If the name is found as a sub-entry under the data
service name, that value is used.  Otherwise, if the name is found as a
top-level entry then it is used.

=head3 has_feature ( feature_name )

Returns a true value if the specified
L<feature|Web::DataService::Configuration/"features [req] [inst]">
is enabled for this data service.  Returns false otherwise.

=head3 special_param ( parameter_name )

If the specified 
L<special parameter|Web::DataService::Configuration/"special_params [req]
[inst]"> is enabled for this data service, returns the parameter name which
clients use.  This may be different from the internal name by which this
parameter is known, but will always be a true value.  Returns false if this
parameter is not enabled.

=head3 generate_site_url

This method is called by the
L<generate_url|Web::DataService::Request/"generate_url ( attrs )"> method of
L<Web::DataService::Request>.  You should be aware that if you call it outside
of the context of a request it will not be able to generate absolute URLs.  In
most applications, you will never need to call this directly and can instead
use the latter method.

=head3 get_connection

If a backend plugin is available, this method obtains a connection handle from
it.  You can use this method when initializing your operation roles, if your
initialization process requires communication with the backend.  You are not
required to use this mechanism, and may connect to the backend in any way you
choose.

=head3 accessor methods

Each of the data service 
L<attributes|Web::DataService::Configuration/"Data service attributes">
is provided with an accessor method.  This method returns the attribute value,
but cannot be used to set it.  All data service attributes must be set when
the data service object is instantiated with C<new>, either specified
directly in that call or looked up in the application configuration file
provided by the foundation framework.

=head2 DOCUMENTATION

The following methods are used in generating documentation.  If you use
documentation templates, you will probably not need to call them directly.

=head3 document_vocabs ( path, { options ... } )

Returns a documentation string in Pod for the
L<vocabularies|Web::DataService::Configuration::Vocabulary> that are allowed
for the node corresponding to the specified path.  The optional C<options> hash
may include the following:

=over

=item all

If this option has a true value then all vocabularies are documented, not just
those allowed for the given path.

=item extended

If this option has a true value then the documentation string is included for
each vocabulary.

=back

=head3 document_formats ( path, { options ... } )

Return a string containing documentation in Pod for the
L<formats|Web::DataService::Configuration::Format> that are allowed for the
node corresponding to the specified path.  The optional C<options> hash may
include the following:

=over

=item all

If this option has a true value then all formats are documented, not just
those allowed for the given path.

=item extended

If this option has a true value then the documentation string is included for
each format.

=back

=head3 document_nodelist ( list, { options ... } )

Returns a string containing documentation in Pod for the specified
L<node list|Web::DataService::Configuration::Node/"Node Lists">.
Each node has a default node list whose name is its node path, and you can
define other lists arbitrarily by using the method L<list_node|/list_node>.
The optional C<options> hash may include the following:

=over

=item usage

If this documentation string has a non-empty value, then usage examples will
be included if they are specified in the node list entries.  The value of this
attribute will be included in the result between each node's documentation
string and its usage list, so it should be a string such as "For example:".

=back

=head2 MISCELLANEOUS

=head3 valid_name ( name )

Returns true if the given string is valid as a Web::DataService name.  This
means that it begins with a word character and includes only word characters
plus the punctuation characters ':', '-' and '.'.

=head3 set_mode ( mode ... )

You can call this either as a class method or as an instance method; it has
a global effect either way.  This method turns on one or more of the
following modes:

=over 4

=item debug

Produces additional debugging output to STDERR.

=item one_request

Configures the data service to satisfy one request and then exit.  This is
generally used for testing purposes.

=back

You will typically call this at application startup time.

=head1 AUTHOR

mmcclenn "at" cpan.org

=head1 BUGS

Please report any bugs or feature requests to C<bug-web-dataservice at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Web-DataService>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2014 Michael McClennen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


package Web::DataService::Plugin::Templating;

use Carp qw(croak);

sub render_template { croak "render_template: no templating plugin was specified\n"; }


package Web::DataService::Plugin::Backend;

use Carp qw(croak);

sub get_connection { croak "get_connection: no backend plugin was specified"; }


1;
