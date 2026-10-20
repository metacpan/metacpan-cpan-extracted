package Time::Keeper::Sun;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.03';

use Time::Keeper::Sky ();
use Time::Keeper::Sun::Day;

1;

__END__

=encoding utf8

=head1 NAME

Time::Keeper::Sun - sunrise, sunset, twilight and solar noon, for a place and a day, in a time zone

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    use Time::Keeper::Sun;

    my $sun = Time::Keeper::Sun->new(
        latitude => 51.5074, longitude => -0.1278,
        zone     => 'Europe/London',
    );
    my $day = $sun->on(year => 2026, month => 10, day => 15);

    print $day->sunrise, "\n";          # 2026-10-15T07:24:22+01:00
    print $day->sunset, "\n";           # 2026-10-15T18:07:21+01:00
    print $day->solar_noon, "\n";       # 2026-10-15T12:46:17+01:00
    print $day->dawn, "\n";             # 2026-10-15T06:50:39+01:00, civil twilight begins
    print $day->day_length->format, "\n";   # 10 hours, 42 minutes, 59 seconds

    my $p = $sun->position(Time::Keeper->now);
    printf "%.1f degrees up, bearing %.1f\n", $p->{altitude}, $p->{azimuth};
    print $sun->next_sunset(Time::Keeper->now), "\n";

    Time::Keeper::Sun->equinox(year => 2026, month => 'march');    # 2026-03-20T14:45:36Z
    Time::Keeper::Sun->new(place => 'Asia/Tokyo');                # Tokyo, by its zone's name

    use Time::Keeper::Moon;
    Time::Keeper::Moon->phase_name(Time::Keeper->now);             # waxing_crescent
    Time::Keeper::Moon->next(phase => 'full');                     # 2026-10-26T04:11:49Z
    Time::Keeper::Moon->on($date, place => $sun)->moonrise;      # 2026-10-15T13:14:52+01:00

=head1 DESCRIPTION

Time::Keeper::Sun is part of L<Time::Keeper::Sky>, the dist it was renamed to: a
Time::Keeper::Sun is a Time::Keeper::Sky, the observer, and new code can start there.
Everything below works as it did in Time::Keeper::Sun 0.02.

Time::Keeper::Sun gives the moments the sun rises, sets, reaches its height and
passes through the three depths of twilight, for a place on a given day; the sun's
altitude and bearing at any instant; the equinoxes and solstices of a year; and, in
L<Time::Keeper::Moon>, the phases of the moon. Every answer is a L<Time::Keeper> value
in the place's time zone, and a day is that zone's day: it begins at the midnight the
zone had, runs for 23, 24 or 25 hours, and holds whatever crossings fall in it, which
near the poles can be two sunsets or none. Nothing is guessed: a day without a sunrise
gives undef and says why, a date that does not exist dies, and a place must be named.

The astronomy is Jean Meeus's, from I<Astronomical Algorithms> (second edition): the
sun's place to a hundredth of a degree, the moon's phases to a few seconds, the
seasons to under a minute; the horizon is that of Reingold and Dershowitz's
I<Calendrical Calculations>. L</ACCURACY> says what that comes to, measured against the
U.S. Naval Observatory.

=head1 CONSTRUCTOR

=head2 new

    my $sun = Time::Keeper::Sun->new(
        latitude  => 51.5074,          # degrees, north positive
        longitude => -0.1278,          # degrees, east positive
        elevation => 0,                # metres above the horizon seen; see THE HORIZON
        zone      => 'Europe/London',  # the zone whose day is meant; UTC otherwise
        locale    => 'en',             # the locale of the values returned
    );
    my $sun = Time::Keeper::Sun->new(place => 'Europe/London');   # see PLACES

A place. C<latitude> and C<longitude> are required, or C<place> instead of them, and
are checked against their ranges; C<zone> is anything L<Time::Keeper> takes as one
except C<floating>, since a place has an offset; an unknown name, locale or argument
dies naming it.

=head1 PLACE METHODS

=head2 latitude

=head2 longitude

=head2 elevation

=head2 zone_name

=head2 locale

    $sun->latitude;  $sun->longitude;  $sun->elevation;
    $sun->zone_name;                   # Europe/London
    $sun->locale;                      # en

What the place was made with.

=head2 position

    my $p = $sun->position($t);       # $t a Time::Keeper value or an epoch
    my $p = $sun->position($t, precise => 1);
    $p->{altitude};                    # degrees above the horizon, geometric
    $p->{apparent_altitude};           # with refraction, from a degree below the horizon up
    $p->{azimuth};                     # degrees from north through east, 0 to 360
    $p->{hour_angle};                  # degrees, -180 to 180, positive after noon
    $p->{declination};                 # degrees
    $p->{right_ascension};             # degrees
    $p->{equation_of_time};            # seconds, positive when a sundial is ahead of the clock
    $p->{distance};                    # astronomical units

