package Time::Keeper::Eclipse;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

use Time::Keeper::Sky;
use Time::Keeper::Eclipse::Local;

1;

__END__

=encoding utf8

=head1 NAME

Time::Keeper::Eclipse - eclipses of the moon and the sun: when, how deep, and from where

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Time::Keeper::Eclipse;

    my $e = Time::Keeper::Eclipse->next(kind => 'lunar', after => $t);
    $e->type;                      # penumbral | partial | total
    $e->greatest;                  # a Time::Keeper value
    $e->umbral_magnitude;  $e->penumbral_magnitude;  $e->gamma;
    for ($e->contacts) { my ($name, $when) = @$_ }      # p1 u1 u2 u3 u4 p4, those it has

    my $sky = Time::Keeper::Sky->new(place => 'Asia/Tokyo');
    for ($e->visible(place => $sky)) { my ($name, $when, $altitude) = @$_ }

    my @all = Time::Keeper::Eclipse->between(kind => 'lunar', from => $t0, to => $t1);

    my $s = Time::Keeper::Eclipse->next(kind => 'solar', after => $t);
    $s->type;                      # partial | annular | total | hybrid
    $s->magnitude;  $s->gamma;  $s->greatest_place;  $s->path_width;  $s->duration;
    my $l = $s->local(place => $sky);                  # a Time::Keeper::Eclipse::Local, or undef
    $l->type;  $l->magnitude;  $l->obscuration;  $l->contacts;  $l->duration;
    my $line = $s->central_line(step => 60);           # epoch, latitude, longitude, width, duration
    Time::Keeper::Eclipse->next(kind => 'solar', after => $t, place => $sky);   # the next seen from there

=head1 DESCRIPTION

Eclipses of the moon, as the Five Millennium Canon of Lunar Eclipses (Espenak and
Meeus) computes them: at each full moon the moon's place (Meeus 47) and the sun's
(VSOP87) give the moon's distance from the axis of the earth's shadow, and the
shadows are Danjon's, the earth's radius enlarged by 1/85 for its opaque air, as the
Canon and the Connaissance des Temps take them. (The Astronomical Almanac uses
Chauvenet's 1/50, whose umbral magnitudes are about 0.006 larger.)

A lunar eclipse is the same for everyone who can see the moon; where it is seen from
decides only which of its stages happen with the moon above the horizon
(L</visible>).

Eclipses of the sun are found from the moon's shadow: the sun (VSOP87) and the moon
(Meeus 47) as vectors in the earth's radii give, at each instant, the axis of the
shadow and its cones, the Besselian quantities computed directly. Greatest eclipse
is the axis nearest the earth's centre; where the axis meets the earth (the WGS84
ellipsoid) is the central line, and the umbra's size there says total or annular
(hybrid if it changes along the path). Seen from a place, the sun's and the moon's
discs give the contacts, the magnitude and the area covered. The moon's radius is the
Canon's: k = 0.2724880 for the outer contacts, 0.2722810 for the inner, which allow for
the valleys on its limb.

=head1 CLASS METHODS

=head2 next

=head2 previous

    my $e = Time::Keeper::Eclipse->next(kind => 'lunar', after => $t);
    my $e = Time::Keeper::Eclipse->previous(kind => 'lunar', before => $t);
    my $e = Time::Keeper::Eclipse->next(kind => 'lunar');                       # after now

The next or previous eclipse whose greatest is after (before) an instant, as a
Time::Keeper::Eclipse, or undef if none falls within sixty years. Its values are in
UTC, or in the zone of C<place>, C<zone> or C<locale> as on the moon's methods.

=head2 between

    my @e = Time::Keeper::Eclipse->between(kind => 'lunar', from => $t0, to => $t1);

Every eclipse with its greatest from one instant to another, at most a century apart,
in order.

C<kind> is C<lunar> or C<solar>. For a solar eclipse C<place> on C<next> and
C<previous> also asks for the next one seen from there: some of it with the sun up.

=head1 METHODS

=head2 kind

C<lunar> or C<solar>.

=head2 type

For the moon: C<penumbral> (the moon only in the earth's penumbra, a dimming hard
to see), C<partial> (part of the moon in the umbra) or C<total> (all of it). For the
sun: C<partial> (the shadow's axis misses the earth), C<annular> (the moon too small
to cover the sun: a ring), C<total>, or C<hybrid> (annular at the path's ends, total
in its middle, or the other way).

=head2 greatest

The instant the moon's centre is nearest the axis of the earth's shadow.

