package WiX3::XML::RegistryValue;

####################################################################
# WiX3::XML::RegistryValue - Object that represents an <RegistryValue> tag.
#
# Copyright 2010 Curtis Jewell, Alexandr Ciornii
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
use WiX3::Types
  qw( YesNoType EnumRegistryRootType EnumRegistryValueType EnumRegistryValueAction );
use MooseX::Types::Moose qw( Str Maybe Bool Undef );
use WiX3::Util::StrictConstructor;

our $VERSION = '0.011';

# http://wix.sourceforge.net/manual-wix3/wix_xsd_registryvalue.htm

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

has root => (
	is     => 'ro',
	isa    => EnumRegistryRootType,
	reader => '_get_root',
);

has key => (
	is     => 'ro',
	isa    => Maybe [Str],
	reader => '_get_key',
);

has action => (
	is      => 'ro',
	isa     => EnumRegistryValueAction,
	reader  => '_get_action',
	default => 'write',
);

has key_path => (
	is     => 'ro',
	isa    => YesNoType | Undef,
	reader => '_get_key_path',

#	default => 'no',
	coerce => 1,
);

has type => (
	is       => 'ro',
	isa      => EnumRegistryValueType,
	reader   => '_get_type',
	required => 1,
);

has value => (
	is     => 'ro',
	isa    => Str,
	reader => '_get_value',
);

#####################################################################
# Main Methods

########################################
# as_string
# Parameters:
#   None.
# Returns:
#   String containing <RegistryValue> tag defined by this object.

sub as_string {
	my $self = shift;

	my $id    = 'RV_' . $self->get_id();
	my $type  = $self->_get_type();
	my $value = $self->_get_value();

	# Print tag.
	my $string = '<RegistryValue';

	my @attribute = (
		[ 'Id'      => $id, ],
		[ 'Root'    => $self->_get_root(), ],
		[ 'Key'     => $self->_get_key(), ],
		[ 'Action'  => $self->_get_action(), ],
		[ 'KeyPath' => $self->_get_key_path(), ],
		[ 'Type'    => $self->_get_type(), ],
	);

	my ( $k, $v );

	foreach my $ref (@attribute) {
		( $k, $v ) = @{$ref};
		$string .= $self->print_attribute( $k, $v );
	}

	if ( 'multiString' eq $type ) {
		$string .= qq{>$value</RegistryValue>\n};
	} else {
		$string .= $self->print_attribute( 'Value', $value );
		$string .= qq{ />\n};
	}

	return $string;
} ## end sub as_string

sub get_namespace {
	return q{xmlns='http://schemas.microsoft.com/wix/2006/wi'};
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
