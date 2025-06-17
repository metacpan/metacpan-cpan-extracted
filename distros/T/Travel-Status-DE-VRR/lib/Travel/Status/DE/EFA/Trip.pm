package Travel::Status::DE::EFA::Trip;

use strict;
use warnings;
use 5.010;

use DateTime::Format::Strptime;
use Travel::Status::DE::EFA::Stop;

use parent 'Class::Accessor';

our $VERSION = '3.11';

Travel::Status::DE::EFA::Trip->mk_ro_accessors(
	qw(operator product product_class name line number type id dest_name dest_id)
);

sub new {
	my ( $obj, %conf ) = @_;

	my $json = $conf{json}{transportation} // $conf{json}{leg}{transportation};

	my $ref = {
		operator      => $json->{operator}{name},
		product       => $json->{product}{name},
		product_class => $json->{product}{class},
		polyline_raw  => $conf{json}{leg}{coords},
		name          => $json->{name},
		line          => $json->{disassembledName},
		number        => $json->{properties}{trainNumber},
		type      => $json->{properties}{trainType} // $json->{product}{name},
		id        => $json->{id},
		dest_name => $json->{destination}{name},
		dest_id   => $json->{destination}{id},
		route_raw => $json->{locationSequence}
		  // $conf{json}{leg}{stopSequence},
		strptime_obj => DateTime::Format::Strptime->new(
			pattern   => '%Y-%m-%dT%H:%M:%SZ',
			time_zone => 'UTC'
		),
	};
	if ( ref( $ref->{polyline_raw} ) eq 'ARRAY'
		and @{ $ref->{polyline_raw} } == 1 )
	{
		$ref->{polyline_raw} = $ref->{polyline_raw}[0];
	}
	return bless( $ref, $obj );
}

sub polyline {
	my ( $self, %opt ) = @_;

	if ( $self->{polyline} ) {
		return @{ $self->{polyline} };
	}

	if ( not @{ $self->{polyline_raw} // [] } ) {
		if ( $opt{fallback} ) {
			return map {
				{
					lat  => $_->{latlon}[0],
					lon  => $_->{latlon}[1],
					stop => $_,
				}
			} $self->route;
		}
		return;
	}

	$self->{polyline} = [ map { { lat => $_->[0], lon => $_->[1] } }
		  @{ $self->{polyline_raw} } ];
	my $distance;

	eval {
		require GIS::Distance;
		$distance = GIS::Distance->new;
	};

	if ($distance) {
		my %min_dist;
		for my $stop ( $self->route ) {
			for my $polyline_index ( 0 .. $#{ $self->{polyline} } ) {
				my $pl   = $self->{polyline}[$polyline_index];
				my $dist = $distance->distance_metal(
					$stop->{latlon}[0],
					$stop->{latlon}[1],
					$pl->{lat}, $pl->{lon}
				);
				if ( not $min_dist{ $stop->{id_code} }
					or $min_dist{ $stop->{id_code} }{dist} > $dist )
				{
					$min_dist{ $stop->{id_code} } = {
						dist  => $dist,
						index => $polyline_index,
					};
				}
			}
		}
		for my $stop ( $self->route ) {
			if ( $min_dist{ $stop->{id_code} } ) {
				$self->{polyline}[ $min_dist{ $stop->{id_code} }{index} ]{stop}
				  = $stop;
			}
		}
	}

	return @{ $self->{polyline} };
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
		my ( $platform, $place, $name, $name_full, $id_num, $id_code );
		while ( $chain->{type} ) {
			if ( $chain->{type} eq 'platform' ) {
				$platform = $chain->{properties}{platformName}
				  // $chain->{properties}{platform};
			}
			elsif ( $chain->{type} eq 'stop' ) {
				$name      = $chain->{disassembledName};
				$name_full = $chain->{name};
				$id_code   = $chain->{id};
				$id_num    = $chain->{properties}{stopId};
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
				occupancy => $stop->{properties}{occupancy},
				is_cancelled => $stop->{isCancelled},
				latlon       => $stop->{coord},
				full_name    => $name_full,
				name         => $name,
				place        => $place,
				niveau       => $stop->{niveau},
				platform     => $platform,
				id_code      => $id_code,
				id_num       => $id_num,
			)
		);
	}

	delete $self->{route_raw};

	return @{ $self->{route} // [] };
}

sub TO_JSON {
	my ($self) = @_;

	# lazy loading
	$self->route;

	# lazy loading
	$self->polyline;

	my $ret = { %{$self} };

	delete $ret->{strptime_obj};

	return $ret;
}

1;

__END__

=head1 NAME

Travel::Status::DE::EFA::Trip - Information about an individual public transit
trip

=head1 SYNOPSIS

    printf( "%s %s -> %s\n", $trip->type, $trip->line // q{}, $trip->dest_name );
    for my $stop ( $trip->route ) {
        ...;
    }

=head1 VERSION

version 3.11

=head1 DESCRIPTION

Travel::Status::DE::EFA::Trip describes a single trip / journey of a public
transport line.

=head1 METHODS

=head2 ACCESSORS

Most accessors return undef if the corresponding data is not available.

=over

=item $trip->operator

Operator name.

=item $trip->product

Product name.

=item $trip->product_class

Product class.

=item $trip->name

Trip or line name.

=item $trip->line

Line identifier. Note that this is not necessarily numeric.

=item $trip->number

Trip/journey number.

=item $trip->type

Transport / vehicle type, e.g. "RE" or "Bus".

=item $trip->id

Unique(?) trip ID

=item $trip->dest_name

Name of the trip's destination stop

=item $trip->dest_id

ID of the trip's destination stop

=item $trip->route

List of Travel::Status::DE::EFA::Stop(3pm) objects describing the route of this
trip.

Note: The EFA API requires a stop to be specified when requesting trip details.
The stops returned by this accessor appear to be limited to stops after the
requested stop; earlier ones may be missing.

=item $journey->polyline(I<%opt>)

List of geocoordinates that describe the trips's route.
Each list entry is a hash with the following keys.

=over

=item * lon (longitude)

=item * lat (latitude)

=item * stop (Stop object for this location, if any. undef otherwise)

=back

Note that stop is not provided by the backend and instead inferred by this
module.

If the backend does not provide geocoordinates and this accessor was called
with B< fallback > set to a true value, it returns the list of stop coordinates
instead. Otherwise, it returns an empty list.

=back

=head2 INTERNAL

=over

=item $trip = Travel::Status::DE::EFA::Trip->new(I<%data>)

Returns a new Travel::Status::DE::EFA::Trip object.  You should not need to
call this.

=item $trip->TO_JSON

Allows the object data to be serialized to JSON.

=back

=head1 DIAGNOSTICS

None.

=head1 DEPENDENCIES

=over

=item Class::Accessor(3pm)

=item DateTime::Format::Strptime(3pm)

=item Travel::Status::DE::EFA::Stop(3pm)

=back

=head1 BUGS AND LIMITATIONS

This module is a Work in Progress.
Its API may change between minor versions.

=head1 SEE ALSO

Travel::Status::DE::EFA(3pm).

=head1 AUTHOR

Copyright (C) 2024-2025 Birte Kristina Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.
