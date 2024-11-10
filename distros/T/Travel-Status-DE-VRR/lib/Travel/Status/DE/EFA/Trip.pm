package Travel::Status::DE::EFA::Trip;

use strict;
use warnings;
use 5.010;

use DateTime::Format::Strptime;
use Travel::Status::DE::EFA::Stop;

use parent 'Class::Accessor';

our $VERSION = '3.03';

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
		polyline      => $json->{coords},
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
	if ( ref( $ref->{polyline} ) eq 'ARRAY' and @{ $ref->{polyline} } == 1 ) {
		$ref->{polyline} = $ref->{polyline}[0];
	}
	return bless( $ref, $obj );
}

sub polyline {
	my ( $self, %opt ) = @_;

	if ( $opt{fallback} and not @{ $self->{polyline} // [] } ) {
		# TODO add $_->{id} as well?
		return map { $_->{latlon} } $self->route;
	}

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
		my ( $platform, $place, $name, $name_full, $stop_id );
		while ( $chain->{type} ) {
			if ( $chain->{type} eq 'platform' ) {
				$platform = $chain->{properties}{platformName}
				  // $chain->{properties}{platform};
			}
			elsif ( $chain->{type} eq 'stop' ) {
				$name      = $chain->{disassembledName};
				$name_full = $chain->{name};
				$stop_id   = $chain->{properties}{stopId};
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
				stop_id   => $stop_id,
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

version 3.03

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

Copyright (C) 2024 by Birte Kristina Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.
