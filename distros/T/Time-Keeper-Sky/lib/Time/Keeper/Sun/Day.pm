package Time::Keeper::Sun::Day;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.03';

use Time::Keeper::Sun;

1;

__END__

=encoding utf8

=head1 NAME

Time::Keeper::Sun::Day - the sun's events on one civil day at a place

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    my $day = $sun->on(year => 2026, month => 10, day => 15);

    $day->sunrise;  $day->sunset;                  # Time::Keeper values, or undef
    $day->dawn;  $day->dusk(kind => 'nautical');   # civil unless told
    $day->solar_noon;  $day->solar_midnight;
    $day->day_length;                              # a Time::Keeper::Duration, or undef
    $day->is_polar_day;  $day->is_polar_night;
    $day->sunrises;  $day->sunsets;                # all of them
    $day->events;                                  # ([name, value], ...) in order

=head1 DESCRIPTION

What L<Time::Keeper::Sun/on> gives: the moments the sun rose, set, reached its height
and passed through the twilights on one civil day in the place's zone. A day runs
from the midnight the zone had to the next; it is 23, 24 or 25 hours long where the
clocks change, and it holds whatever crossings fall in it, which can be none or two of
a kind. See L<Time::Keeper::Sun/THE DAY>.

Every value is in the place's zone and locale and is rounded to the whole second.

=head1 METHODS

=head2 date

The day, as a L<Time::Keeper::Date>.

=head2 place

The L<Time::Keeper::Sun> place the day was computed for.

=head2 zone_name

The zone's name.

=head2 start

=head2 end

The window's edges as values: the local midnight the day began at, and the one it
ends before.

=head2 sunrise

=head2 sunset

The first sunrise or sunset in the day, or undef when there is none: the sun's upper
limb at the horizon seen from the place's elevation.

=head2 solar_noon

=head2 solar_midnight

The sun's upper and lower transits in the day, or undef.

=head2 dawn

=head2 dusk

    $day->dawn;                          # civil: the sun six degrees down
    $day->dusk(kind => 'nautical');      # twelve
    $day->dawn(kind => 'astronomical');  # eighteen

The beginning and the end of a twilight, or undef.

=head2 sunrises

=head2 sunsets

=head2 solar_noons

=head2 solar_midnights

=head2 dawns

=head2 dusks

Every event of the kind in the day, in order, as a list: empty, one, or two.

=head2 events

Every event of the day in order of time, each a reference to a two-element array of
the event's name and its value. The names are C<sunrise>, C<sunset>, C<civil_dawn>,
C<civil_dusk>, C<nautical_dawn>, C<nautical_dusk>, C<astronomical_dawn>,
C<astronomical_dusk>, C<solar_noon> and C<solar_midnight>.

=head2 day_length

The day's first sunrise to the sunset that follows it, wherever that falls, as a
L<Time::Keeper::Duration>; the whole window when the sun is up all day; undef when
there is no sunrise, or no sunset after it.

=head2 crossings

    my @x = $day->crossings(altitude => 6);   # ([value, 'rising'], [value, 'setting'])

Every moment in the day the sun's centre crosses an altitude, in degrees from -90 to
90, in order of time, each with the way it was going. The altitude is the geometric
one, as the twilights' depths are: C<< altitude => -6 >> gives the civil dawns and
dusks, and C<< altitude => -50/60 >> the sunrises and sunsets of a place at sea level,
to the second. A day the sun never reaches the altitude, or never leaves it, gives
none.

=head2 golden_hours

=head2 blue_hours

    for my $span ($day->golden_hours) {
        my ($start, $end) = @$span;           # values, or undef
    }

The spans of the day the sun's centre is from 6 degrees up to 4 below (golden hour),
or from 4 below to 6 below (blue hour), in order, as C<[start, end]> pairs. The figures
are photographers' and vary between them; these are the commonest. A span that began
before the day has an undef start, and one that runs on past it an undef end: at
Tromso at midsummer the golden hour of the night before ends at 02:56 and the
evening's runs on past midnight, and near a pole at an equinox it lasts all day,
C<[undef, undef]>.

=head2 is_polar_day

=head2 is_polar_night

True when the sun neither rose nor set in the window and was above the horizon all
through it, or below it. They speak of the sun's horizon only: a polar night can still
have a civil dawn and dusk.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
