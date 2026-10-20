package Time::Keeper::Sky;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

use XSLoader;
XSLoader::load('Time::Keeper::Sky', $VERSION);

require Time::Keeper::Sun;

1;

__END__

=encoding utf8

=head1 NAME

Time::Keeper::Sky - the sky from a place: the sun and the moon, where they are and when they rise, in a time zone

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Time::Keeper::Sky;

    my $sky = Time::Keeper::Sky->new(place => 'Europe/London');
    my $sky = Time::Keeper::Sky->new(latitude => 51.5074, longitude => -0.1278, zone => 'Europe/London');

    my $day = $sky->on(year => 2026, month => 10, day => 15);
    print $day->sunrise, "\n";                     # 2026-10-15T07:24:22+01:00

    my $p = $sky->position(Time::Keeper->now);     # the sun's altitude, azimuth, ...
    my $tr = $sky->track(from => $t0, to => $t1, step => 120);

    use Time::Keeper::Moon;
    Time::Keeper::Moon->position($t, place => $sky);
    Time::Keeper::Moon->on($date, place => $sky)->moonrise;

    # any body by name: the sun, the moon, a planet or a star
    $sky->position('jupiter', $t);
    $sky->track('Vega', from => $t0, to => $t1, step => 60);
    $sky->on($date, 'Sirius')->rise;

    # what is up tonight, and when each is best
    for my $r ($sky->tonight) {
        printf "%-10s %s  %2.0f degrees up, azimuth %3.0f\n", $r->{body}, $r->{best}, $r->{altitude}, $r->{azimuth};
    }

=head1 DESCRIPTION

A Time::Keeper::Sky is an observer: a place on the earth, with the time zone its days
are counted in and the locale its values print in. Everything the dist computes is
seen from one.

