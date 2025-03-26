package Travel::Status::DE::DBRIS::Journey;

use strict;
use warnings;
use 5.020;

use parent 'Class::Accessor';

use Travel::Status::DE::DBRIS::Location;

our $VERSION = '0.08';

Travel::Status::DE::DBRIS::Journey->mk_ro_accessors(
	qw(day id train type number is_cancelled));

sub new {
	my ( $obj, %opt ) = @_;

	my $json     = $opt{json};
	my $strpdate = $opt{strpdate_obj};
	my $strptime = $opt{strptime_obj};

	my $ref = {
		id           => $opt{id},
		day          => $strpdate->parse_datetime( $json->{reisetag} ),
		train        => $json->{zugName},
		is_cancelled => $json->{cancelled},
		raw_route    => $json->{halte},
		raw_polyline => $json->{polylineGroup}{polylineDescriptions},
		strptime_obj => $strptime,
	};

	# Number is either train no (ICE, RE) or line no (S, U, Bus, ...)
	# with no way of distinguishing between those
	( $ref->{type}, $ref->{number} ) = split( qr{\s+}, $ref->{train} );

	# The line number seems to be encoded in the trip ID
	if ( not defined $ref->{number}
		and $opt{id} =~ m{ [#] ZE [#] (?<line> [^#]+ ) [#] ZB [#] }x )
	{
		$ref->{number} = $+{line};
	}

	bless( $ref, $obj );

	for my $message ( @{ $json->{himMeldungen} // [] } ) {
		push( @{ $ref->{messages} }, $message );
	}

	for my $message ( @{ $json->{priorisierteMeldungen} // [] } ) {
		push( @{ $ref->{messages} }, $message );
	}

	for my $attr ( @{ $json->{zugattribute} // [] } ) {
		push( @{ $ref->{attributes} }, $attr );
	}

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

	my $distance;
	my $polyline = [ map { { lon => $_->{lng}, lat => $_->{lat} } }
		  @{ $self->{raw_polyline}[0]{coordinates} } ];

	eval {
		require GIS::Distance;
		$distance = GIS::Distance->new;
	};

	if ($distance) {
		my %min_dist;
		for my $stop ( $self->route ) {
			for my $polyline_index ( 0 .. $#{$polyline} ) {
				my $pl = $polyline->[$polyline_index];
				my $dist
				  = $distance->distance_metal( $stop->{lat}, $stop->{lon},
					$pl->{lat}, $pl->{lon} );
				if ( not $min_dist{ $stop->{eva} }
					or $min_dist{ $stop->{eva} }{dist} > $dist )
				{
					$min_dist{ $stop->{eva} } = {
						dist  => $dist,
						index => $polyline_index,
					};
				}
			}
		}
		for my $stop ( $self->route ) {
			if ( $min_dist{ $stop->{eva} } ) {
				$polyline->[ $min_dist{ $stop->{eva} }{index} ]{stop}
				  = $stop;
			}
		}
	}

	$self->{polyline} = $polyline;

	return @{ $self->{polyline} };
}

sub route {
	my ($self) = @_;

	if ( $self->{route} ) {
		return @{ $self->{route} };
	}

	@{ $self->{route} }
	  = map {
		Travel::Status::DE::DBRIS::Location->new(
			json         => $_,
			strptime_obj => $self->{strptime_obj}
		)
	  } ( @{ $self->{raw_route} // [] },
		@{ $self->{raw_cancelled_route} // [] } );

	return @{ $self->{route} };
}

sub attributes {
	my ($self) = @_;

	return @{ $self->{attributes} // [] };
}

sub messages {
	my ($self) = @_;

	return @{ $self->{messages} // [] };
}

sub TO_JSON {
	my ($self) = @_;

	# transform raw_route into route (lazy accessor)
	$self->route;

	# transform raw_polyline into polyline (lazy accessor)
	$self->polyline;

	my $ret = { %{$self} };

	delete $ret->{strptime_obj};

	for my $k (qw(day)) {
		if ( $ret->{$k} ) {
			$ret->{$k} = $ret->{$k}->epoch;
		}
	}

	return $ret;
}

1;
