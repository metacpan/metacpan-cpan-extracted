package Travel::Status::MOTIS::Stop;

use strict;
use warnings;
use 5.020;

use parent 'Class::Accessor';

our $VERSION = '0.04';

Travel::Status::MOTIS::Stop->mk_ro_accessors(
	qw(
	  id
	  parent_id
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
		id        => $json->{stopId},
		parent_id => $json->{parentId},
		name      => $json->{name},
		lat       => $json->{lat},
		lon       => $json->{lon},
	};

	bless( $ref, $obj );

	return $ref;
}

sub TO_JSON {
	my ($self) = @_;

	return { %{$self} };
}

1;
