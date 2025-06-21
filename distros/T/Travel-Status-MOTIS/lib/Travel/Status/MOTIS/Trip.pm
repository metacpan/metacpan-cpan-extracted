package Travel::Status::MOTIS::Trip;

use strict;
use warnings;
use 5.020;

use parent 'Class::Accessor';

use DateTime::Format::ISO8601;

use Travel::Status::MOTIS::Stop;
use Travel::Status::MOTIS::Polyline qw(decode_polyline);

our $VERSION = '0.03';

Travel::Status::MOTIS::Trip->mk_ro_accessors(
	qw(
	  id
	  mode
	  agency
	  route_name
	  route_color
	  route_text_color
	  headsign

	  is_realtime
	  is_cancelled

	  arrival
	  scheduled_arrival
	  realtime_arrival

	  departure
	  scheduled_departure
	  realtime_departure
	)
);

sub new {
	my ( $obj, %opt ) = @_;

	my $json = $opt{json}{legs}[0];
	my $time_zone = $opt{time_zone};

	my $ref = {
		id               => $json->{tripId},
		mode             => $json->{mode},
		agency           => $json->{agencyName},
		route_name       => $json->{routeShortName},
		route_color      => $json->{routeColor},
		route_text_color => $json->{routeTextColor},
		headsign         => $json->{headsign},

		is_cancelled => $json->{cancelled},
		is_realtime  => $json->{realTime},

		raw_stopovers =>
		  [ $json->{from}, @{ $json->{intermediateStops} }, $json->{to} ],
		raw_polyline => $json->{legGeometry},

		time_zone    => $time_zone,
	};

	$ref->{scheduled_departure} = DateTime::Format::ISO8601->parse_datetime(
		$json->{scheduledStartTime} );
	$ref->{scheduled_departure}->set_time_zone( $time_zone );

	if ( $json->{realTime} ) {
		$ref->{realtime_departure}
		  = DateTime::Format::ISO8601->parse_datetime( $json->{startTime} );
		$ref->{realtime_departure}->set_time_zone( $time_zone );
	}

	$ref->{departure} = $ref->{realtime_departure}
	  // $ref->{scheduled_departure};

	$ref->{scheduled_arrival}
	  = DateTime::Format::ISO8601->parse_datetime( $json->{scheduledEndTime} );
	$ref->{scheduled_arrival}->set_time_zone( $time_zone );

	if ( $json->{realTime} ) {
		$ref->{realtime_arrival}
		  = DateTime::Format::ISO8601->parse_datetime( $json->{endTime} );
		$ref->{realtime_arrival}->set_time_zone( $time_zone );
	}

	$ref->{arrival} = $ref->{realtime_arrival} // $ref->{scheduled_arrival};

	bless( $ref, $obj );

	return $ref;
}

sub polyline {
	my ($self) = @_;

	if ( not $self->{raw_polyline} ) {
		return;
	}

	if ( $self->{polyline} ) {
		return @{ $self->{polyline} };
	}

	my $polyline = [ decode_polyline( $self->{raw_polyline} ) ];

	my $gis_distance;

	eval {
		require GIS::Distance;
		$gis_distance = GIS::Distance->new;
	};

	if ($gis_distance) {
		my %minimum_distances;

		for my $stopover ( $self->stopovers ) {
			my $stop = $stopover->stop;

			for my $polyline_index ( 0 .. $#{$polyline} ) {
				my $coordinate = $polyline->[$polyline_index];
				my $distance   = $gis_distance->distance_metal(
					$stop->{lat},       $stop->{lon},
					$coordinate->{lat}, $coordinate->{lon},
				);

				if ( not $minimum_distances{ $stop->id }
					or $minimum_distances{ $stop->id }{distance} > $distance )
				{
					$minimum_distances{ $stop->id } = {
						distance => $distance,
						index    => $polyline_index,
					};
				}
			}
		}

		for my $stopover ( $self->stopovers ) {
			my $stop = $stopover->stop;

			if ( $minimum_distances{ $stop->id } ) {
				$polyline->[ $minimum_distances{ $stop->id }{index} ]{stop}
				  = $stop;
			}
		}
	}

	$self->{polyline} = $polyline;

	return @{ $self->{polyline} };
}

sub stopovers {
	my ($self) = @_;

	if ( $self->{stopovers} ) {
		return @{ $self->{stopovers} };
	}

	@{ $self->{stopovers} } = map {
		Travel::Status::MOTIS::Stopover->new(
			json      => $_,
			realtime  => $self->{is_realtime},
			time_zone => $self->{time_zone},
		)
	} ( @{ $self->{raw_stopovers} // [] } );

	return @{ $self->{stopovers} };
}

sub TO_JSON {
	my ($self) = @_;

	# transform raw_stopovers into stopovers (lazy accessor)
	$self->stopovers;

	# transform raw_polyline into polyline (lazy accessor)
	$self->polyline;

	my $ret = { %{$self} };

	for my $timestamp_key (
		qw(
		arrival
		scheduled_arrival
		realtime_arrival

		departure
		scheduled_departure
		realtime_departure
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