The sun as seen from the place at an instant, as a hash reference of numbers. The
value's zone plays no part: only its instant. The place is good to about a hundredth
of a degree, which is a few seconds of time at the horizon.

With C<< precise => 1 >> the sun comes from the earth's place by the full VSOP87D (see
L<Time::Keeper::Planet>), with the FK5 correction, nutation and aberration of Meeus's
25.9 and 25.10, and the equation of time by 28.1: half an arcsecond, against chapter
25's hundredth of a degree, for ten times the cost (about 6 microseconds). The
events and tracks keep chapter 25, which refraction at the horizon makes as good.

=head2 track

    my $tr = $sun->track(from => $t0, to => $t1, step => 120);
    $tr->{epoch};              # [ $t0's epoch, + 120, + 240, ... ]
    $tr->{altitude};           # and apparent_altitude, azimuth, as position gives them
    $tr->{sub_latitude};       # and sub_longitude, as sub_point gives them

The sun from the place at every C<step> seconds from C<from> to C<to>, as a hash of
array references, one entry per sample: a path to draw, or a day to scrub through.
Each sample is exactly what C<position> and C<sub_point> give at its instant, and the
whole is built in one call, about twice as fast as the same calls one by one.

C<from> and C<to> are Time::Keeper values or epochs, and C<to> must be after C<from>.
C<step> is a whole number of seconds from 1 to 86,400, 60 unless given. The samples
are C<from> plus whole steps, C<to> included when the span is a whole number of steps,
and there may be at most 20,000 of them. An epoch is an integer unless C<from> held a
fraction of a second, which every sample keeps.

=head2 sub_point

    my ($lat, $lon) = $sun->sub_point($t);
    my ($lat, $lon) = Time::Keeper::Sun->sub_point($t);

Where on the earth the sun is overhead at an instant: the latitude, which is its
declination, and the longitude east, -180 to 180, which is minus its Greenwich hour
angle. No place enters into it, so it can be asked of the class. The night side of a
map is everything more than 90 degrees from it.

=head2 on

    my $day = $sun->on(year => 2026, month => 10, day => 15);
    my $day = $sun->on($date);           # a Time::Keeper::Date
    my $day = $sun->on($t);              # a Time::Keeper value: its date in the PLACE's zone
    my $day = $sun->on;                  # today in the place's zone

The sun's events on one civil day at the place, as a L<Time::Keeper::Sun::Day>. The
day is the place's zone's: a value in another zone gives the day it falls in at the
place, not in its own zone. With no argument the day is today by L<Time::Keeper>'s
clock, which C<$Time::Keeper::CLOCK> pins in a test. A date that does not exist, or a
day outside the range, dies naming it.

=head2 next_sunrise

=head2 next_sunset

=head2 previous_sunrise

=head2 previous_sunset

=head2 next_solar_noon

=head2 previous_solar_noon

=head2 next_dawn

=head2 next_dusk

=head2 previous_dawn

=head2 previous_dusk

    $sun->next_sunrise($t);                        # the first sunrise after $t
    $sun->previous_sunset($t);                      # the last sunset before it
    $sun->next_dawn($t, kind => 'astronomical');  # civil unless told

The event nearest an instant on the side asked for, without regard to days: a
L<Time::Keeper> value in the place's zone, strictly after (or before) C<$t>. The search
walks up to a year of solar days and gives undef if nothing is found, which only an
impossible depth can bring about.

=head1 THE DAY

A day is the civil day in the place's zone: from the midnight the zone had to the
next. Where the clocks change in the night the day is 23 or 25 hours long; where they
change at midnight itself (Santiago, Havana) the day begins at the first moment that
exists, and consecutive days always meet exactly. The events of the day are whatever
crossings fall inside that window.

Usually that is one of each. Near the poles, and in zones whose clock is far from the
sun's, it need not be. On the days polar day or polar night begins or ends an event
sits near local midnight, and a civil day can hold two sunsets and no sunrise
(Longyearbyen on 25 August 2026 has a sunset at 00:29 and another at 23:56), or
none of either. The singular methods give the first event of their kind in the day,
or undef; the plural methods give them all; C<is_polar_day> and C<is_polar_night> say
which way a day with neither sunrise nor sunset went. The sun's lower transit can
also fall inside the civil day, so that the day's sunset comes before its sunrise;
C<day_length> is therefore the first sunrise to the sunset that follows it, wherever
that falls, never the day's sunset less its sunrise.

