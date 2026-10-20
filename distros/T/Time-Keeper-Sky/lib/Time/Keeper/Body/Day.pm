package Time::Keeper::Body::Day;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

use Time::Keeper::Sky;

1;

__END__

=encoding utf8

=head1 NAME

Time::Keeper::Body::Day - what a planet's day and a star's day share

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $d = $sky->on($date, 'jupiter');       # a Time::Keeper::Planet::Day
    my $d = $sky->on($date, 'Sirius');        # a Time::Keeper::Star::Day
    $d->isa('Time::Keeper::Body::Day');       # both

    $d->body;                                 # 'jupiter', 'Sirius'
    $d->rise;  $d->set;  $d->transit;          # values, or undef
    $d->rises;  $d->sets;  $d->transits;       # all of them in the day
    $d->events;                               # ([rise => value], [transit => value], ...)
    $d->is_up_all_day;  $d->is_down_all_day;

=head1 DESCRIPTION

The methods of L<Time::Keeper::Planet::Day> and L<Time::Keeper::Star::Day>, which
inherit them. A day of either is made by its class's C<on>, or by
L<Time::Keeper::Sky/on> with the body's name; this class makes none of its own.

=head1 METHODS

=head2 rise

=head2 set

=head2 transit

The first rise, set or upper transit in the day, as a L<Time::Keeper> value in the
place's zone, or undef.

=head2 rises

=head2 sets

=head2 transits

All of them in the day, in order (two at most).

=head2 events

Every event of the day in order of time, as C<[name, value]> pairs, the names
C<rise>, C<set> and C<transit>.

=head2 is_up_all_day

=head2 is_down_all_day

On a day with neither a rise nor a set, which way it went.

=head2 body

The body's name: the planet's, or the star's IAU name (C<HR n> for a star without
one).

=head2 date

=head2 zone_name

=head2 start

=head2 end

=head2 place

The day: its L<Time::Keeper::Date>, its zone's name, its first moment and the next
day's, and the place (a L<Time::Keeper::Sun>, which is a L<Time::Keeper::Sky>).

=head1 SEE ALSO

L<Time::Keeper::Planet::Day>, L<Time::Keeper::Star::Day>, L<Time::Keeper::Sky>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
