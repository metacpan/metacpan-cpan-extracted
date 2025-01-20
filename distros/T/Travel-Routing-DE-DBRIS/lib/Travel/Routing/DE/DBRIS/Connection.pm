package Travel::Routing::DE::DBRIS::Connection;

use strict;
use warnings;
use 5.020;
use utf8;

use parent 'Class::Accessor';

use DateTime::Duration;
use Travel::Routing::DE::DBRIS::Connection::Segment;

our $VERSION = '0.01';

Travel::Routing::DE::DBRIS::Connection->mk_ro_accessors(
	qw(changes
	  duration sched_duration rt_duration
	  sched_dep rt_dep dep
	  sched_arr rt_arr arr
	  occupancy occupancy_first occupancy_second
	  price price_unit
	)
);

sub new {
	my ( $obj, %opt ) = @_;

	my $json     = $opt{json};
	my $strpdate = $opt{strpdate_obj};
	my $strptime = $opt{strptime_obj};

	my $ref = {
		changes      => $json->{umstiegsAnzahl},
		id           => $json->{tripId},
		price        => $json->{angebotsPreis}{betrag},
		price_unit   => $json->{angebotsPreis}{waehrung},
		strptime_obj => $strptime,
	};

	if ( $ref->{price_unit} and $ref->{price_unit} eq 'EUR' ) {
		$ref->{price_unit} = '€';
	}

	if ( my $d = $json->{verbindungsDauerInSeconds} ) {
		$ref->{sched_duration} = DateTime::Duration->new(
			hours   => int( $d / 3600 ),
			minutes => int( ( $d % 3600 ) / 60 ),
			seconds => $d % 60,
		);
	}
	if ( my $d = $json->{ezVerbindungsDauerInSeconds} ) {
		$ref->{rt_duration} = DateTime::Duration->new(
			hours   => int( $d / 3600 ),
			minutes => int( ( $d % 3600 ) / 60 ),
			seconds => $d % 60,
		);
	}
	$ref->{duration} = $ref->{rt_duration} // $ref->{sched_duration};

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

	for my $segment ( @{ $json->{verbindungsAbschnitte} // [] } ) {
		push(
			@{ $ref->{segments} },
			Travel::Routing::DE::DBRIS::Connection::Segment->new(
				json         => $segment,
				strptime_obj => $strptime
			)
		);
	}

	for my $key (qw(sched_dep rt_dep dep)) {
		$ref->{$key} = $ref->{segments}[0]{$key};
	}
	for my $key (qw(sched_arr rt_arr arr)) {
		$ref->{$key} = $ref->{segments}[-1]{$key};
	}

	bless( $ref, $obj );

	return $ref;
}

sub segments {
	my ($self) = @_;

	return @{ $self->{segments} // [] };
}

sub TO_JSON {
	my ($self) = @_;

	my $ret = { %{$self} };

	return $ret;
}

1;
