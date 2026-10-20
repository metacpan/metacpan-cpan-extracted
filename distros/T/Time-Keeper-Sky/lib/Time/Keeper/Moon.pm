package Time::Keeper::Moon;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.03';

use Time::Keeper::Sun;
use Time::Keeper::Moon::Day;

1;

__END__

=encoding utf8

=head1 NAME

Time::Keeper::Moon - the phases of the moon, as Time::Keeper values

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    use Time::Keeper::Moon;

    my $t = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 12, zone => 'UTC');

    Time::Keeper::Moon->phase_name($t);                      # waxing_crescent
    Time::Keeper::Moon->illumination($t);                    # 0.22
    Time::Keeper::Moon->age($t);                             # 4.8 days since the new moon
    Time::Keeper::Moon->next(phase => 'full', after => $t);  # 2026-10-26T04:11:49Z
    Time::Keeper::Moon->phases(from => $a, to => $b);        # ([new, value], [first_quarter, value], ...)

    my $sun = Time::Keeper::Sun->new(place => 'Europe/London');
    my $day = Time::Keeper::Moon->on($date, place => $sun);  # a Time::Keeper::Moon::Day
    $day->moonrise;                                          # 2026-10-15T13:14:52+01:00
    $day->moonset;                                           # 2026-10-15T19:55:42+01:00
    Time::Keeper::Moon->position($t, place => $sun);         # altitude and azimuth from London

=head1 DESCRIPTION

Time::Keeper::Moon is part of L<Time::Keeper::Sky>, the dist Time::Keeper::Sun was
renamed to; the place a method takes with C<< place => >> is a Time::Keeper::Sky (or a
Time::Keeper::Sun, which is one), and C<< $sky->position('moon', $t) >> and its kin
reach these methods from there. Everything below works as it did in Time::Keeper::Sun
0.02.

The instants of new moon, first quarter, full moon and last quarter, to a few seconds;
at any instant the moon's place, its elongation from the sun, its phase angle, the
fraction of its disk that is lit, its age and the name of its phase; and from a place,
the moon's altitude and azimuth and the moments it rises, sets and crosses the meridian. The instants come from the
periodic terms of Meeus's chapter 49; the moon's place from the 120 terms of his
chapter 47; the fraction lit from the two places. See L</ACCURACY>.

Every value returned is a L<Time::Keeper> value in the zone given (UTC otherwise),
rounded to the whole second. Every method is a class method.

=head2 Where

The methods that return values or a day take C<zone> and C<locale>, UTC and English
otherwise, and C<place>: a L<Time::Keeper::Sun> place, whose zone and locale then
become the defaults, which C<zone> and C<locale> override, in whichever order they are
given. C<position> takes a place to add the moon's altitude and azimuth as seen from
it.

=head1 METHODS

=head2 phase_name

    Time::Keeper::Moon->phase_name($t);     # one of the eight below

The phase at an instant, by eighths of the elongation: C<new> within 22.5 degrees of
the sun, then C<waxing_crescent>, C<first_quarter>, C<waxing_gibbous>, C<full>,
C<waning_gibbous>, C<last_quarter>, C<waning_crescent>. A day's name is a different
question: see L<Time::Keeper::Moon::Day/phase_name>.

=head2 elongation

The difference between the moon's longitude and the sun's, degrees, 0 at new moon
rising to 360: under 180 the moon is waxing. The phases are its multiples of 90.

=head2 phase_angle

The angle at the moon between the sun and the earth, degrees: 0 when the moon is fully
lit, 180 when it is dark. It is near 180 less the elongation, and differs from it by
up to five degrees, since the moon is up to five degrees off the ecliptic.

=head2 illumination

The fraction of the disk that is lit, 0 to 1. It is never quite 0 at a new moon nor 1
at a full moon, for the same reason: in 2026 the least was 0.0019 and the most 0.9981.

=head2 age

Days since the last new moon, as a number.