This dist was Time::Keeper::Sun, and still contains it: L<Time::Keeper::Sun> is a
Time::Keeper::Sky, and every program written for Time::Keeper::Sun 0.01 or 0.02 runs
unchanged, its objects still Time::Keeper::Suns. Anything that takes a place (C<<
place => >> on the moon's methods) takes either. New code should start here.

The methods below are the sun's, as Time::Keeper::Sun documented them; they are
described in full in L<Time::Keeper::Sun>, with what a day is, the horizon, the range
and the accuracy. The rest of the sky has a module each:

=over 4

=item L<Time::Keeper::Moon>

The phases, the moon's place, its disc as seen, and its rises, sets and transits
(L<Time::Keeper::Moon::Day>).

=item L<Time::Keeper::Planet>

Mercury to Neptune by the full VSOP87D, and Pluto: their places, magnitudes and
phases, their days (L<Time::Keeper::Planet::Day>), their conjunctions, oppositions,
elongations and stations.

=item L<Time::Keeper::Star>

The 9,096 stars of the Yale Bright Star Catalogue with the IAU's names: their places
and their days (L<Time::Keeper::Star::Day>).

=item L<Time::Keeper::Eclipse>

Lunar and solar eclipses, their types, magnitudes and contacts, the central line of a
solar one, and what one place sees (L<Time::Keeper::Eclipse::Local>).

=back

Any of these bodies can be named to the Sky's own C<position>, C<track> and C<on>
(L</BODIES>), and L</tonight> says what is up after dark.

=head1 CONSTRUCTOR

=head2 new

    my $sky = Time::Keeper::Sky->new(latitude => ..., longitude => ..., zone => ..., locale => ..., elevation => ...);
    my $sky = Time::Keeper::Sky->new(place => 'Asia/Tokyo');

The observer. The arguments are those of L<Time::Keeper::Sun/new>; the object is of
the class C<new> was called on.

=head1 THE PLACE

=head2 latitude

=head2 longitude

=head2 elevation

=head2 zone_name

=head2 locale

What the observer was made with.

=head1 THE SUN FROM THE PLACE

=head2 position

    $sky->position($t);                  # the sun
    $sky->position($t, precise => 1);
    $sky->position($body, $t, ...);      # any body

The sun's place seen from here at an instant. See L<Time::Keeper::Sun/position>. With
a body first (L</BODIES>), that body's: the moon's from
L<Time::Keeper::Moon/position>, a planet's from L<Time::Keeper::Planet/position>, a
star's from L<Time::Keeper::Star/position>, each with C<< place => >> this Sky, and
any further pairs passed on.

=head2 track

    $sky->track(from => $t0, to => $t1, step => 120);           # the sun
    $sky->track($body, from => $t0, to => $t1, step => 120);    # any body

The sun at every step from one instant to another, as arrays. See
L<Time::Keeper::Sun/track>. With a body first, that body's track from its own class,
seen from here.

=head2 sub_point

Where on the earth the sun is overhead. See L<Time::Keeper::Sun/sub_point>.

=head2 on

    $sky->on($date);                     # the sun's day
    $sky->on($date, $body);              # any body's
    $sky->on($body);                     # today's

The sun's events on one civil day here, as a L<Time::Keeper::Sun::Day>. With a body
after the date (a L<Time::Keeper::Date> or a L<Time::Keeper> value), that body's day:
a L<Time::Keeper::Moon::Day>, a L<Time::Keeper::Planet::Day> or a
L<Time::Keeper::Star::Day>. A body alone is today's in the place's zone.

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

The next or previous event from an instant. See L<Time::Keeper::Sun/next_sunrise>.

=head1 BODIES

A body is named as a person would: C<sun>, C<moon>, a planet (C<mercury>, C<venus>,
C<mars>, C<jupiter>, C<saturn>, C<uranus>, C<neptune>, C<pluto>; case not minded;
not the earth), or a star of the Bright Star Catalogue by anything
L<Time::Keeper::Star/find> takes: an IAU name (C<Sirius>), a Bayer or Flamsteed
designation (C<alpha CMa>, C<9 CMa>), C<HR 2491>, or the HR number alone. A name that
is none of these dies saying so.

=head1 TONIGHT

=head2 night

    my $n = $sky->night;                     # the night now in, or the coming one
    my $n = $sky->night(date => $date);      # a Time::Keeper::Date or value
    # { kind => 'night', start => value, end => value, date => Time::Keeper::Date }

The night of a date here, as a hashref. The night is the dark span of the 24 hours
from the date's noon to the next day's noon (noon being the middle of the civil day in
the place's zone): from civil dusk, the sun's centre 6 degrees below the horizon, to
the next civil dawn. C<kind> is one of:

=over 4

=item night

A dusk and a dawn; C<start> and C<end> are they.

=item polar_night

The sun below -6 degrees all the 24 hours; C<start> and C<end> are the two noons.

=item white_night

The sun sets but never goes 6 degrees down; C<start> and C<end> are undef.

=item polar_day

The sun never sets; C<start> and C<end> are undef.

=back

Without C<< date => >> the date is today in the place's zone, or yesterday before
today's noon: at two in the morning the night is the one you are in.

=head2 tonight

    my @up = $sky->tonight;
    my @up = $sky->tonight(date => $date, minimum_altitude => 15, magnitude => 2);

What is up in the L</night>: the moon, the planets from Mercury to Neptune, and the
stars of the catalogue at or brighter than C<magnitude> (default 1.5, about twenty
stars), each listed if it is at or above C<minimum_altitude> (default 10 degrees) for
half an hour of the night in all. A list of hashrefs in order of when each is best:

=over 4

=item body

The body's name: C<moon>, a planet's, a star's IAU name or C<HR n>.

=item kind

C<moon>, C<planet> or C<star>.

=item best

When it is highest in the night, as a L<Time::Keeper> value in the place's zone: its
transit, or the night's start or end for one setting or rising through it.

=item altitude

=item apparent_altitude

=item azimuth

Where it is then: the altitude, geometric and refracted, and the azimuth, degrees, as
the body's own C<position> has them (topocentric for the moon and the planets).

=item from

=item until

The first and last moments it is at or above the minimum altitude, within the night,
to the second.

=item magnitude

A planet's, by Mallama and Hilton (undef where their formulae give none); a star's
from the catalogue; undef for the moon.

=item illumination

The fraction lit: the moon's and a planet's.

=item constellation

The IAU abbreviation of the constellation it is in.

=item hr

A star's HR number.

=back

A white night or polar day gives an empty list; L</night> says which. The altitudes are
sampled every two minutes over the night, then the crossings of the minimum and the
greatest altitude are found to the second from the exact places (a star's from its
place at the night's middle, which moves under an arcsecond in a night). The best
moment is within a minute of the highest point of a one-minute track over 36 nights
at London, Sydney and Tromso (the worst 30 s, the track's step); see C<t/29-tonight.t>.

=head1 CLASS METHODS

=head2 place_of

=head2 places

=head2 places_release

The zones whose cities the dist knows. See L<Time::Keeper::Sun/PLACES>.

=head2 equinox

=head2 solstice

=head2 seasons

The seasons of a year. See L<Time::Keeper::Sun/equinox>.

=head2 closest_approach

    my @a = Time::Keeper::Sky->closest_approach('venus', 'jupiter', from => $t0, to => $t1);
    my @a = Time::Keeper::Sky->closest_approach('moon', 'mars', from => $t0, to => $t1, place => $sky);
    for (@a) { my ($when, $degrees) = @$_ }

Every moment from C<from> to C<to> (at most ten years apart) when two bodies are
closest on the sky, each with its separation in degrees: every local minimum, near or
far, in order. The bodies are C<sun>, C<moon> and the planets. With a place the moon
is seen from there, which moves it by up to a degree; the sun and the planets are
geocentric, which their parallax leaves within half a minute of arc.

=head2 constellation_of

    my $abbr = Time::Keeper::Sky->constellation_of($ra, $dec);        # J2000.0
    my $abbr = Time::Keeper::Sky->constellation_of($ra, $dec, $t);    # of the date of $t

The IAU abbreviation of the constellation a direction lies in, right ascension and
declination in degrees, referred to J2000.0 or, with an instant, to the equator and
equinox of its date (a position of date, as the moon's and the planets' are). The
boundaries are those the IAU fixed in 1930 (Delporte), which run along right ascension
and declination in the frame of B1875.0; the direction is precessed there and found by
Roman's (1987) method. An apparent place differs from a mean one by under a minute of
arc, which tells only on a boundary.

The moon's and the planets' C<position> carry their constellation already.

=head2 constellation

    my $c = Time::Keeper::Sky->constellation('Ori');           # or 'Orion', 'orion'
    $c->{abbreviation};  $c->{name};  $c->{genitive};          # Ori, Orion, Orionis

A constellation by its abbreviation or name, case not minded, as a hash reference;
undef if there is none. The genitive is what a star's designation takes: alpha
Orionis.

=head2 constellations

    my @abbr = Time::Keeper::Sky->constellations;

The 88 abbreviations, in alphabetical order of the constellations' names.

=head2 delta_t

TT minus UT at an instant, in seconds. See L<Time::Keeper::Sun/DELTA T>.

=head1 ACCURACY

Each module says how close it comes, measured against sources independent of it; in
brief, the worst seen:

=over 4

=item The sun

Against the U.S. Naval Observatory's tables, rises and sets within a minute below 60
degrees of latitude; its place within 0.01 degree by Meeus's chapter 25, and within
0.52 arcseconds of JPL's DE421 with C<< precise => 1 >>. See L<Time::Keeper::Sun/ACCURACY>.

=item The moon

Its place within about 10 arcseconds (Meeus 47); its phases within the minute of
USNO's; its rises and sets within 32 seconds of USNO's minute, and within a second of
DE421's below 60 degrees. See L<Time::Keeper::Moon/ACCURACY>.

=item The planets

VSOP87D within 7e-11 of IMCCE's check values; on the sky within 0.66 arcseconds of
DE421 for Mercury to Saturn, 1.7 for Uranus and Pluto, 2.5 for Neptune; rises and
sets within a second of Skyfield's. See L<Time::Keeper::Planet/ACCURACY>.

=item The stars

Within 0.35 arcseconds of Skyfield's Star from the same catalogue numbers; rises and
sets within 2.1 seconds. See L<Time::Keeper::Star/ACCURACY>.

=item The constellations

All 88 as the IAU names them; every one of the catalogue's 3,143 Bayer and Flamsteed
constellations the same; the moon's, against Skyfield's, the same every hour of a year
but the one where it was on a boundary.

=item Eclipses

Every lunar eclipse of 1901 to 2100 as the Five Millennium Canon has it, and 451 of
its 452 solar ones; greatest eclipse within 18 seconds; a place's contacts within 14
seconds of USNO's. See L<Time::Keeper::Eclipse/ACCURACY>.

=item Tonight

Each body's best moment within 30 seconds of the highest point of a one-minute track.

=back

Two choices set most of these limits, and the dist says so where they tell: the moon
is Meeus's chapter 47 (about 10 arcseconds), and precession and nutation are the IAU
1976 and short series of Meeus's chapters 21 and 22 (a few tenths of an arcsecond).

=head1 SOURCES

Every table the dist compiles in, where it came from and on what terms:

=over 4

=item VSOP87D

Bretagnon and Francou (1988), I<Astronomy and Astrophysics> 202, 309: the eight
VSOP87D files of the CDS catalogue VI/81 (IMCCE), every term with the files' digits.
CDS distributes them freely; no licence is stated in them.

=item The Yale Bright Star Catalogue

Hoffleit and Warren, 5th revised edition (1991), CDS V/50: public domain.

=item The IAU Catalog of Star Names

The IAU Working Group on Star Names (WGSN), IAU-CSN: CC BY, by the International
Astronomical Union.

=item The constellations

The boundaries of 1930 (Delporte) in Roman's form, Roman (1987), I<Publications of the
Astronomical Society of the Pacific> 99, 695, CDS VI/42; the names and genitives from
the IAU Style Manual (1989), Table 11.

=item Meeus's tables

Chapters 47 (the moon), 37 (Pluto), 49 (the phases) and 27 (the seasons) of Jean
Meeus's I<Astronomical Algorithms> (2nd ed., 1998), as the Go port
github.com/soniakeys/meeus encodes them: Copyright 2018 Sonia Keys, MIT licence
(permission is granted to use, copy, modify, merge, publish and distribute, provided
the copyright and permission notice is included; the software is provided as is,
without warranty of any kind).

=item The places

The zones of the IANA time zone database (tzdata 2026e, zone1970.tab and backward):
public domain.

=back

The tests carry what they compare against: the Five Millennium Canons of Lunar and
Solar Eclipses (Espenak and Meeus, NASA; public domain), the U.S. Naval Observatory's
Astronomical Applications API (a U.S. government work), IMCCE's VSOP87 check file, and
figures from Skyfield (Rhodes, MIT) with JPL's DE421.

=head1 SEE ALSO

L<Time::Keeper::Sun>, L<Time::Keeper::Sun::Day>, L<Time::Keeper::Moon>,
L<Time::Keeper::Moon::Day>, L<Time::Keeper::Planet>, L<Time::Keeper::Star>,
L<Time::Keeper::Eclipse>, L<Time::Keeper>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
