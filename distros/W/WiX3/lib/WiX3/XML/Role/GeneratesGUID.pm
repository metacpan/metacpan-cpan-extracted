package WiX3::XML::Role::GeneratesGUID;

use 5.008003;
use Moose::Role 2;
use WiX3::Types qw( Host );
require WiX3::XML::GeneratesGUID::Object;

our $VERSION = '0.011';

# requires 'get_path';

has sitename => (
	is      => 'ro',
	isa     => Host,
	reader  => '_get_sitename',
	default => q{www.perl.invalid},
);

has _guidobject => (
	is       => 'ro',
	isa      => 'WiX3::XML::GeneratesGUID::Object',
	lazy     => 1,
	init_arg => undef,
	default  => sub {
		my $self = shift;
		return WiX3::XML::GeneratesGUID::Object->new(
			sitename => $self->_get_sitename() );
	},
	handles => [qw(generate_guid)],
);

sub id_build {
	my $self = shift;

	my $id = $self->get_guid();
	$id =~ s{-}{_}gsm;
	return $id;
}

sub guid_build {
	my $self = shift;

	if ( defined $self->get_path() ) {
		return $self->generate_guid( $self->get_path() );
	} else {
		return $self->generate_guid( $self->get_id() );
	}
}

no Moose::Role;

1;                                     # Magic true value required at end of module
