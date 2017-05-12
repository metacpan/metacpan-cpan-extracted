package WiX3::XML::Custom;

####################################################################
# WiX3::XML::Custom - Object that represents an <Custom> tag.
#
# Copyright 2010 Curtis Jewell
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
use WiX3::Types qw( YesNoType );
use MooseX::Types::Moose qw( Str Int Maybe );
use WiX3::Util::StrictConstructor;

our $VERSION = '0.011';

# http://wix.sourceforge.net/manual-wix3/wix_xsd_custom.htm

with qw(WiX3::XML::Role::Tag WiX3::XML::Role::InnerText);

# No child tags allowed.

#####################################################################
# Accessors:
#   see new.

has action => (
	is       => 'ro',
	isa      => Str,
	reader   => '_get_action',
	required => 1,
);

has after => (
	is      => 'ro',
	isa     => Str,
	reader  => '_get_after',
	default => undef,
);

has before => (
	is      => 'ro',
	isa     => Maybe [Str],
	reader  => '_get_before',
	default => undef,
);

# TODO: This one is an enums. Define a type accordingly.

has onexit => (
	is      => 'ro',
	isa     => Maybe [Str],
	reader  => '_get_onexit',
	default => undef,
);

has overridable => (
	is      => 'ro',
	isa     => Maybe [YesNoType],
	reader  => '_get_overridable',
	default => undef,
);

has sequence => (
	is      => 'ro',
	isa     => Maybe [Int],
	reader  => '_get_sequence',
	default => undef,
);

#####################################################################
# Main Methods

sub as_string {
	my $self = shift;

	my $string;
	$string = '<Custom';

	my @attribute = (
		[ 'Action'      => $self->_get_action(), ],
		[ 'After'       => $self->_get_after(), ],
		[ 'Before'      => $self->_get_before(), ],
		[ 'OnExit'      => $self->_get_onexit(), ],
		[ 'Overridable' => $self->_get_overridable(), ],
		[ 'Sequence'    => $self->_get_sequence(), ],
	);

	my ( $k, $v );

	foreach my $ref (@attribute) {
		( $k, $v ) = @{$ref};
		$string .= $self->print_attribute( $k, $v );
	}

	$string .= $self->inner_text_as_string();

	return $string;
} ## end sub as_string

sub get_namespace {
	return q{xmlns='http://schemas.microsoft.com/wix/2006/wi'};
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
