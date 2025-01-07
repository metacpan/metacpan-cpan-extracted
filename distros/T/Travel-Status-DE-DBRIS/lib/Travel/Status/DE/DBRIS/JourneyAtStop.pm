package Travel::Status::DE::DBRIS::JourneyAtStop;

use strict;
use warnings;
use 5.020;

use parent 'Class::Accessor';

our $VERSION = '0.01';

Travel::Status::DE::DBRIS::JourneyAtStop->mk_ro_accessors(
	qw(type dep sched_dep rt_dep delay is_cancelled line stop_eva id platform rt_platform destination via via_last)
);

sub new {
	my ( $obj, %opt ) = @_;

	my $json     = $opt{json};
	my $strptime = $opt{strptime_obj};

	my $ref = {
		type        => $json->{verkehrmittel}{kurzText},
		line        => $json->{verkehrmittel}{mittelText},
		id          => $json->{journeyId},
		stop_eva    => $json->{bahnhofsId},
		destination => $json->{terminus},
		platform    => $json->{gleis},
		rt_platform => $json->{ezGleis},
		via         => $json->{ueber},
		via_last    => ( $json->{ueber} // [] )->[-1],
	};

	bless( $ref, $obj );

	if ( $json->{zeit} ) {
		$ref->{sched_dep} = $strptime->parse_datetime( $json->{zeit} );
	}
	if ( $json->{ezZeit} ) {
		$ref->{rt_dep} = $strptime->parse_datetime( $json->{ezZeit} );
	}
	$ref->{dep} = $ref->{rt_dep} // $ref->{sched_dep};

	if ( $ref->{sched_dep} and $ref->{rt_dep} ) {
		$ref->{delay} = $ref->{rt_dep}->subtract_datetime( $ref->{sched_dep} )
		  ->in_units('minutes');
	}

	for my $message ( @{ $json->{meldungen} // [] } ) {
		if ( $message->{type} and $message->{type} eq 'HALT_AUSFALL' ) {
			$ref->{is_cancelled} = 1;
		}
		push( @{ $ref->{messages} }, $message );
	}

	return $ref;
}

sub messages {
	my ($self) = @_;

	return @{ $self->{messages} // [] };
}

sub TO_JSON {
	my ($self) = @_;

	my $ret = { %{$self} };

	return $ret;
}

1;
