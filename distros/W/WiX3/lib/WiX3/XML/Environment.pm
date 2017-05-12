package WiX3::XML::Environment;

####################################################################
# WiX3::XML::Environment - Object that represents an <Environment> tag.
#
# Copyright 2009, 2010 Curtis Jewell
#
# License is the same as perl. See WiX3.pm for details.
#
use 5.008003;

# Must be done before Moose, or it won't get picked up.
use metaclass (
	metaclass   => 'Moose::Meta::Class',
	error_class => 'WiX3::Util::Error',
);
use Moose 2;
use Params::Util qw( _IDENTIFIER _STRING );
use WiX3::Types qw( YesNoType EnumEnvironmentAction);
use MooseX::Types::Moose qw( Str Maybe );
use WiX3::Util::StrictConstructor;

our $VERSION = '0.011';

# http://wix.sourceforge.net/manual-wix3/wix_xsd_environment.htm

with 'WiX3::XML::Role::Tag';

# No child tags allowed.

#####################################################################
# Accessors:
#   see new.

has id => (
	is       => 'ro',
	isa      => Str,
	reader   => 'get_id',
	required => 1,
);

has name => (
	is       => 'ro',
	isa      => Str,
	reader   => '_get_name',
	required => 1,
);

has value => (
	is     => 'ro',
	isa    => Str,
	reader => '_get_value',
);

# TODO: These two are enums. Define types accordingly.
# Note: see http://wix.sourceforge.net/manual-wix3/wix_xsd_environment.htm for valid values.

has action => (
	is      => 'ro',
	isa     => EnumEnvironmentAction,
	reader  => '_get_action',
	default => 'set',
);

has part => (
	is      => 'ro',
	isa     => Str,
	reader  => '_get_part',
	default => 'all',
);

has permanent => (
	is      => 'ro',
	isa     => YesNoType,
	reader  => '_get_permanent',
	default => 'yes',
);

has system => (
	is      => 'ro',
	isa     => YesNoType,
	reader  => '_get_system',
	default => 'yes',
);

has separator => (
	is      => 'ro',
	isa     => Maybe [Str],
	reader  => '_get_separator',
	default => undef,

#	default => ';',   WiX defaults to this if not included
);

#####################################################################
# Main Methods

########################################
# as_string
# Parameters:
#   None.
# Returns:
#   String containing <Environment> tag defined by this object.

sub as_string {
	my $self = shift;

	my $id = 'E_' . $self->get_id();

	# Print tag.
	my $answer;
	$answer = '<Environment';
	$answer .= $self->print_attribute( 'Id',     $id );
	$answer .= $self->print_attribute( 'Name',   $self->_get_name() );
	$answer .= $self->print_attribute( 'Value',  $self->_get_value() );
	$answer .= $self->print_attribute( 'System', $self->_get_system() );
	$answer .=
	  $self->print_attribute( 'Permanent', $self->_get_permanent() );
	$answer .= $self->print_attribute( 'Action', $self->_get_action() );
	$answer .= $self->print_attribute( 'Part',   $self->_get_part() );
	$answer .=
	  $self->print_attribute( 'Separator', $self->_get_separator() );
	$answer .= " />\n";

	return $answer;
} ## end sub as_string

sub get_namespace {
	return q{xmlns='http://schemas.microsoft.com/wix/2006/wi'};
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
