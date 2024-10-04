package Travel::Status::DE::EFA::Trip;

use strict;
use warnings;
use 5.010;

use DateTime::Format::Strptime;
use Travel::Status::DE::EFA::Stop;

use parent 'Class::Accessor';

our $VERSION = '3.01';

Travel::Status::DE::EFA::Trip->mk_ro_accessors(
	qw(operator product product_class name line number type id dest_name dest_id));

sub new {
	my ( $obj, %conf ) = @_;

	my $json = $conf{json}{transportation};

	my $ref = {
		operator     => $json->{operator}{name},
		product      => $json->{product}{name},
		product_class => $json->{product}{class},
		polyline     => $json->{coords},
		name         => $json->{name},
		line         => $json->{disassembledName},
		number       => $json->{properties}{trainNumber},
		type         => $json->{properties}{trainType} // $json->{product}{name},
		id           => $json->{id},
		dest_name    => $json->{destination}{name},
		dest_id      => $json->{destination}{id},
		route_raw    => $json->{locationSequence},
		strptime_obj => DateTime::Format::Strptime->new(
			pattern   => '%Y-%m-%dT%H:%M:%SZ',
			time_zone => 'UTC'
		),
	};
	return bless( $ref, $obj );
}

sub polyline {
	my ($self) = @_;

	return @{ $self->{polyline} // [] };
}

sub parse_dt {
	my ( $self, $value ) = @_;

	if ($value) {
		my $dt = $self->{strptime_obj}->parse_datetime($value);
		if ($dt) {
			return $dt->set_time_zone('Europe/Berlin');
		}
	}
	return undef;
}

sub route {
	my ($self) = @_;

	if ( $self->{route} ) {
		return @{ $self->{route} };
	}

	for my $stop ( @{ $self->{route_raw} // [] } ) {
		my $chain = $stop;
		my ( $platform, $place, $name, $name_full );
		while ( $chain->{type} ) {
			if ( $chain->{type} eq 'platform' ) {
				$platform = $chain->{properties}{platformName}
				  // $chain->{properties}{platform};
			}
			elsif ( $chain->{type} eq 'stop' ) {
				$name      = $chain->{disassembledName};
				$name_full = $chain->{name};
			}
			elsif ( $chain->{type} eq 'locality' ) {
				$place = $chain->{name};
			}
			$chain = $chain->{parent};
		}
		push(
			@{ $self->{route} },
			Travel::Status::DE::EFA::Stop->new(
				sched_arr => $self->parse_dt( $stop->{arrivalTimePlanned} ),
				sched_dep => $self->parse_dt( $stop->{departureTimePlanned} ),
				rt_arr    => $self->parse_dt( $stop->{arrivalTimeEstimated} ),
				rt_dep    => $self->parse_dt( $stop->{departureTimeEstimated} ),
				latlon    => $stop->{coord},
				full_name => $name_full,
				name      => $name,
				place     => $place,
				niveau    => $stop->{niveau},
				platform  => $platform,
				id        => $stop->{id},
			)
		);
	}

	delete $self->{route_raw};

	return @{ $self->{route} // [] };
}

sub TO_JSON {
	my ($self) = @_;

	my $ret = { %{$self} };

	delete $ret->{strptime_obj};

	return $ret;
}

1;
