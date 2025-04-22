package Travel::Status::MOTIS::TripAtStopover;

use strict;
use warnings;
use 5.020;

use DateTime::Format::ISO8601;

use parent 'Class::Accessor';

our $VERSION = '0.01';

Travel::Status::MOTIS::TripAtStopover->mk_ro_accessors(
	qw(
	  id
	  mode
	  agency
	  route_name
	  route_color
	  headsign

	  is_cancelled
	  is_realtime

	  stopover
	)
);

sub new {
	my ( $obj, %opt ) = @_;

	my $json = $opt{json};

	my $ref = {
		id          => $json->{tripId},
		mode        => $json->{mode},
		agency      => $json->{agencyName},
		route_name  => $json->{routeShortName},
		route_color => $json->{routeColor},
		headsign    => $json->{headsign},

		is_cancelled => $json->{cancelled},
		is_realtime  => $json->{realTime},

		stopover => Travel::Status::MOTIS::Stopover->new(
			json => $json->{place},

			# NOTE: $json->{place}->{cancelled} isn't set, we just override this here.
			cancelled => $json->{cancelled},
			realtime  => $json->{realTime},
		),
	};

	bless( $ref, $obj );

	return $ref;
}

sub TO_JSON {
	my ($self) = @_;

	my $ret = { %{$self} };

	for my $timestamp_key (
		qw(
		scheduled_departure
		realtime_departure
		departure
		scheduled_arrival
		realtime_arrival
		arrival
		)
	  )
	{
		if ( $ret->{$timestamp_key} ) {
			$ret->{$timestamp_key} = $ret->{$timestamp_key}->epoch;
		}
	}

	return $ret;
}

1;
