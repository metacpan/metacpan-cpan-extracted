package Travel::Status::DE::EFA::Stop;

use strict;
use warnings;
use 5.010;

use parent 'Class::Accessor';

our $VERSION = '3.10';

Travel::Status::DE::EFA::Stop->mk_ro_accessors(
	qw(sched_arr rt_arr arr arr_delay
	  sched_dep rt_dep dep dep_delay
	  occupancy delay distance_m is_cancelled
	  place name full_name id_num id_code latlon
	  platform niveau)
);

sub new {
	my ( $obj, %conf ) = @_;

	my $ref = \%conf;

	if ( $ref->{sched_arr} and $ref->{arr_delay} and not $ref->{rt_arr} ) {
		$ref->{rt_arr}
		  = $ref->{sched_arr}->clone->add( minutes => $ref->{arr_delay} );
	}

	if ( $ref->{sched_dep} and $ref->{dep_delay} and not $ref->{rt_dep} ) {
		$ref->{rt_dep}
		  = $ref->{sched_dep}->clone->add( minutes => $ref->{dep_delay} );
	}

	$ref->{arr} //= $ref->{rt_arr} // $ref->{sched_arr};
	$ref->{dep} //= $ref->{rt_dep} // $ref->{sched_dep};

	if (    $ref->{rt_arr}
		and $ref->{sched_arr}
		and not defined $ref->{arr_delay} )
	{
		$ref->{arr_delay}
		  = $ref->{rt_arr}->subtract_datetime( $ref->{sched_arr} )
		  ->in_units('minutes');
	}

	if (    $ref->{rt_dep}
		and $ref->{sched_dep}
		and not defined $ref->{dep_delay} )
	{
		$ref->{dep_delay}
		  = $ref->{rt_dep}->subtract_datetime( $ref->{sched_dep} )
		  ->in_units('minutes');
	}

	$ref->{delay} = $ref->{dep_delay} // $ref->{arr_delay};

	return bless( $ref, $obj );
}

sub TO_JSON {
	my ($self) = @_;

	my $ret = { %{$self} };

	for my $k (qw(sched_arr rt_arr arr sched_dep rt_dep dep)) {
		if ( $ret->{$k} ) {
			$ret->{$k} = $ret->{$k}->epoch;
		}
	}

	return $ret;
}

1;

__END__

=head1 NAME

Travel::Status::DE::EFA::Stop - Information about a stop (station) contained
in a Travel::Status::DE::EFA::Result's route

=head1 SYNOPSIS

    for my $stop ($departure->route_post) {
        printf(
            "%s -> %s : %40s %s\n",
            $stop->arr ? $stop->arr->strftime('%H:%M') : q{--:--},
            $stop->dep ? $stop->dep->strftime('%H:%M') : q{--:--},
            $stop->name, $stop->platform
        );
    }

=head1 VERSION

version 3.10

=head1 DESCRIPTION

Travel::Status::DE::EFA::Stop describes a single stop of a departure's
route. It is solely based on the respective departure's schedule;
delays or changed platforms are not taken into account.

=head1 METHODS

=head2 ACCESSORS

Most accessors return undef if the corresponding data is not available.

=over

=item $stop->sched_arr

DateTime(3pm) object holding scheduled arrival date and time.

=item $stop->rt_arr

DateTime(3pm) object holding estimated (real-time) arrival date and time.

=item $stop->arr

DateTime(3pm) object holding arrival date and time. Real-time data if
available, schedule data otherwise.

=item $stop->arr_delay

Arrival delay in minutes.

=item $stop->sched_dep

DateTime(3pm) object holding scheduled departure date and time.

=item $stop->rt_dep

DateTime(3pm) object holding estimated (real-time) departure date and time.

=item $stop->dep

DateTime(3pm) object holding departure date and time. Real-time data if
available, schedule data otherwise.

=item $stop->dep_delay

Departure delay in minutes.

=item $stop->delay

Delay in minutes. Departure delya if available, arrival delay otherwise.

=item $stop->distance_m

Distance from request coordinates in meters. undef if the object has not
been obtained by means of a coord request.

=item $stop->id_num

Stop ID (numeric).

=item $stop->id_code

Stop ID (code).

=item $stop->place

Place or city name, for instance "Essen".

=item $stop->full_name

stop name with place or city prefix ("I<City> I<Stop>", for instance
"Essen RE<uuml>ttenscheider Stern").

=item $stop->name

stop name without place or city prefix, for instance "RE<uuml>ttenscheider Stern".

=item $stop->latlon

Arrayref describing the stop's latitude and longitude in WGS84 coordinates.

=item $stop->platform

Platform name/number if available, empty string otherwise.

=back

=head2 INTERNAL

=over

=item $stop = Travel::Status::DE::EFA::Stop->new(I<%data>)

Returns a new Travel::Status::DE::EFA::Stop object.  You should not need to
call this.

=item $stop->TO_JSON

Allows the object data to be serialized to JSON.

=back

=head1 DIAGNOSTICS

None.

=head1 DEPENDENCIES

=over

=item Class::Accessor(3pm)

=back

=head1 BUGS AND LIMITATIONS

This module is a Work in Progress.
Its API may change between minor versions.

=head1 SEE ALSO

Travel::Status::DE::EFA(3pm).

=head1 AUTHOR

Copyright (C) 2015-2025 Birte Kristina Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.
