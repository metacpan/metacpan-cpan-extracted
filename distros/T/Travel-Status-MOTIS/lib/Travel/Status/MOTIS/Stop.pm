package Travel::Status::MOTIS::Stop;

use strict;
use warnings;
use 5.020;

use parent 'Class::Accessor';

our $VERSION = '0.03';

Travel::Status::MOTIS::Stop->mk_ro_accessors(
	qw(
	  id
	  name
	  type
	  lat
	  lon
	)
);

sub from_match {
	my ( $obj, %opt ) = @_;

	my $json = $opt{json};

	my $ref = {
		id   => $json->{id},
		name => $json->{name},
		lat  => $json->{lat},
		lon  => $json->{lon},
	};

	bless( $ref, $obj );

	return $ref;
}

sub from_stopover {
	my ( $obj, %opt ) = @_;

	my $json = $opt{json};

	my $ref = {
		id   => $json->{stopId},
		name => $json->{name},
		lat  => $json->{lat},
		lon  => $json->{lon},
	};

	bless( $ref, $obj );

	return $ref;
}

sub TO_JSON {
	my ($self) = @_;

	return { %{$self} };
}

1;
