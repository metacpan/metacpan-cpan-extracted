package Travel::Status::DE::EFA::Departure;

use strict;
use warnings;
use 5.010;

use DateTime;
use List::Util qw(any);
use Travel::Status::DE::EFA::Stop;

use parent 'Class::Accessor';

our $VERSION = '3.06';

Travel::Status::DE::EFA::Departure->mk_ro_accessors(
	qw(countdown datetime delay destination is_cancelled key line lineref mot
	  occupancy operator origin platform platform_db platform_name rt_datetime
	  sched_datetime stateless stop_id_num train_type train_name train_no type)
);

my @mot_mapping = qw{
  zug s-bahn u-bahn stadtbahn tram stadtbus regionalbus
  schnellbus seilbahn schiff ast sonstige
};

sub parse_departure {
	my ( $self, $departure ) = @_;
}

sub new {
	my ( $obj, %conf ) = @_;

	my $departure = $conf{json};
	my ( $sched_dt, $real_dt );

	if ( my $dt = $departure->{dateTime} ) {
		$sched_dt = DateTime->new(
			year      => $dt->{year},
			month     => $dt->{month},
			day       => $dt->{day},
			hour      => $dt->{hour},
			minute    => $dt->{minute},
			second    => $dt->{second} // 0,
			time_zone => 'Europe/Berlin',
		);
	}

	if ( my $dt = $departure->{realDateTime} ) {
		$real_dt = DateTime->new(
			year      => $dt->{year},
			month     => $dt->{month},
			day       => $dt->{day},
			hour      => $dt->{hour},
			minute    => $dt->{minute},
			second    => $dt->{second} // 0,
			time_zone => 'Europe/Berlin',
		);
	}

	my @hints
	  = map { $_->{content} } @{ $departure->{servingLine}{hints} // [] };

	my $ref = {
		strp_stopseq_s => $conf{strp_stopseq_s},
		strp_stopseq   => $conf{strp_stopseq},
		rt_datetime    => $real_dt,
		platform       => $departure->{platform},
		platform_name  => $departure->{platformName},
		platform_type  => $departure->{pointType},
		key            => $departure->{servingLine}{key},
		stateless      => $departure->{servingLine}{stateless},
		stop_id_num    => $departure->{stopID},
		line           => $departure->{servingLine}{symbol},
		train_type     => $departure->{servingLine}{trainType},
		train_name     => $departure->{servingLine}{trainName},
		train_no       => $departure->{servingLine}{trainNum},
		origin         => $departure->{servingLine}{directionFrom},
		destination    => $departure->{servingLine}{direction},
		occupancy      => $departure->{occupancy},
		countdown      => $departure->{countdown},
		delay          => $departure->{servingLine}{delay},
		sched_datetime => $sched_dt,
		type           => $departure->{servingLine}{name},
		mot            => $departure->{servingLine}{motType},
		hints          => \@hints,
	};

	if ( defined $ref->{delay} and $ref->{delay} eq '-9999' ) {
		$ref->{delay}        = 0;
		$ref->{is_cancelled} = 1;
	}
	else {
		$ref->{is_cancelled} = 0;
	}

	$ref->{datetime} = $ref->{rt_datetime} // $ref->{sched_datetime};

	bless( $ref, $obj );

	if ( $departure->{prevStopSeq} ) {
		$ref->{prev_route} = $ref->parse_route( $departure->{prevStopSeq},
			$departure->{stopID} );
	}
	if ( $departure->{onwardStopSeq} ) {
		$ref->{next_route} = $ref->parse_route( $departure->{onwardStopSeq},
			$departure->{stopID} );
	}

	return $ref;
}

sub parse_route {
	my ( $self, $stop_seq, $requested_id ) = @_;
	my @ret;

	if ( not $stop_seq ) {
		return \@ret;
	}

	# Oh EFA, you so silly
	if ( ref($stop_seq) eq 'HASH' ) {

		# For lines that start or terminate at the requested stop, onwardStopSeq / prevStopSeq includes the requested stop.
		if ( $stop_seq->{ref}{id} eq $requested_id ) {
			return \@ret;
		}
		$stop_seq = [$stop_seq];
	}

	for my $stop ( @{ $stop_seq // [] } ) {
		my $ref = $stop->{ref};
		my ( $arr, $dep );

		if ( $ref->{arrDateTimeSec} ) {
			$arr = $self->{strp_stopseq_s}
			  ->parse_datetime( $ref->{arrDateTimeSec} );
		}
		elsif ( $ref->{arrDateTime} ) {
			$arr = $self->{strp_stopseq}->parse_datetime( $ref->{arrDateTime} );
		}

		if ( $ref->{depDateTimeSec} ) {
			$dep = $self->{strp_stopseq_s}
			  ->parse_datetime( $ref->{depDateTimeSec} );
		}
		elsif ( $ref->{depDateTime} ) {
			$dep = $self->{strp_stopseq}->parse_datetime( $ref->{depDateTime} );
		}

		push(
			@ret,
			Travel::Status::DE::EFA::Stop->new(
				sched_arr => $arr,
				sched_dep => $dep,
				arr_delay => $ref->{arrValid} ? $ref->{arrDelay} : undef,
				dep_delay => $ref->{depValid} ? $ref->{depDelay} : undef,
				id_num    => $ref->{id},
				id_code   => $ref->{gid},
				full_name => $stop->{name},
				place     => $stop->{place},
				name      => $stop->{nameWO},
				occupancy => $stop->{occupancy},
				platform  => $ref->{platform} || $stop->{platformName} || undef,
			)
		);
	}

	return \@ret;
}

sub id {
	my ($self) = @_;

	if ( $self->{id} ) {
		return $self->{id};
	}

	return $self->{id} = sprintf( '%s@%d(%s)%d',
		$self->stateless =~ s{ }{}gr,
		scalar $self->route_pre
		? ( $self->route_pre )[0]->id
		: $self->stop_id_num,
		$self->sched_datetime->strftime('%Y%m%d'),
		$self->key );
}

sub hints {
	my ($self) = @_;

	return @{ $self->{hints} // [] };
}

sub mot_name {
	my ($self) = @_;

	return $mot_mapping[ $self->{mot} ] // 'sonstige';
}

sub route_pre {
	my ($self) = @_;

	return @{ $self->{prev_route} // [] };
}

sub route_post {
	my ($self) = @_;

	return @{ $self->{next_route} // [] };
}

sub route_interesting {
	my ( $self, $max_parts ) = @_;

	my @via = $self->route_post;
	my ( @via_main, @via_show, $last_stop );
	$max_parts //= 3;

	for my $stop (@via) {
		if (
			$stop->name =~ m{ Bf | Hbf | Flughafen | [Bb]ahnhof
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
			if ( any { $_->name eq $stop->name } @via_show
				or $stop->name eq $last_stop->name )
			{
				next;
			}
			push( @via_show, $stop );
		}
	}

	return @via_show;
}

sub TO_JSON {
	my ($self) = @_;

	# compute on-demand keys
	$self->id;

	my $ret = { %{$self} };

	delete $ret->{strp_stopseq};
	delete $ret->{strp_stopseq_s};

	for my $k (qw(datetime rt_datetime sched_datetime)) {
		if ( $ret->{$k} ) {
			$ret->{$k} = $ret->{$k}->epoch;
		}
	}

	return $ret;
}

1;

__END__

=head1 NAME

Travel::Status::DE::EFA::Departure - Information about a single
departure received by Travel::Status::DE::EFA

=head1 SYNOPSIS

    for my $departure ($status->results) {
        printf(
            "At %s: %s to %s from platform %d\n",
            $departure->datetime->strftime('%H:%M'), $departure->line,
            $departure->destination, $departure->platform
        );
    }

=head1 VERSION

version 3.06

=head1 DESCRIPTION

Travel::Status::DE::EFA::Departure describes a single departure as obtained by
Travel::Status::DE::EFA.  It contains information about the time, platform,
line number and destination.

=head1 METHODS

=head2 ACCESSORS

=over

=item $departure->countdown

Time in minutes from now until the tram/bus/train will depart, including
realtime data if available.

If delay information is available, it is already included.

=item $departure->datetime

DateTime(3pm) object for departure date and time.  Realtime data if available,
schedule data otherwise.

=item $departure->delay

Expected delay from scheduled departure time in minutes. A delay of 0
indicates departure on time. undef when no realtime information is available.

=item $departure->destination

Destination name.

=item $departure->hints

Additional information related to the departure (list of strings). If
departures for an address were requested, this is the stop name, otherwise it
may be recent news related to the line's schedule.

=item $departure->id

Stringified unique(?) identifier of this departure; suitable for passing to
Travel::Status::DE::EFA->new(stopseq) after decomposing it again.
The returned string combines B<stateless>, B<stop_id_num> (or the ID of the first
stop in B<route_pre>, if present), B<sched_datetime>, and B<key>.

=item $departure->is_cancelled

1 if the departure got cancelled, 0 otherwise.

=item $departure->key

Key of this departure of the corresponding line. Unique for a given day when
combined with B<stateless>.

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
"MANY_SEATS" (low occupation), "FEW_SEATS" (high occupation),
"STANDING_ONLY" (very high occupation), and "FULL" (boarding not advised).

=item $departure->origin

Origin name.

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

=item $departure->rt_datetime

DateTime(3pm) object holding the departure date and time according to
realtime data. Undef if unknown / unavailable.

=item $departure->sched_datetime

DateTime(3pm) object holding the scheduled departure date and time.

=item $departure->stateless

Unique line identifier.

=item $departure->train_type

Train type, e.g. "ICE". Typically only defined for long-distance trains.

=item $departure->train_name

Train name, e.g. "ICE International" or "InterCityExpresS" or "Deichgraf".
Typically only defined for long-distance trains.

=item $departure->train_no

Train number. Only defined if departure is a train.

=item $departure->type

Type of the departure.  Note that efa.vrr.de sometimes puts bogus data in this
field.  See L</DEPARTURE TYPES>.

=back

=head2 INTERNAL

=over

=item $departure = Travel::Status::DE::EFA::Departure->new(I<%data>)

Returns a new Travel::Status::DE::EFA::Departure object.  You should not need to
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

Copyright (C) 2011-2025 Birte Kristina Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.