=head1 THE HORIZON

Sunrise and sunset are the moments the upper limb of the sun touches the horizon as
seen from sea level: the centre is 50 arcminutes below the geometric horizon, 34 for
refraction and 16 for the half-diameter, which is the convention of NOAA, USNO and
the almanacs. C<elevation> is the observer's height above the horizon he sees, a
cliff or a tower above the sea; it adds the dip of the horizon and a small refraction
term, as Calendrical Calculations gives them, and it is 0 unless given. A city on a
plateau sees a horizon at its own height and leaves it at 0: Denver at 1,600 metres
would otherwise get its sunrise six minutes early, and neither NOAA nor USNO counts
height at all.

The twilights are at a geometric depression of the sun's centre of 6 degrees (civil),
12 (nautical) and 18 (astronomical), with no term for height.


=head1 CLASS METHODS

=head2 place_of

=head2 places

=head2 places_release

    my ($lat, $lon) = Time::Keeper::Sun->place_of('Asia/Tokyo');   # 35.6544, 139.7447
    my @names = Time::Keeper::Sun->places;                           # every zone with a place
    Time::Keeper::Sun->places_release;                               # 2026e

The coordinates a zone name stands for (see L</PLACES>), every name that has them, and
the tzdata release they come from.

=head2 equinox

=head2 solstice

=head2 seasons

    Time::Keeper::Sun->equinox(year => 2026, month => 'march');     # 2026-03-20T14:46:xxZ
    Time::Keeper::Sun->solstice(year => 2026, month => 'june');     # or december
    Time::Keeper::Sun->seasons(year => 2026);                       # the four, in order
    Time::Keeper::Sun->seasons(year => 2026, zone => 'Asia/Tokyo', locale => 'ja');

The equinoxes (C<march>, C<september>) and solstices (C<june>, C<december>) of a year,
as values in the zone given, UTC otherwise. They are the moments the sun's apparent
longitude passes 0, 90, 180 and 270 degrees, from the formulae of Meeus's chapter 27,
which the book states within 51 seconds of the ephemeris for 1951 to 2050; from 1900
to 2100 they agree with the U.S. Naval Observatory's published times to the minute.
The formulae are given for the years -1000 to 3000; before -1000 they are extrapolated.
An equinox asked for in June, or a solstice in March, dies.

=head2 delta_t

    my $seconds = Time::Keeper::Sun->delta_t($t);        # 69.184 in 2026

Delta T at an instant: the number of seconds Terrestrial Time, the uniform scale the
astronomy is computed in, is ahead of Universal Time, the scale the clocks keep. C<$t>
is a L<Time::Keeper> value or an epoch. See L</DELTA T>.

=head1 DELTA T

From 1972 to the end of Time::Keeper's leap-second table, Delta T is 32.184 seconds
plus the difference between TAI and UTC that the table gives: exact to the fraction of
a second by which UT1 and UTC differ, which is under 0.9 seconds and is ignored. After
the table's last entry the last value holds, which is a guess that no further leap
second is added; the published polynomial for 2005 to 2050 is not used there, since by
2026 it was six seconds above the observed value. Before 1972 Delta T is the polynomial
expressions of Espenak and Meeus, fits to the historical record whose own error is
seconds in the nineteenth century and tens of seconds before 1600.

Delta T moves a sunrise by nothing worth seeing (a hundred seconds of it is one second
of sunrise) and moves an equinox or a phase of the moon one second for one.

=head1 RANGE

Every method computes for the years -1999 to 3000, the span of the Delta T expressions
and of the formulae for the moon's phases, and dies naming the year outside it. The
accuracy stated for each method holds from 1900 to 2100 and degrades outside, as the
underlying fits do.

=head1 ACCURACY

Every value is rounded to the whole second; the accuracy is coarser than that, and
it was measured against two independent sources: the U.S. Naval Observatory's published
data (its one-day, phases and seasons services, to the minute), and the Jet Propulsion
Laboratory's ephemeris DE421 (through Skyfield, to the second, 1900 to 2049).

=over 4

=item sunrise, sunset and the twilights

Within a minute of USNO below 60 degrees of latitude, in 1700 to 2100, and within
four seconds of DE421 (the worst of 283 events, 3.3 seconds, is a civil dusk). Above 60
degrees, two minutes on the days polar day or night begins, when the sun skims the
horizon so slowly that the method's hundredth of a degree is minutes of time. Within a
degree of a pole, half an hour: there the sun takes a day to cross the horizon, and
the sun's parallax, which the method ignores, is ten minutes. Refraction at the
horizon varies with the weather by more than any formula knows, so no method does
better than about a minute.

