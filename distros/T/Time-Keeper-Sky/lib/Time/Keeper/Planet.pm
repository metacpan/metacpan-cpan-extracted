package Time::Keeper::Planet;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

use Time::Keeper::Sky;
use Time::Keeper::Planet::Day;

1;

__END__

=encoding utf8

=head1 NAME

Time::Keeper::Planet - the planets' places, brightness and phases, by the full VSOP87D

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Time::Keeper::Planet;

    my $h = Time::Keeper::Planet->heliocentric('mars', $t);
    $h->{longitude};  $h->{latitude};    # degrees, ecliptic and equinox of date
    $h->{radius};                        # AU from the sun

    my @names = Time::Keeper::Planet->planets;   # mercury venus mars ... neptune pluto

    my $p = Time::Keeper::Planet->position('jupiter', $t);
    $p->{right_ascension};  $p->{declination};  $p->{magnitude};  $p->{illumination};
    my $q = Time::Keeper::Planet->position('jupiter', $t, place => $sky);   # + altitude, azimuth

    my $tr = Time::Keeper::Planet->track('mars', from => $t0, to => $t1, step => 3600, place => $sky);
    my ($lat, $lon) = Time::Keeper::Planet->sub_point('venus', $t);

    my $d = Time::Keeper::Planet->on($date, 'venus', place => $sky);   # a Time::Keeper::Planet::Day
    $d->rise;  $d->set;  $d->transit;
    Time::Keeper::Planet->next_rise('mars', $t, place => $sky);
    Time::Keeper::Planet->next(event => 'opposition', planet => 'mars', after => $t);

=head1 DESCRIPTION

The planets from Mercury to Neptune by VSOP87 (Bretagnon and Francou, 1988), in its
version D: every one of its 31,577 terms, which hold the planets to under an
arcsecond from 2000 BC to AD 6000 for the inner planets, and to about an arcsecond over
a shorter span for the outer. The terms are compiled into the dist from the published
files; nothing is read at run time. Pluto, which VSOP87 lacks, is Meeus's chapter 37,
from 1885 to 2099.

A planet's apparent place is found as the Astronomical Almanac finds it: the light-time
iterated, the planet where it was when its light left and the earth where it is; the
sun's deflection of the light; the annual aberration from the earth's velocity; the
correction of VSOP87's frame to FK5, the nutation and the true obliquity (Meeus 32.3,
chapter 33). The magnitudes are Mallama and Hilton's (2018), which the Almanac uses,
including Saturn's rings and Uranus's tilt.

=head1 METHODS

=head2 heliocentric

    my $h = Time::Keeper::Planet->heliocentric($name, $t);   # $t a Time::Keeper value or an epoch

A planet's place seen from the sun's centre at an instant, as a hash reference: its
ecliptic C<longitude> (0 to 360) and C<latitude> in degrees, referred to the ecliptic
and the mean equinox of the date, and its C<radius> from the sun in astronomical
units. C<$name> is one of C<planets>, or C<earth>. The time is converted to
Terrestrial Time (see L<Time::Keeper::Sun/DELTA T>), which VSOP87's dynamical time
follows to within two milliseconds.

=head2 planets

    my @names = Time::Keeper::Planet->planets;

The planets' names, from the sun outwards: mercury, venus, mars, jupiter, saturn,
uranus, neptune, pluto.

=head2 position

    my $p = Time::Keeper::Planet->position($name, $t);
    my $p = Time::Keeper::Planet->position($name, $t, place => $sky);
    $p->{right_ascension};  $p->{declination};   # apparent, of date, degrees
    $p->{longitude};  $p->{latitude};            # apparent ecliptic of date, degrees
    $p->{distance};                              # AU from the earth's centre
    $p->{light_time};                            # seconds
    $p->{elongation};                            # degrees from the sun, 0 to 180
    $p->{phase_angle};                           # degrees, at the planet between the sun and the earth
    $p->{illumination};                          # the fraction of the disc lit
    $p->{diameter};                              # arcseconds, equatorial
    $p->{magnitude};                             # visual, or undef where there is none
    $p->{constellation};                         # the IAU abbreviation of where it is, 'Leo'

A planet's apparent place seen from the earth's centre at an instant, as a hash
reference of numbers. With a place (a L<Time::Keeper::Sky>, which a
L<Time::Keeper::Sun> is) it also holds C<altitude>, C<apparent_altitude>,
C<azimuth> and C<hour_angle> as seen from there, with the planet's parallax.

C<magnitude> is undef where Mallama and Hilton's formulae give none: always for Pluto,
for Saturn at a phase angle over 6.5 degrees, and for Neptune at one over 1.9 degrees
before 2000. Pluto's place dies outside 1885 to 2099.

