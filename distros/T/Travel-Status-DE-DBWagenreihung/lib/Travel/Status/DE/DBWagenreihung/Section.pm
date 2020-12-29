package Travel::Status::DE::DBWagenreihung::Section;

use strict;
use warnings;
use 5.020;
use utf8;

use parent 'Class::Accessor';

our $VERSION = '0.05';

Travel::Status::DE::DBWagenreihung::Section->mk_ro_accessors(
	qw(name start_percent end_percent length_percent start_meters end_meters length_meters)
);

sub new {
	my ( $obj, %opt ) = @_;
	my $ref = \%opt;

	$ref->{length_meters}  = $ref->{end_meters} - $ref->{start_meters};
	$ref->{length_percent} = $ref->{end_percent} - $ref->{start_percent};

	return bless( $ref, $obj );
}

sub TO_JSON {
	my ($self) = @_;

	my %copy = %{$self};

	return {%copy};
}

1;