=item the sun's position

Declination within 0.003 degrees of USNO, altitude and azimuth within 0.01, the
equation of time within 3 seconds, in 1800 to 2050. With C<< precise => 1 >>, within
0.52 arcseconds of DE421 at 1,479 instants from 1900 to 2050 at the same TT, and the
distance within 7e-8 AU; chapter 25's worst at the same instants is 34 arcseconds.

=item the planets' series

VSOP87D as compiled matches every one of the 80 VSOP87D values in IMCCE's check file
(vsop87.chk, 1100 to 2000) to within 7e-11, the file's own last place.

=item the sub-points

The sun's within 0.003 degrees of USNO's declination and 0.01 of its Greenwich hour
angle; the moon's within 0.002 and 0.004; in 1800 to 2050.

=item the moon's phases

In USNO's minute or the one beside it for every phase of 1900, 2026 and 2100, and
within 21 seconds of DE421 for every phase of 1950, 2000 and 2026. The illuminated
fraction within 0.005 of USNO's, which rounds it to a whole percent.

=item the seasons

Within 76 seconds of DE421 from 1900 to 2049, and 66 seconds from 1951: more than the
51 seconds the book states for 1951 to 2050, though within 41 seconds of the book's own
table of 1996 to 2005. In USNO's minute or the one beside it for 1900 to 2100.

=item outside 1900 to 2100

The formulae are given for -1000 to 3000 and the dist computes for -1999 to 3000, but
the accuracy above is measured where oracles exist. Beyond them the fits degrade, and
for an equinox or a phase Delta T's uncertainty enters one for one (see L</DELTA T>).

=back

=head1 PLACES

    Time::Keeper::Sun->new(place => 'Europe/London');                  # London, Europe/London
    Time::Keeper::Sun->new(place => 'Europe/Jersey');                  # London's coordinates, Jersey's zone
    Time::Keeper::Sun->new(place => 'America/Denver', zone => 'UTC');  # Denver's coordinates, the UTC day

A zone is wide: an hour of sunrise and more from one side to the other. The IANA time
zone database names each zone after one city in it and gives that city's coordinates,
to the minute of arc, and C<place> takes them: C<place =E<gt> 'Europe/London'> is
London itself (51 degrees 30 minutes north, 7 minutes west), not everywhere the zone
covers. A link such as C<Europe/Jersey> takes its target's coordinates and keeps its
own name as the zone. C<zone> given beside C<place> replaces the zone, not the
coordinates; C<latitude> or C<longitude> beside it dies. The table is zone1970.tab and
backward of the release C<places_release> names, compiled in; zones that table omits
(the names a country no longer uses as its own) have no place here though
L<Time::Keeper> knows them.

=head1 TESTING

C<on> with no argument, and C<next> and C<previous> with none, read the clock through
L<Time::Keeper>, so C<local $Time::Keeper::CLOCK = $fixed> pins them for a test as it
pins C<now>.

=head1 EXAMPLES

Times that communities derive from the sun are a few lines over these methods; the
angles and proportions are theirs to choose, and these are only shapes:

    # a proportional hour (one twelfth of the daylight) and the end of the third
    my $day   = $sun->on($date);
    my $hour  = $day->day_length->total('seconds') / 12;
    my $third = $day->sunrise->plus(seconds => 3 * $hour);

    # dawn at a chosen depression: the twilights come at 6, 12 and 18 degrees
    my $dawn18 = $day->dawn(kind => 'astronomical');

=head1 SEE ALSO

L<Time::Keeper>, whose values these are, and L<Time::Keeper::Zone>, whose zones.
L<Time::Keeper::Moon>, the moon's phases, place, rising and setting, and
L<Time::Keeper::Sun::Day> and L<Time::Keeper::Moon::Day>, in this distribution.

L<Astro::Sunrise> and L<DateTime::Event::Sunrise> (Schlyter's algorithm, a UTC
offset for a zone), L<Astro::MoonPhase> (Moontool), L<Astro::Coord::ECI> (a satellite
toolkit that knows the sun and moon), which answer some of the same questions.

Jean Meeus, I<Astronomical Algorithms>, second edition, Willmann-Bell, 1998: chapters
12, 13, 16, 22, 25, 27, 28, 48 and 49. Edward Reingold and Nachum Dershowitz,
I<Calendrical Calculations>, for the horizon's depression and dip. Espenak and
Meeus, I<Polynomial Expressions for Delta T>, for the years before 1972.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