=head2 umbral_magnitude

=head2 penumbral_magnitude

The fraction of the moon's diameter inside the umbra, or the penumbra, at greatest:
over 1 for a total eclipse, and negative when the moon misses that shadow.

=head2 gamma

For the moon, the least distance of its centre from the earth's shadow's axis, in the
earth's equatorial radii, positive when it passes north of it. For the sun, the least
distance of the moon's shadow's axis from the earth's centre, likewise: under about 1
the eclipse is central.

=head2 magnitude

A solar eclipse's: for a central one the moon's apparent diameter over the sun's at
greatest (over 1 total, under annular); otherwise the fraction of the sun's diameter
covered where greatest eclipse is seen, on the earth's limb.

=head2 greatest_place

    my ($lat, $lon) = $s->greatest_place;

Where greatest eclipse is seen: the central point, or for an eclipse that is not
central the point on the earth's limb nearest the shadow's axis, with the sun on the
horizon.

=head2 sun_altitude

The sun's altitude at the greatest place at greatest eclipse (0 when not central).

=head2 path_width

The width of the path of totality or annularity at the greatest place, km (0 when not
central).

=head2 duration

The duration of totality or annularity on the central line at greatest, as a
L<Time::Keeper::Duration>, or undef.

=head2 local

    my $l = $s->local(place => $sky);

The eclipse seen from a place, as a L<Time::Keeper::Eclipse::Local>, or undef where
the moon covers none of the sun. It is computed whether or not the sun is up there:
C<is_seen> says.

=head2 central_line

    my $line = $s->central_line;                         # every minute
    my $line = $s->central_line(step => 300, duration => 0);

The central line from end to end at every whole step (seconds) of UTC, as arrays:
C<epoch>, C<latitude>, C<longitude>, C<width> (km), and C<duration> (seconds of
totality or annularity there; computing it is most of the cost, and C<< duration => 0
>> leaves it out). Undef for an eclipse that is not central.

=head2 contacts

A lunar eclipse's contacts, in order, as C<[name, value]> pairs: C<p1> and C<p4>,
the moon's first and last touch of the penumbra; C<u1> and C<u4>, of the umbra;
C<u2> and C<u3>, the beginning and end of totality. A penumbral eclipse has two, a
partial one four, a total one six.

=head2 contact

    my $u2 = $e->contact('u2');     # undef in an eclipse without totality

One contact by name.

=head2 visible

A lunar eclipse's contacts from a place:

    my @seen = $e->visible(place => $sky);              # the contacts with the moon up
    my @all  = $e->visible(place => $sky, all => 1);    # every contact

The contacts as seen from a place, as C<[name, value, altitude]>, the value in the
place's zone and the altitude the moon's centre's, seen from there with refraction,
in degrees. Without C<all>, only those with the moon above the horizon.

=head1 ACCURACY

Against the Five Millennium Canon for every lunar eclipse of 1901 to 2100 (457): none
missed or invented, every type the same; the time of greatest eclipse within 15
seconds (in Terrestrial Time, so Delta T apart), the magnitudes within 0.0021, gamma
within 0.0011, and the duration of every phase deeper than 0.05 within 38 seconds.
The moon's place (Meeus 47, about 10 arcseconds) is the limit, and it tells most on a
grazing phase, whose length goes as the square root of its depth: the shallowest
penumbral eclipses (a magnitude of a few thousandths) can differ by a minute or two.

The solar eclipses against the Canon for 1901 to 2100: 451 of its 452, the one missed
being 1935 January 5, a partial eclipse of magnitude 0.0013, under the moon's 10
arcseconds; every type the same; greatest eclipse within 18 seconds (TT), gamma within
0.0010, a central eclipse's magnitude within 0.0001 and its duration within a second,
the path's width within 2.4%, the others' magnitude within 0.0023. Against the U.S.
Naval Observatory's local circumstances at 39 places from 1999 to 2026: the first and
last contacts within 14 seconds (10 at all but one eclipse, whose contacts are all
late together: the moon's place), the inner ones within 19 (USNO takes the IAU's lunar
radius, 0.2725076, which lengthens a totality), the magnitude and the obscuration
within 0.002. The central line is within 8 km of the Canon's with the sun high and 47
km at its ends, where the shadow crosses the ground fastest: the moon's place again,
as the full ELP-2000/82 theory the Canon used would not be.

=head1 SEE ALSO

L<Time::Keeper::Eclipse::Local>, L<Time::Keeper::Sky>, L<Time::Keeper::Moon>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
