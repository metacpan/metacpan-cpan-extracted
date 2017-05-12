package Travel::Status::DE::URA::Result;

use strict;
use warnings;
use 5.010;

use parent 'Class::Accessor';

use DateTime::Format::Duration;

our $VERSION = '2.01';

Travel::Status::DE::URA::Result->mk_ro_accessors(
	qw(datetime destination line line_id stop stop_id stop_indicator));

sub new {
	my ( $obj, %conf ) = @_;

	my $ref = \%conf;

	return bless( $ref, $obj );
}

sub countdown {
	my ($self) = @_;

	$self->{countdown} //= $self->datetime->subtract_datetime( $self->{dt_now} )
	  ->in_units('minutes');

	return $self->{countdown};
}

sub countdown_sec {
	my ($self) = @_;
	my $secpattern = DateTime::Format::Duration->new( pattern => '%s' );

	$self->{countdown_sec} //= $secpattern->format_duration(
		$self->datetime->subtract_datetime( $self->{dt_now} ) );

	return $self->{countdown_sec};
}

sub date {
	my ($self) = @_;

	return $self->datetime->strftime('%d.%m.%Y');
}

sub platform {
	my ($self) = @_;

	return $self->{stop_indicator};
}

sub time {
	my ($self) = @_;

	return $self->datetime->strftime('%H:%M:%S');
}

sub type {
	return 'Bus';
}

sub route_interesting {
	my ( $self, $max_parts ) = @_;

	my @via = $self->route_post;
	my ( @via_main, @via_show, $last_stop );
	$max_parts //= 3;

	for my $stop (@via) {
		if (
			$stop->name =~ m{ bf | hbf | Flughafen | bahnhof
				| Krankenhaus | Klinik | bushof | busstation }iox
		  )
		{
			push( @via_main, $stop );
		}
	}
	$last_stop = pop(@via);

	if ( @via_main and $via_main[-1] == $last_stop ) {
		pop(@via_main);
	}
	if ( @via and $via[-1] == $last_stop ) {
		pop(@via);
	}

	if ( @via_main and @via and $via[0] == $via_main[0] ) {
		shift(@via_main);
	}

	if ( @via < $max_parts ) {
		@via_show = @via;
	}
	else {
		if ( @via_main >= $max_parts ) {
			@via_show = ( $via[0] );
		}
		else {
			@via_show = splice( @via, 0, $max_parts - @via_main );
		}

		while ( @via_show < $max_parts and @via_main ) {
			my $stop = shift(@via_main);
			push( @via_show, $stop );
		}
	}

	return @via_show;
}

sub route_pre {
	my ($self) = @_;

	return @{ $self->{route_pre} };
}

sub route_post {
	my ($self) = @_;

	return @{ $self->{route_post} };
}

sub TO_JSON {
	my ($self) = @_;

	return { %{$self} };
}

1;

__END__

=head1 NAME

Travel::Status::DE::URA::Result - Information about a single
departure received by Travel::Status::DE::URA

=head1 SYNOPSIS

    for my $departure ($status->results) {
        printf(
            "At %s: %s to %s (in %d minutes)",
            $departure->time, $departure->line, $departure->destination,
            $departure->countdown
        );
    }

=head1 VERSION

version 2.01

=head1 DESCRIPTION

Travel::Status::DE::URA::Result describes a single departure as obtained by
Travel::Status::DE::URA.  It contains information about the time,
line number and destination.

=head1 METHODS

=head2 ACCESSORS

=over

=item $departure->countdown

Time in minutes from the time Travel::Status::DE::URA was instantiated until
the bus will depart.

=item $departure->countdown_sec

Time in seconds from the time Travel::Status::DE::URA was instantiated until
the bus will depart.

=item $departure->date

Departure date (DD.MM.YYYY)

=item $departure->datetime

DateTime object holding the departure date and time.

=item $departure->destination

Destination name.

=item $departure->line

The name of the line.

=item $departure->line_id

The number of the line.

=item $departure->platform

Shortcut for $departure->stop_indicator, see there.

=item $departure->route_interesting(I<num_stops>)

If the B<results> method of Travel::Status::DE::URA(3pm) was called with
B<calculate_routes> => true: Returns a list of up to I<num_stops> (defaults to
3) stops considered interesting (usually of major importance in the transit
area). Each stop is a Travel::Status::DE::URA::Stop(3pm) object.  Note that the
importance is determined heuristically based on the stop name, so it is not
always accurate.

Returns an empty list if B<calculate_routes> was false.

=item $departure->route_pre

If the B<results> method of Travel::Status::DE::URA(3pm) was called with
B<calculate_routes> => true:
Returns a list containing all stops after the requested one.
Each stop is a Travel::Status::DE::URA::Stop(3pm) object.
Returns an empty list otherwise.

=item $departure->route_post

Same as B<route_pre>, but contains the stops before the requested one.

=item $departure->stop

The stop (name, not object) belonging to this departure.

=item $departure->stop_id

The stop ID belonging to this departure.

=item $departure->stop_indicator

The indicator for this departure at the corresponding stop, usually
describes a platform or sub-stop number.  undef if the stop does not
have such a distinction.

=item $departure->time

Departure time (HH:MM:SS).

=item $departure->type

Vehicle type for this departure. At the moment, this always returns "Bus".
This option exists for compatibility with other Travel::Status libraries.

=back

=head2 INTERNAL

=over

=item $departure = Travel::Status::DE::URA::Result->new(I<%data>)

Returns a new Travel::Status::DE::URA::Result object.  You should not need to
call this.

=item $departure->TO_JSON

Allows the object data to be serialized to JSON.

=back

=head1 DIAGNOSTICS

None.

=head1 DEPENDENCIES

=over

=item Class::Accessor(3pm)

=back

=head1 BUGS AND LIMITATIONS

Unknown.

=head1 SEE ALSO

Travel::Status::DE::URA(3pm), Travel::Status::DE::URA::Stop(3pm).

=head1 AUTHOR

Copyright (C) 2013-2016 by Daniel Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.