=head2 track

    my $tr = Time::Keeper::Planet->track($name, from => $t0, to => $t1, step => 3600, place => $sky);
    $tr->{epoch};  $tr->{magnitude};  $tr->{illumination};  $tr->{distance};
    $tr->{sub_latitude};  $tr->{sub_longitude};
    $tr->{altitude};  $tr->{apparent_altitude};  $tr->{azimuth};   # with a place

The planet at every step, as arrays, each sample exactly what C<position> and
C<sub_point> give; the arguments and limits are those of L<Time::Keeper::Sun/track>.

=head2 sub_point

    my ($lat, $lon) = Time::Keeper::Planet->sub_point($name, $t);

Where on the earth the planet is overhead: its apparent declination, and minus its
Greenwich hour angle, east positive, -180 to 180.

=head2 on

    my $d = Time::Keeper::Planet->on($date, $name, place => $sky);
    my $d = Time::Keeper::Planet->on($t, $name, place => $sky);    # the value's date at the place

The planet's rises, sets and transits on one civil day at the place, as a
L<Time::Keeper::Planet::Day>. C<place> is required; C<zone> and C<locale> may change the
day and the values' zone as on the moon's methods.

=head2 next_rise

=head2 next_set

=head2 previous_rise

=head2 previous_set

=head2 next_transit

=head2 previous_transit

    Time::Keeper::Planet->next_rise('jupiter', $t, place => $sky);

The next or previous event from an instant, seen from the place, or undef if there is
none within a year (near a pole, where a planet can stay down for months).

=head2 next

=head2 previous

    Time::Keeper::Planet->next(event => 'opposition', planet => 'mars', after => $t);
    Time::Keeper::Planet->previous(event => 'greatest_elongation_east', planet => 'venus', before => $t);

A planet's next or previous configuration with the sun, after (before) an instant or
now, as a value in UTC, or in the zone of C<place>, C<zone> or C<locale> as on the moon's
methods. Undef if none falls within three synodic periods. The events:

=over 4

=item conjunction, opposition

The planet's apparent ecliptic longitude equal to the sun's, or opposite it. Every
planet has conjunctions; only those beyond the earth have oppositions.

=item inferior_conjunction, superior_conjunction

For Mercury and Venus: a conjunction with the planet nearer than the sun, or beyond it.
(C<conjunction> gives either.)

=item greatest_elongation_east, greatest_elongation_west

For Mercury and Venus: the greatest angle from the sun, east of it (an evening sky)
or west (a morning one).

=item station_retrograde, station_direct

The planet's motion in longitude stopping, before it goes backwards (retrograde) or
forwards again (direct).

=back

The greatest elongations and the stations are extrema, flat in time: their moment is
good to minutes, their value (the elongation, the longitude) to the place's arcsecond.

=head1 ACCURACY

Against JPL's DE421 through Skyfield, every 37 days from 1900 to 2050 at the same
Terrestrial Time (so that Delta T is left out), on the sky: Mercury 0.53, Venus 0.52,
Mars 0.53, Jupiter 0.65, Saturn 0.66 arcseconds at worst; Uranus 1.7, Neptune 2.5,
Pluto 1.7. VSOP87 was fitted to JPL's DE200 of 1982, and the outer planets' orbits
have moved since; for them the series, not this code, is the limit. The distance is
within 2e-7 AU for the inner planets and 8e-5 AU for Neptune.

The phase angle agrees with DE421's within 0.00002 degrees, and the magnitudes are
Mallama and Hilton's formulae to the last digit (checked against Skyfield's own on
the same numbers). The formulae themselves are good to a few hundredths of a
magnitude; Mars's, without its rotation and season terms, to about 0.06.

Rises, sets and transits, against Skyfield's almanac for the planets at 12 places on 4
days of 2026 (1,129 events): every count the same, within 0.7 seconds below 60 degrees
of latitude and 0.8 above. Conjunctions and oppositions from 2020 to 2039 within 46
seconds; greatest elongations within 40 seconds. A station is where the motion in
longitude is nothing, and the motion of a slow planet changes so little there that
VSOP87's arcseconds move it a long way: Mercury's, Venus's and Mars's are within 10
minutes, Jupiter's to Pluto's within 11 to 43. Closest approaches within 15 seconds,
the separation within 0.21 arcseconds (4.2 with the moon, whose place is Meeus's
chapter 47).

=head1 SEE ALSO

L<Time::Keeper::Sky>, L<Time::Keeper::Sun>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
