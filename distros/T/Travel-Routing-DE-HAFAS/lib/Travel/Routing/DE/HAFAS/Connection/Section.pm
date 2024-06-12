package Travel::Routing::DE::HAFAS::Connection::Section;

# vim:foldmethod=marker

use strict;
use warnings;
use 5.014;

use parent 'Class::Accessor';
use DateTime::Duration;
use Travel::Routing::DE::HAFAS::Utils;
use Travel::Status::DE::HAFAS::Journey;

our $VERSION = '0.08';

Travel::Routing::DE::HAFAS::Connection::Section->mk_ro_accessors(
	qw(type schep_dep rt_dep sched_arr rt_arr dep arr arr_delay dep_delay journey distance duration transfer_duration dep_loc arr_loc
	  dep_platform arr_platform dep_cancelled arr_cancelled
	  load)
);

# {{{ Constructor

sub new {
	my ( $obj, %opt ) = @_;

	my $hafas = $opt{hafas};
	my $sec   = $opt{sec};
	my $date  = $opt{date};
	my $locL  = $opt{locL};
	my $prodL = $opt{prodL};

	# himL may only be present in departure monitor mode
	my @remL = @{ $opt{common}{remL} // [] };
	my @himL = @{ $opt{common}{himL} // [] };

	my @msgL = (
		@{ $sec->{dep}{msgL} // [] },
		@{ $sec->{arr}{msgL} // [] },
		@{ $sec->{jny}{msgL} // [] }
	);

	my @messages;
	for my $msg (@msgL) {
		if ( $msg->{type} eq 'REM' and defined $msg->{remX} ) {
			push( @messages, $hafas->add_message( $remL[ $msg->{remX} ] ) );
		}
		elsif ( $msg->{type} eq 'HIM' and defined $msg->{himX} ) {
			push( @messages, $hafas->add_message( $himL[ $msg->{himX} ], 1 ) );
		}
		else {
			say "Unknown message type $msg->{type}";
		}
	}

	my $strptime = DateTime::Format::Strptime->new(
		pattern   => '%Y%m%dT%H%M%S',
		time_zone => 'Europe/Berlin'
	);

	my $sched_dep = handle_day_change(
		date     => $date,
		time     => $sec->{dep}{dTimeS},
		offset   => $sec->{dep}{dTZOffset},
		strp_obj => $strptime,
	);
	my $rt_dep = handle_day_change(
		date     => $date,
		time     => $sec->{dep}{dTimeR},
		offset   => $sec->{dep}{dTZOffset},
		strp_obj => $strptime,
	);
	my $sched_arr = handle_day_change(
		date     => $date,
		time     => $sec->{arr}{aTimeS},
		offset   => $sec->{arr}{aTZOffset},
		strp_obj => $strptime,
	);
	my $rt_arr = handle_day_change(
		date     => $date,
		time     => $sec->{arr}{aTimeR},
		offset   => $sec->{arr}{aTZOffset},
		strp_obj => $strptime,
	);

	my $tco = {};
	for my $tco_id ( @{ $sec->{jny}{dTrnCmpSX}{tcocX} // [] } ) {
		my $tco_kv = $opt{common}{tcocL}[$tco_id];
		$tco->{ $tco_kv->{c} } = $tco_kv->{r};
	}

	my $ref = {
		type          => $sec->{type},
		sched_dep     => $sched_dep,
		rt_dep        => $rt_dep,
		sched_arr     => $sched_arr,
		rt_arr        => $rt_arr,
		dep           => $rt_dep // $sched_dep,
		arr           => $rt_arr // $sched_arr,
		dep_loc       => $locL->[ $sec->{dep}{locX} ],
		arr_loc       => $locL->[ $sec->{arr}{locX} ],
		dep_platform  => $sec->{dep}{dplatfR} // $sec->{dep}{dPlatfS},
		arr_platform  => $sec->{arr}{aplatfR} // $sec->{arr}{aPlatfS},
		dep_cancelled => $sec->{dep}{dCncl},
		arr_cancelled => $sec->{arr}{aCncl},
		load          => $tco,
		messages      => \@messages,
	};

	if ( $sched_dep and $rt_dep ) {
		$ref->{dep_delay} = ( $rt_dep->epoch - $sched_dep->epoch ) / 60;
	}

	if ( $sched_arr and $rt_arr ) {
		$ref->{arr_delay} = ( $rt_arr->epoch - $sched_arr->epoch ) / 60;
	}

	# known types according to 2015 DB Navigator:
	# HIDE, JNY, WALK, BIKE, KISS, PARK, TAXI, TRSF, DEVI
	if ( $sec->{type} eq 'JNY' ) {

		$ref->{journey} = Travel::Status::DE::HAFAS::Journey->new(
			common  => $opt{common},
			date    => $date,
			locL    => $locL,
			prodL   => $prodL,
			journey => $sec->{jny},
			hafas   => $hafas,
		);
	}
	elsif ( $sec->{type} eq 'TRSF' or $sec->{type} eq 'WALK' ) {
		$ref->{distance} = $sec->{gis}{dist};
		my $duration = $sec->{gis}{durS};
		$ref->{duration} = DateTime::Duration->new(
			hours   => substr( $duration, 0, 2 ),
			minutes => substr( $duration, 2, 2 ),
			seconds => substr( $duration, 4, 2 ),
		);
	}

	bless( $ref, $obj );

	return $ref;
}

# }}}

# {{{ Private

sub set_transfer_from_previous_section {
	my ( $self, $prev_sec ) = @_;

	my $delta = $self->dep - $prev_sec->arr;
	$self->{transfer_duration} = $delta;
}

# }}}

# {{{ Accessors

sub messages {
	my ($self) = @_;

	if ( $self->{messages} ) {
		return @{ $self->{messages} };
	}
	return;
}

sub TO_JSON {
	my ($self) = @_;

	my $ret = { %{$self} };

	for my $k ( keys %{$ret} ) {
		if ( ref( $ret->{$k} ) eq 'DateTime' ) {
			$ret->{$k} = $ret->{$k}->epoch;
		}
		if ( ref( $ret->{$k} ) eq 'DateTime::Duration' ) {
			$ret->{$k} = [ $ret->{$k}->in_units( 'days', 'hours', 'minutes' ) ];
		}
	}

	return $ret;
}

# }}}

1;

__END__

=head1 NAME

Travel::Routing::DE::HAFAS::Connection::Section - A single trip between two stops

=head1 SYNOPSIS

	# $connection is a Travel::Routing::DE::HAFAS::Connection object
	for my $sec ( $connection->sections ) {
		if ($sec->type eq 'JNY') {
			printf("%s -> %s\n%s ab %s\n%s an %s\n\n",
				$sec->journey->name,
				$sec->journey->direction,
				$sec->dep->strftime('%H:%M'),
				$sec->dep_loc->name,
				$sec->arr->strftime('%H:%M'),
				$sec->arr_loc->name,
			);
		}
	}

=head1 VERSION

version 0.08

=head1 DESCRIPTION

Travel::Routing::DE::HAFAS::Connection::Section describes a single section
between two stops, which is typically a public transit trip or a walk.  It is
part of a series of sections held by
Travel::Routing::DE::HAFAS::Connection(3pm).

=head1 METHODS

Some accessors depend on the section type. Those are annotated with the types
in which they are valid and return undef when called in other contexts.

=head2 ACCESSORS

=over

=item $section->arr_cancelled

True if the arrival at the end of this section has been cancelled.
False otherwise.

=item $section->arr

DateTime(3pm) object holding the arrival time and date. Based on real-time data
if available, falls back to schedule data otherwise.

=item $section->arr_delay

Arrival delay in minutes. Undef if unknown.

=item $section->arr_loc

Travel::Status::DE::HAFAS::Location(3pm) object describing the arrival stop.

=item $section->arr_platform

Arrival platform as string, not necessarily numeric. Undef if unknown.

=item $section->dep_cancelled

True if the departure at the start of this section has been cancelled.
False otherwise.

=item $section->dep

DateTime(3pm) object holding the departure time and date. Based on real-time
data if available, falls back to schedule data otherwise.

=item $section->dep_delay

Departure dlay in minutes. Undef if unknown.

=item $section->dep_loc

Travel::Status::DE::HAFAS::Location(3pm) object describing the departure stop.

=item $section->dep_platform

=item $section->distance (TRSF, WALK)

Transfer or walking distance in meters. Does not take vertical elevation
changes into account.

=item $section->duration (TRSF, WALK)

DateTime::Duration(3pm) oobject holding the estimated transfer or walk
duration. Typically assumes a slow pace.

=item $section->journey (JNY)

Travel::Status::DE::HAFAS::Journey(3pm) instance describing the journey
(mode of transport, intermediate stops, etc.).

=item $sec->load

Maximum expected occupancy along this section.
Returns a hashref with keys FIRST and SECOND; each value ranges from 1
(low occupancy) to 4 (fully booked).
Returns undef if occupancy data is not available.

=item $section->messages

List of Travel::Status::DE::HAFAS::Message(3pm) objects associated with this
connection section. Typically contains messages related to the mode of
transport, such as construction sites, Wi-Fi availability, and the like.

=item $section->rt_arr

DateTime(3pm) object holding real-time arrival if available.
Undef otherwise.

=item $section->rt_dep

DateTime(3pm) object holding real-time departure if available.
Undef otherwise.

=item $section->sched_arr

DateTime(3pm) object holding scheduled arrival if available.
Undef otherwise.

=item $section->schep_dep

DateTime(3pm) object holding scheduled departure if available.
Undef otherwise.

=item $section->transfer_duration (JNY)

DateTime::Duration(3pm) object holding the difference between the departure of
this journey and the arrival of the previous journey in the connection -- i.e.,
the amount of time available for changing platforms. May be negative.
Undef for the first journey in a connection.

=item $section->type

Type of this section as exposeed by the HAFAS backend.
Known types: B<JNY> (a public transit journey), B<TRSF> (unspecified local
transit), and B<WALK> (walking).

=back

=head1 DIAGNOSTICS

None.

=head1 DEPENDENCIES

DateTime::Duration(3pm), Travel::Routing::DE::HAFAS::Utils(3pm).

=head1 BUGS AND LIMITATIONS

None known.

=head1 SEE ALSO

Travel::Routing::DE::HAFAS(3pm), Travel::Routing::DE::HAFAS::Connection(3pm).

=head1 AUTHOR

Copyright (C) 2023 by Birte Kristina Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

This program is licensed under the same terms as Perl itself.
