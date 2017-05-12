package WiX3::XML::RegistryKey;

####################################################################
# WiX3::XML::RegistryKey - Object that represents an <RegistryKey> tag.
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
use WiX3::Types qw( EnumRegistryRootType EnumRegistryKeyAction );
use MooseX::Types::Moose qw( Str Maybe Bool );
use WiX3::Util::StrictConstructor;

our $VERSION = '0.011';

# http://wix.sourceforge.net/manual-wix3/wix_xsd_registrykey.htm

with 'WiX3::XML::Role::TagAllowsChildTags';

# Has WiX3::XML::RegistryKey and WiX3::XML::RegistryValue as children.

#####################################################################
# Accessors:
#   see new.

has id => (
	is       => 'ro',
	isa      => Str,
	reader   => 'get_id',
	required => 0,
);

has action => (
	is     => 'ro',
	isa    => EnumRegistryKeyAction,
	reader => '_get_action',
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

#####################################################################
# Main Methods

########################################
# as_string
# Parameters:
#   None.
# Returns:
#   String containing <RegistryKey> tag defined by this object.

sub as_string {
	my $self = shift;

	my $id;
	if ( $self->get_id() ) {
		$id = 'RK_' . $self->get_id();
	}

	# Print tag.
	my $answer;
	$answer = '<RegistryKey';
	$answer .= $self->print_attribute( 'Id',     $id );
	$answer .= $self->print_attribute( 'Root',   $self->_get_root() );
	$answer .= $self->print_attribute( 'Key',    $self->_get_key() );
	$answer .= $self->print_attribute( 'Action', $self->_get_action() );
	$answer .= ">\n";
	my $child_string = q{};
	$child_string = $self->indent( 2, $self->as_string_children() )
	  if $self->has_child_tags();
	chomp $child_string;
	$answer .= "$child_string\n</RegistryKey>\n";

	return $answer;
} ## end sub as_string

sub get_namespace {
	return q{xmlns='http://schemas.microsoft.com/wix/2006/wi'};
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
