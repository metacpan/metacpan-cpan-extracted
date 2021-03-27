package Travel::Status::DE::EFA::Result;

use strict;
use warnings;
use 5.010;

no if $] >= 5.018, warnings => 'experimental::smartmatch';

use parent 'Class::Accessor';

our $VERSION = '1.19';

Travel::Status::DE::EFA::Result->mk_ro_accessors(
	qw(countdown date delay destination is_cancelled info key line lineref
	  mot occupancy operator platform platform_db platform_name sched_date sched_time time train_no type)
);

my @mot_mapping = qw{
  zug s-bahn u-bahn stadtbahn tram stadtbus regionalbus
  schnellbus seilbahn schiff ast sonstige
};

sub new {
	my ( $obj, %conf ) = @_;

	my $ref = \%conf;

	if ( defined $ref->{delay} and $ref->{delay} eq '-9999' ) {
		$ref->{delay}        = 0;
		$ref->{is_cancelled} = 1;
	}
	else {
		$ref->{is_cancelled} = 0;
	}

	return bless( $ref, $obj );
}

sub mot_name {
	my ($self) = @_;

	return $mot_mapping[ $self->{mot} ] // 'sonstige';
}

sub route_pre {
	my ($self) = @_;

	return @{ $self->{prev_route} };
}

sub route_post {
	my ($self) = @_;

	return @{ $self->{next_route} };
}

sub route_interesting {
	my ( $self, $max_parts ) = @_;

	my @via = $self->route_post;
	my ( @via_main, @via_show, $last_stop );
	$max_parts //= 3;

	for my $stop (@via) {
		if (
			$stop->name_suf =~ m{ Bf | Hbf | Flughafen | Hauptbahnhof
				| Krankenhaus | Klinik | (?: S $ ) }ox
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

			# FIXME cannot smartmatch $stop since it became an object
			#			if ( $stop ~~ \@via_show or $stop == $last_stop ) {
			#				next;
			#			}
			push( @via_show, $stop );
		}
	}

	return @via_show;
}

sub TO_JSON {
	my ($self) = @_;

	return { %{$self} };
}

1;

__END__

=head1 NAME

Travel::Status::DE::EFA::Result - Information about a single
departure received by Travel::Status::DE::EFA

=head1 SYNOPSIS

    for my $departure ($status->results) {
        printf(
            "At %s: %s to %s from platform %d\n",
            $departure->time, $departure->line, $departure->destination,
            $departure->platform
        );
    }

=head1 VERSION

version 1.19

=head1 DESCRIPTION

Travel::Status::DE::EFA::Result describes a single departure as obtained by
Travel::Status::DE::EFA.  It contains information about the time, platform,
line number and destination.

=head1 METHODS

=head2 ACCESSORS

"Actual" in the description means that the delay (if available) is already
included in the calculation, "Scheduled" means it isn't.

=over

=item $departure->countdown

Actual time in minutes from now until the tram/bus/train will depart.

If delay information is available, it is already included.

=item $departure->date

Actual departure date (DD.MM.YYYY).

=item $departure->delay

Expected delay from scheduled departure time in minutes. A delay of 0
indicates departure on time. undef when no realtime information is available.

=item $departure->destination

Destination name.

=item $departure->info

Additional information related to the departure (string).  If departures for
an address were requested, this is the stop name, otherwise it may be recent
news related to the line's schedule.  If no information is available, returns
an empty string.

=item $departure->is_cancelled

1 if the departure got cancelled, 0 otherwise.

=item $departure->key

Unknown.  Unlike the name may suggest, this is not a unique key / UUID for a
departure: On the same day, different lines departing at the same station
may have the same key.  It might, however, be unique when combined with the
B<line> information.

=item $departure->line

The name/number of the line.

=item $departure->lineref

Travel::Status::DE::EFA::Line(3pm) object describing the departing line in
detail.

=item $departure->mot

Returns the "mode of transport" number. This is usually an integer between 0
and 11.

=item $departure->mot_name

Returns the "mode of transport", for instance "zug", "s-bahn", "tram" or
"sonstige".

=item $departure->occupancy

Returns expected occupancy, if available, undef otherwise.

Occupancy values are passed from the backend as-is. Known values are
"MANY_SEATS" (low occupation), "FEW_SEATS" (high occupation), and
"STANDING_ONLY" (very high occupation).

=item $departure->platform

Departure platform number (may not be a number).

=item $departure->platform_db

true if the platform number is operated by DB ("Gleis x"), false ("Bstg. x")
otherwise.

Unfortunately, there is no distinction between tram and bus platforms yet,
which may also have the same numbers.

=item $departure->route_interesting

List of up to three "interesting" stations served by this departure. Is a
subset of B<route_post>. Each station is a Travel::Status::DE::EFA::Stop(3pm)
object.

=item $departure->route_pre

List of stations the vehicle passed (or will have passed) before this stop.
Each station is a Travel::Status::DE::EFA::Stop(3pm) object.

=item $departure->route_post

List of stations the vehicle will pass after this stop.
Each station is a Travel::Status::DE::EFA::Stop(3pm) object.

=item $departure->sched_date

Scheduled departure date (DD.MM.YYYY).

=item $departure->sched_time

Scheduled departure time (HH:MM).

=item $departure->time

Actual departure time (HH:MM).

=item $departure->train_no

Train number. Only defined if departure is a train.

=item $departure->type

Type of the departure.  Note that efa.vrr.de sometimes puts bogus data in this
field.  See L</DEPARTURE TYPES>.

=back

=head2 INTERNAL

=over

=item $departure = Travel::Status::DE::EFA::Result->new(I<%data>)

Returns a new Travel::Status::DE::EFA::Result object.  You should not need to
call this.

=item $departure->TO_JSON

Allows the object data to be serialized to JSON.

=back

=head1 DEPARTURE TYPES

The following are known so far:

=over

=item * Abellio-Zug

=item * Bus

=item * Eurocity

=item * Intercity-Express

=item * NE (NachtExpress / night bus)

=item * Niederflurbus

=item * R-Bahn (RE / RegionalExpress)

=item * S-Bahn

=item * SB (Schnellbus)

=item * StraE<szlig>enbahn

=item * U-Bahn

=back

=head1 DIAGNOSTICS

None.

=head1 DEPENDENCIES

=over

=item Class::Accessor(3pm)

=back

=head1 BUGS AND LIMITATIONS

C<< $result->type >> may contain bogus data.  This comes from the efa.vrr.de
interface.

=head1 SEE ALSO

Travel::Status::DE::EFA(3pm).

=head1 AUTHOR

Copyright (C) 2011-2015 by Daniel Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.
