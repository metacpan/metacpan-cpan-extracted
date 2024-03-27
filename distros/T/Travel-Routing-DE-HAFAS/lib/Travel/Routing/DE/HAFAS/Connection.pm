package Travel::Routing::DE::HAFAS::Connection;

# vim:foldmethod=marker

use strict;
use warnings;
use 5.014;

use parent 'Class::Accessor';
use DateTime::Duration;
use Travel::Routing::DE::HAFAS::Utils;
use Travel::Routing::DE::HAFAS::Connection::Section;

our $VERSION = '0.05';

Travel::Routing::DE::HAFAS::Connection->mk_ro_accessors(
	qw(changes duration sched_dep rt_dep sched_arr rt_arr dep arr dep_platform arr_platform dep_loc arr_loc dep_cancelled arr_cancelled is_cancelled load)
);

# {{{ Constructor

sub new {
	my ( $obj, %opt ) = @_;

	my $hafas      = $opt{hafas};
	my $connection = $opt{connection};
	my $locs       = $opt{locL};

	# himL may only be present in departure monitor mode
	my @remL = @{ $opt{common}{remL} // [] };
	my @himL = @{ $opt{common}{himL} // [] };

	my @msgL = @{ $connection->{msgL} // [] };
	my @secL = @{ $connection->{secL} // [] };

	my $date     = $connection->{date};
	my $duration = $connection->{dur};

	$duration = DateTime::Duration->new(
		hours   => substr( $duration, 0, 2 ),
		minutes => substr( $duration, 2, 2 ),
		seconds => substr( $duration, 4, 2 ),
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

	# dProgType/aProgType: CORRECTED oder PROGNOSED
	my $sched_dep = $connection->{dep}{dTimeS};
	my $rt_dep    = $connection->{dep}{dTimeR};
	my $sched_arr = $connection->{arr}{aTimeS};
	my $rt_arr    = $connection->{arr}{aTimeR};

	for my $ts ( $sched_dep, $rt_dep, $sched_arr, $rt_arr ) {
		if ($ts) {
			$ts = handle_day_change(
				date     => $date,
				time     => $ts,
				strp_obj => $strptime,
			);
		}
	}

	my @sections;
	for my $sec (@secL) {
		push(
			@sections,
			Travel::Routing::DE::HAFAS::Connection::Section->new(
				common => $opt{common},
				date   => $date,
				locL   => $locs,
				sec    => $sec,
				hafas  => $hafas,
			)
		);
	}

	my $prev;
	for my $sec (@sections) {
		if ( $sec->type eq 'JNY' ) {
			if ($prev) {
				$sec->set_transfer_from_previous_section($prev);
			}
			$prev = $sec;
		}
	}

	my $tco = {};
	for my $tco_id ( @{ $connection->{dTrnCmpSX}{tcocX} // [] } ) {
		my $tco_kv = $opt{common}{tcocL}[$tco_id];
		$tco->{ $tco_kv->{c} } = $tco_kv->{r};
	}

	my $dep_cancelled = $connection->{dep}{dCncl} ? 1 : 0;
	my $arr_cancelled = $connection->{arr}{aCncl} ? 1 : 0;
	my $is_cancelled  = $dep_cancelled || $arr_cancelled;

	my $ref = {
		duration      => $duration,
		changes       => $connection->{chg},
		sched_dep     => $sched_dep,
		rt_dep        => $rt_dep,
		sched_arr     => $sched_arr,
		rt_arr        => $rt_arr,
		dep_cancelled => $dep_cancelled,
		arr_cancelled => $arr_cancelled,
		is_cancelled  => $is_cancelled,
		dep           => $rt_dep // $sched_dep,
		arr           => $rt_arr // $sched_arr,
		dep_platform  => $connection->{dep}{dPlatfR}
		  // $connection->{dep}{dPlatfS},
		arr_platform => $connection->{arr}{aPlatfR}
		  // $connection->{arr}{aPlatfS},
		dep_loc  => $locs->[ $connection->{dep}{locX} ],
		arr_loc  => $locs->[ $connection->{arr}{locX} ],
		load     => $tco,
		messages => \@messages,
		sections => \@sections,
	};

	bless( $ref, $obj );

	return $ref;
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

sub sections {
	my ($self) = @_;

	if ( $self->{sections} ) {
		return @{ $self->{sections} };
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

Travel::Routing::DE::HAFAS::Connection - A single connection between two stops

=head1 SYNOPSIS

	for my $connection ( $hafas->connections ) {
		# $connection is a Travel::Routing::DE::HAFAS::Connection object
		for my $section ( $connection->sections ) {
			# $section is a Travel::Routing::DE::HAFAS::Connection::Section object
		}
	}

=head1 VERSION

version 0.05

=head1 DESCRIPTION

Travel::Routing::DE::HAFAS::Connection describes a single connection (or
itinerary) for getting from one stop to another. In addition to overall
connection information, it holds a list of
Travel::Routing::DE::HAFAS::Connection::Section(3pm) objects that describe the
individual parts of the connection.

=head1 METHODS

=head2 ACCESSORS

=over

=item $connection->arr_cancelled

True if the arrival of the last section in this connection has been cancelled,
false otherwise.

=item $connection->arr

DateTime(3pm) object holding the arrival time and date. Based on real-time data
if available, falls back to schedule data otherwise.

=item $connection->arr_loc

Travel::Status::DE::HAFAS::Location(3pm) object describing the arrival stop.

=item $connection->arr_platform

Arrival platform. Undef if unknown.

=item $connection->changes

Number of changes between different modes of transport.

=item $connection->dep_cancelled

True if the departure of the first section in this connection has been
cancelled, false otherwise.

=item $connection->dep

DateTime(3pm) object holding the departure time and date. Based on real-time
data if available, falls back to schedule data otherwise.

=item $connection->dep_loc

Travel::Status::DE::HAFAS::Location(3pm) object describing the departure stop.

=item $connection->dep_platform

Departure platform. Undef if unknown.

=item $connection->duration

DateTime::Duration(3pm) object describing the duration of this connection,
i.e., the time between departure and arrival.

=item $connection->is_cancelled

True if part of this connection has been cancelled.  Depending on the
availability of replacement service, this may or may not indicate that the
connection is no longer possible.

=item $connection->load

Maximum expected occupancy along the connection.
Returns a hashref with keys FIRST and SECOND; each value ranges from 1
(low occupancy) to 4 (fully booked).
Returns undef if occupancy data is not available.

=item $connection->messages

List of Travel::Status::DE::HAFAS::Message(3pm) objects associated with this
connection. Typically contains messages along the lines of "current information
available", "journey cancelled", or "a change between two connection sections
may not be feasible".

=item $connection->rt_arr

DateTime(3pm) object holding real-time arrival if available.
Undef otherwise.

=item $connection->rt_dep

DateTime(3pm) object holding real-time departure if available.
Undef otherwise.

=item $connection->sched_arr

DateTime(3pm) object holding scheduled arrival if available.
Undef otherwise.

=item $connection->sched_dep

DateTime(3pm) object holding scheduled departure if available.
Undef otherwise.

=item $connection->sections

List of Travel::Routing::DE::HAFAS::Connection::Section(3pm) objects that
describe the individual sections of this connection.

=back

=head1 DIAGNOSTICS

None.

=head1 DEPENDENCIES

None.

=head1 BUGS AND LIMITATIONS

None known.

=head1 SEE ALSO

Travel::Routing::DE::HAFAS(3pm), Travel::Routing::DE::HAFAS::Connection::Section(3pm).

=head1 AUTHOR

Copyright (C) 2023 by Birte Kristina Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

This program is licensed under the same terms as Perl itself.
