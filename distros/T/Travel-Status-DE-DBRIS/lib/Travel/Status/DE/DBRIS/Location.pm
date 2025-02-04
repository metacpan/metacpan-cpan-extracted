package Travel::Status::DE::DBRIS::Location;

use strict;
use warnings;
use 5.020;

use parent 'Class::Accessor';

our $VERSION = '0.05';

Travel::Status::DE::DBRIS::Location->mk_ro_accessors(
	qw(eva id lat lon name products type is_cancelled is_additional is_separation display_priority
	  dep arr sched_dep sched_arr rt_dep rt_arr arr_delay dep_delay delay
	  platform sched_platform rt_platform
	  occupancy_first occupancy_second occupancy
	)
);

sub new {
	my ( $obj, %opt ) = @_;

	my $json = $opt{json};

	my $ref = {
		eva            => $json->{extId} // $json->{evaNumber},
		id             => $json->{id},
		lat            => $json->{lat},
		lon            => $json->{lon},
		name           => $json->{name},
		products       => $json->{products},
		type           => $json->{type},
		is_cancelled   => $json->{canceled},
		is_additional  => $json->{additional},
		sched_platform => $json->{gleis},
		rt_platform    => $json->{ezGleis},
	};

	if ( $json->{abfahrtsZeitpunkt} ) {
		$ref->{sched_dep}
		  = $opt{strptime_obj}->parse_datetime( $json->{abfahrtsZeitpunkt} );
	}
	if ( $json->{ezAbfahrtsZeitpunkt} ) {
		$ref->{rt_dep}
		  = $opt{strptime_obj}->parse_datetime( $json->{ezAbfahrtsZeitpunkt} );
	}
	if ( $json->{ankunftsZeitpunkt} ) {
		$ref->{sched_arr}
		  = $opt{strptime_obj}->parse_datetime( $json->{ankunftsZeitpunkt} );
	}
	if ( $json->{ezAnkunftsZeitpunkt} ) {
		$ref->{rt_arr}
		  = $opt{strptime_obj}->parse_datetime( $json->{ezAnkunftsZeitpunkt} );
	}

	if ( $ref->{sched_dep} and $ref->{rt_dep} ) {
		$ref->{dep_delay}
		  = $ref->{rt_dep}->subtract_datetime( $ref->{sched_dep} )
		  ->in_units('minutes');
	}

	if ( $ref->{sched_arr} and $ref->{rt_arr} ) {
		$ref->{arr_delay}
		  = $ref->{rt_arr}->subtract_datetime( $ref->{sched_arr} )
		  ->in_units('minutes');
	}

	$ref->{delay} = $ref->{arr_delay} // $ref->{dep_delay};

	for my $occupancy ( @{ $json->{auslastungsmeldungen} // [] } ) {
		if ( $occupancy->{klasse} eq 'KLASSE_1' ) {
			$ref->{occupancy_first} = $occupancy->{stufe};
		}
		if ( $occupancy->{klasse} eq 'KLASSE_2' ) {
			$ref->{occupancy_second} = $occupancy->{stufe};
		}
	}

	if ( $ref->{occupancy_first} and $ref->{occupancy_second} ) {
		$ref->{occupancy}
		  = ( $ref->{occupancy_first} + $ref->{occupancy_second} ) / 2;
	}
	elsif ( $ref->{occupancy_first} ) {
		$ref->{occupancy} = $ref->{occupancy_first};
	}
	elsif ( $ref->{occupancy_second} ) {
		$ref->{occupancy} = $ref->{occupancy_second};
	}

	for my $message ( @{ $json->{priorisierteMeldungen} // [] } ) {
		if ( $message->{type} and $message->{type} eq 'HALT_AUSFALL' ) {
			$ref->{is_cancelled} = 1;
		}
		push( @{ $ref->{messages} }, $message );
	}

	for my $message ( @{ $json->{risMeldungen} // [] } ) {
		if (    $message->{key}
			and $message->{key} eq 'text.realtime.stop.cancelled' )
		{
			$ref->{is_cancelled} = 1;
		}
		$ref->{ris_messages}{ $message->{key} } = $message->{value};
	}

	$ref->{arr}      = $ref->{rt_arr}      // $ref->{sched_arr};
	$ref->{dep}      = $ref->{rt_dep}      // $ref->{sched_dep};
	$ref->{platform} = $ref->{rt_platform} // $ref->{sched_platform};

	bless( $ref, $obj );

	return $ref;
}

sub TO_JSON {
	my ($self) = @_;

	my $ret = { %{$self} };

	for my $k (qw(sched_dep rt_dep dep sched_arr rt_arr arr)) {
		if ( $ret->{$k} ) {
			$ret->{$k} = $ret->{$k}->epoch;
		}
	}

	return $ret;
}

1;