=head2 position

    my $p = Time::Keeper::Moon->position($t);
    my $q = Time::Keeper::Moon->position($t, place => $sun);   # see Where
    $p->{longitude};  $p->{latitude};          # apparent ecliptic, degrees
    $p->{right_ascension};  $p->{declination}; # apparent, geocentric, degrees
    $p->{distance};                            # kilometres, centre to centre
    $p->{parallax};                            # the equatorial horizontal parallax, degrees
    $p->{bright_limb};                         # the lit side's direction, degrees (see THE MOON'S DISC)
    $p->{constellation};                       # the IAU abbreviation of where it is, 'Sgr'

The moon's place as seen from the earth's centre at an instant, as a hash reference of
numbers: about 10 arcseconds in longitude and 4 in latitude, from the 120 periodic
terms of Meeus's chapter 47.

With a place the hash also holds what is seen from there: C<altitude>, the moon's centre
above the horizon, with the parallax that lowers a near body by up to a degree;
C<apparent_altitude>, with refraction too; C<azimuth>, from the north through the east;
C<hour_angle>, degrees, -180 to 180; C<parallactic_angle>, degrees, -180 to 180 (see
L</THE MOON'S DISC>). Without a place there is no altitude or azimuth rather than the
one seen from the earth's centre.

=head2 track

    my $tr = Time::Keeper::Moon->track(from => $t0, to => $t1, step => 120);
    my $tr = Time::Keeper::Moon->track(from => $t0, to => $t1, step => 120, place => $sun);
    $tr->{epoch};  $tr->{illumination};  $tr->{distance};
    $tr->{sub_latitude};  $tr->{sub_longitude};
    $tr->{bright_limb};
    $tr->{altitude};  $tr->{apparent_altitude};  $tr->{azimuth};   # with a place
    $tr->{parallactic_angle};                                       # with a place

The moon at every C<step> seconds from C<from> to C<to>, as a hash of array
references, one entry per sample, each exactly what C<illumination>, C<position> and
C<sub_point> give at its instant. The arguments and their limits are those of
L<Time::Keeper::Sun/track>. Without a place there is no altitude, azimuth or
parallactic angle.

=head2 sub_point

    my ($lat, $lon) = Time::Keeper::Moon->sub_point($t);

Where on the earth the moon is overhead at an instant, from its geocentric place:
the latitude, which is its declination, and the longitude east, -180 to 180, which is
minus its Greenwich hour angle.

=head2 lunation

The lunation number in Brown's series, in which the new moon of 17 January 1923 is
lunation 1 (and that of 6 January 2000 is 953): the number of the lunation the
instant falls in.

=head2 next

=head2 previous

    Time::Keeper::Moon->next(phase => 'full');                     # after now
    Time::Keeper::Moon->next(phase => 'new', after => $t, zone => 'Asia/Tokyo');
    Time::Keeper::Moon->previous(phase => 'last_quarter', before => $t);

The first phase of the kind strictly after (or the last strictly before) an instant,
which is now when none is given. C<phase> is C<new>, C<first_quarter>, C<full> or
C<last_quarter>; C<zone>, C<locale> and C<place> shape the value returned (L</Where>).

=head2 phases

    my @p = Time::Keeper::Moon->phases(from => $a, to => $b, zone => 'UTC');
    # ([new, value], [first_quarter, value], [full, value], [last_quarter, value], ...)

Every principal phase from one instant to another, inclusive, in order, each a
reference to a two-element array of its name and its value; at most a year at a time.

=head2 on

    my $day = Time::Keeper::Moon->on($date, zone => 'Europe/London');
    my $day = Time::Keeper::Moon->on($t);                 # the value's date in the zone given
    my $day = Time::Keeper::Moon->on($date, place => $sun);   # in the place's zone

The moon on a civil day in a zone, as a L<Time::Keeper::Moon::Day>: the principal phase
that falls in the day if there is one, else the name of the phase between, with the
fraction and the age at local noon. The day is the zone's civil day, as
L<Time::Keeper::Sun/THE DAY> describes it; a value's date is taken in the zone given,
not its own.

=head2 next_moonrise

=head2 next_moonset

=head2 previous_moonrise

=head2 previous_moonset

=head2 next_moon_transit

=head2 previous_moon_transit

    Time::Keeper::Moon->next_moonrise($t, place => $sun);
    Time::Keeper::Moon->previous_moonset($t, place => $sun, zone => 'UTC');

The moon's rise, set or upper transit nearest an instant on the side asked for, seen
from a place, which is required. Undef if none is found within a year, which only the
poles bring about.

=head1 THE MOON'S DAY

C<on> with a place gives the moon's rises, sets and upper transits in the civil day,
as L<Time::Keeper::Sun/THE DAY> describes the day for the sun. The moon rises about
50 minutes later each day, so at most latitudes one day a month has no moonrise and
one no moonset; that is ordinary, and the singular methods give undef. North or south
of about 60 degrees the delay can turn negative, and a day can hold two moonrises or
two moonsets (Tromso, 11 June 2026: 00:24 and 23:39); the singular then gives the
first and the plural both, as for the sun. On days when the moon neither rises nor
sets, C<is_moon_up_all_day> or C<is_moon_down_all_day> says which.

A moonrise is the moment the moon's upper limb touches the horizon seen from the place:
its centre, lowered by the parallax as seen from there, plus its semidiameter, at
34 arcminutes below the horizon for refraction, and more from a height as for the sun.
This is the convention of the Naval Observatory and of Meeus's 0.7275 times the
parallax less 34 arcminutes.

=head1 THE MOON'S DISC

To draw the moon as it looks, three numbers from C<position> are enough. The phase
angle (C<phase_angle>) says how much is lit. C<bright_limb> is the position angle of
the middle of the lit edge (Meeus 48.5): the direction of the sun from the moon,
measured on the sky from the north point of the disc through the east, 0 to 360; a
waxing moon, the sun to its west, is lit at about 270, a waning one at about 90. It
needs no place.

That angle is counted from the north celestial pole, which an observer does not see.
C<parallactic_angle> (Meeus 14.1), with a place, is the angle at the moon from the
direction of the pole to that of the zenith: 0 when the moon is on the meridian,
positive west of it in the northern sky, and near 180 on the meridian where the moon
passes north of the zenith, as it does south of the tropics. The lit edge as seen
from the place, measured from straight up and turning the way north turns to east,
is C<bright_limb - parallactic_angle>.

=head1 ACCURACY

The phase instants are those of chapter 49, which the book states to be within a few
seconds of the ephemeris from 1980 to 2020; from 1900 to 2100 they agree with the
U.S. Naval Observatory's published times to the minute. Outside that span Delta T's
uncertainty enters one for one (see L<Time::Keeper::Sun/DELTA T>).

The moon's place is good to about 10 arcseconds in longitude and 4 in latitude; against
the Naval Observatory's ephemeris from 1800 to 2050 its declination came within 0.0014
degrees, its altitude from a place within 0.003 and its azimuth within 0.005. The
fraction lit is computed from the moon's and the sun's places (Meeus 48.2 and 48.3);
it came within 0.005 of the Naval Observatory's, which it rounds to a whole percent.

Moonrise, moonset and the upper transit came within 32 seconds of the Naval
Observatory's minute on 374 events at twenty places from the equator to 78 degrees,
every day's count the same, its days of a moon up or down throughout matched. Against
the Jet Propulsion Laboratory's ephemeris DE421 (through Skyfield, 1900 to 2049) they
came within 1 second below 60 degrees of latitude and 3 seconds above, on 387 events;
the phases within 21 seconds. The moon's place against DE421: declination within 0.0024
degrees, right ascension within 25 arcseconds on the sky, distance within 41 km.

=head1 SEE ALSO

L<Time::Keeper::Sun>, L<Time::Keeper>, L<Astro::MoonPhase>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
