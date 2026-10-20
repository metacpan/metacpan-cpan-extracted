package Time::Keeper::Star;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

use Time::Keeper::Sky;

1;

__END__

=encoding utf8

=head1 NAME

Time::Keeper::Star - the stars of the Yale Bright Star Catalogue: where they are, from anywhere

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Time::Keeper::Star;

    my $s = Time::Keeper::Star->find('Betelgeuse');     # or 'alpha Ori', '58 Ori', 'HR 2061', 2061
    $s->{hr};  $s->{bayer};  $s->{constellation};  $s->{magnitude};  $s->{colour};

    my $sky = Time::Keeper::Sky->new(place => 'Europe/London');
    my $p = Time::Keeper::Star->position('Sirius', $t, place => $sky);
    $p->{right_ascension};  $p->{declination};  $p->{altitude};  $p->{azimuth};

    my $map = Time::Keeper::Star->positions($t, magnitude => 4.5, place => $sky);
    # { hr => [...], right_ascension => [...], declination => [...], magnitude => [...],
    #   altitude => [...], azimuth => [...] }, brightest first

    my @hr = Time::Keeper::Star->brighter_than(2);
    my $tr = Time::Keeper::Star->track('Vega', from => $t0, to => $t1, step => 600, place => $sky);

    my $d = Time::Keeper::Star->on($date, 'Sirius', place => $sky);    # a Time::Keeper::Star::Day
    $d->rise;  $d->transit;  $d->set;
    Time::Keeper::Star->next_rise('Sirius', $t, place => $sky);

=head1 DESCRIPTION

The 9,096 stars of the Yale Bright Star Catalogue (Hoffleit and Warren, 5th revised
edition, 1991), every star to about magnitude 6.5, which is every star the eye can
see; the 14 entries without a position (novae and other objects since removed) are
left out. The 332 of them the International Astronomical Union has named (the IAU
Catalog of Star Names, by its Working Group on Star Names) carry their names. Both are
compiled into the dist.

A star's apparent place is found by the rigorous model the Astronomical Almanac and
NOVAS use: its position and space velocity from the catalogue's place, proper motion,
parallax and radial velocity; moved to the moment its light reaches the earth; seen
from the earth (the annual parallax, which moves Alpha Centauri by up to three
quarters of an arcsecond); the sun's deflection of the light and the annual
aberration; then precession and nutation to the true equator and equinox of the date.

=head1 METHODS

=head2 find

    my $s = Time::Keeper::Star->find($what);
    my $s = Time::Keeper::Star->find(hr => 2061);
    my $s = Time::Keeper::Star->find(name => 'Betelgeuse');

What the catalogue says of a star, as a hash reference, or undef if there is no such
star: C<hr>, C<name> (the IAU's, or undef), C<bayer> ("Alp Ori", or undef),
C<flamsteed> ("58 Ori", or undef), C<constellation> (the IAU abbreviation),
C<magnitude> (V), C<colour> (B-V, or undef), C<right_ascension> and C<declination>
(J2000, degrees), C<proper_motion_ra> (times cos(dec)) and C<proper_motion_dec>
(arcseconds a year), C<parallax> (arcseconds, 0 where unknown) and
C<radial_velocity> (km/s).

A star is found by its IAU name, "HR" and its number, its Bayer designation with
the Greek letter spelled out, abbreviated as the catalogue has it or as the IAU has
it ("alpha Ori", "Alp Ori", "alf Ori"; with a superscript, "alpha1 Cen"), its
Flamsteed number ("58 Ori"), or its HR number alone. Case does not matter.

=head2 position

    my $p = Time::Keeper::Star->position($star, $t);
    my $p = Time::Keeper::Star->position($star, $t, place => $sky);

A star's apparent C<right_ascension> and C<declination> at an instant, with its
C<magnitude> and C<hr>; with a place also its C<altitude>, C<apparent_altitude>,
C<azimuth> and C<hour_angle> as seen from there. C<$star> is anything C<find> takes;
an unknown star dies naming it.

=head2 positions

    my $map = Time::Keeper::Star->positions($t, magnitude => 4.5, place => $sky);

Every star at or brighter than a magnitude (4.5 unless given) at one instant, as a
hash of arrays, brightest first: C<hr>, C<right_ascension>, C<declination>,
C<magnitude>, and with a place C<altitude> and C<azimuth>. The precession, the
earth's place and the nutation are worked out once for all of them: the 904 stars to
4.5 take about 0.15 milliseconds.

=head2 brighter_than

    my @hr = Time::Keeper::Star->brighter_than(2.0);

The HR numbers of the stars at or brighter than a magnitude, brightest first.

=head2 track

=head2 sub_point

    my $tr = Time::Keeper::Star->track($star, from => $t0, to => $t1, step => 600, place => $sky);
    my ($lat, $lon) = Time::Keeper::Star->sub_point($star, $t);

As for the sun and the planets: the star at every step, as arrays (C<epoch>,
C<sub_latitude>, C<sub_longitude>, and with a place C<altitude>,
C<apparent_altitude> and C<azimuth>), and where on the earth it is overhead.

=head2 on

    my $d = Time::Keeper::Star->on($date, $star, place => $sky);

The star's rises, sets and upper transits in one civil day at a place, as a
L<Time::Keeper::Star::Day>. C<$date> is a L<Time::Keeper::Date> or a L<Time::Keeper>
value (its date in the place's zone); C<place> is required, and C<zone> and C<locale>
may change the values' zone and locale. A star rises and sets when its centre is 34
arcminutes below the horizon (refraction's; a star is a point), with the dip of the
horizon from a height, as for the planets. A star keeps sidereal time, so its events
come 3 minutes 56 seconds earlier each day, and a civil day can hold two transits.

=head2 next_rise

=head2 next_set

=head2 previous_rise

=head2 previous_set

=head2 next_transit

=head2 previous_transit

    Time::Keeper::Star->next_rise($star, $t, place => $sky);

The star's next or previous rise, set or upper transit from an instant, seen from a
place (required). A rise or set is undef where the star never crosses the horizon: a
circumpolar star, or one that never rises there. The rigorous model's place is
computed at each moment of the search.

=head1 ACCURACY

Against Skyfield's Star made from the same catalogue numbers at the same Terrestrial
Time, so that the arithmetic is compared and not the catalogue: within 0.18
arcseconds from 1950 to 2050, and 0.35 from 1900. The difference is the models': this
dist precesses by Meeus's chapter 21 (IAU 1976), about 0.3 arcseconds a century
from IAU 2006, and nutates by chapter 22's short series, a quarter of an arcsecond from
IAU 2000A. The catalogue itself gives positions to a tenth of a second of right
ascension and an arcsecond of declination, and that, not the arithmetic, is what a
star's place is good to.

Rises, sets and transits, against Skyfield's almanac for 25 stars at 12 places on 4
days of 2026 (2,153 events): every count the same, within 2.1 s below 60 degrees of
latitude and 0.8 s above.

=head1 SEE ALSO

L<Time::Keeper::Star::Day>, L<Time::Keeper::Sky>, L<Time::Keeper::Planet>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The star data are from the Yale Bright Star Catalogue (CDS catalogue V/50, public
domain) and the IAU Catalog of Star Names (IAU WGSN; Creative Commons Attribution).

=cut
