package Travel::Status::MOTIS::Stopover;

use strict;
use warnings;
use 5.020;

use parent 'Class::Accessor';

use DateTime::Format::ISO8601;

our $VERSION = '0.02';

Travel::Status::MOTIS::Stopover->mk_ro_accessors(
	qw(
	  stop

	  is_cancelled
	  is_realtime

	  arrival
	  scheduled_arrival
	  realtime_arrival

	  departure
	  scheduled_departure
	  realtime_departure

	  delay
	  arrival_delay
	  departure_delay

	  track
	  scheduled_track
	  realtime_track
	)
);

sub new {
	my ( $obj, %opt ) = @_;

	my $json      = $opt{json};
	my $realtime  = $opt{realtime} // 0;
	my $cancelled = $opt{cancelled};
	my $time_zone = $opt{time_zone};

	my $ref = {
		stop => Travel::Status::MOTIS::Stop->from_stopover( json => $json ),

		is_realtime  => $realtime,
		is_cancelled => $json->{cancelled} // $cancelled,
	};

	if ( $json->{scheduledArrival} ) {
		$ref->{scheduled_arrival} = DateTime::Format::ISO8601->parse_datetime(
			$json->{scheduledArrival} );
		$ref->{scheduled_arrival}->set_time_zone( $time_zone );
	}

	if ( $json->{arrival} and $realtime ) {
		$ref->{realtime_arrival}
		  = DateTime::Format::ISO8601->parse_datetime( $json->{arrival} );
		$ref->{realtime_arrival}->set_time_zone( $time_zone );
	}

	if ( $json->{scheduledDeparture} ) {
		$ref->{scheduled_departure} = DateTime::Format::ISO8601->parse_datetime(
			$json->{scheduledDeparture} );
		$ref->{scheduled_departure}->set_time_zone( $time_zone );
	}

	if ( $json->{departure} and $realtime ) {
		$ref->{realtime_departure}
		  = DateTime::Format::ISO8601->parse_datetime( $json->{departure} );
		$ref->{realtime_departure}->set_time_zone( $time_zone );
	}

	if ( $ref->{scheduled_arrival} and $ref->{realtime_arrival} ) {
		$ref->{arrival_delay} = $ref->{realtime_arrival}
		  ->subtract_datetime( $ref->{scheduled_arrival} )->in_units('minutes');
	}

	if ( $ref->{scheduled_departure} and $ref->{realtime_departure} ) {
		$ref->{departure_delay}
		  = $ref->{realtime_departure}
		  ->subtract_datetime( $ref->{scheduled_departure} )
		  ->in_units('minutes');
	}

	if ( $json->{scheduledTrack} ) {
		$ref->{scheduled_track} = $json->{scheduledTrack};
	}

	if ( $json->{track} ) {
		$ref->{realtime_track} = $json->{track};
	}

	$ref->{delay} = $ref->{arrival_delay} // $ref->{departure_delay};

	$ref->{arrival}   = $ref->{realtime_arrival} // $ref->{scheduled_arrival};
	$ref->{departure} = $ref->{realtime_departure}
	  // $ref->{scheduled_departure};
	$ref->{track} = $ref->{realtime_track} // $ref->{scheduled_track};

	bless( $ref, $obj );

	return $ref;
}

sub TO_JSON {
	my ($self) = @_;

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
