#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Sky;
use Time::Keeper::Planet;

# The planets' apparent places: Meeus's examples 33.a and 37.a, the ecliptic
# precession against the equatorial route of chapter 21, what a position
# holds, the track and the sub-point, the range and the arguments.

sub near { my ($got, $want, $tol, $name) = @_; cmp_ok(abs($got - $want), '<=', $tol, "$name: $got within $tol of $want") }
sub angle_diff { my $d = abs($_[0] - $_[1]); $d -= 360 * int($d / 360); $d > 180 ? 360 - $d : $d }
my $R = atan2(1, 1) / 45;
sub utc { Time::Keeper->new(@_, zone => 'UTC') }

# ---- Meeus ------------------------------------------------------------------------

{
    # 37.a, 1992 October 13 at 0h TD, as the Go port of Meeus prints it.
    my ($l, $b, $r) = Time::Keeper::Sun::_pluto_j2000(2448908.5);
    near($l, 232.74071, 0.000005, 'example 37.a: Pluto\'s J2000 longitude');
    near($b, 14.58782, 0.000005, '  latitude');
    near($r, 29.711111, 0.0000005, '  radius');

    # 33.a, Venus on 1992 December 20 at 0h TD: the book sums its truncated
    # series (32.a), which moves Venus by about half an arcsecond.
    my ($ra, $dec, $delta, $tau) = Time::Keeper::Sun::_planet_jde(1, 2448976.5);
    near(angle_diff($ra, 316.172729), 0, 1 / 3600, 'example 33.a: Venus\'s apparent right ascension, 21h04m41.454s');
    near($dec, -18.888011, 1 / 3600, '  declination, -18 53 16.84');
    near($delta, 0.910947, 0.000002, '  distance, 0.910947 AU');
    near($tau * 1440, 7.57, 0.01, '  light-time, 7.57 minutes');
}

# ---- precession: the ecliptic route (21.5-21.7) against the equatorial (21.2-21.4) ---

{
    my $e0 = 23.4392911;
    my $worst = 0;
    for my $T (-1, -0.5, 0.26, 0.5, 1) {
        for my $pt ([10, 0], [100, 20], [200, -40], [300, 60], [45, -5]) {
            my ($l0, $b0) = @$pt;
            my ($l1, $b1) = Time::Keeper::Sun::_precess_ecliptic($T, $l0, $b0);
            # J2000 ecliptic to J2000 equatorial
            my ($lr, $br, $er) = ($l0 * $R, $b0 * $R, $e0 * $R);
            my $a0 = atan2(sin($lr) * cos($er) - tan($br) * sin($er), cos($lr));
            my $d0 = asin(sin($br) * cos($er) + cos($br) * sin($er) * sin($lr));
            # precess by zeta, z, theta from J2000
            my $zeta  = (2306.2181 * $T + 0.30188 * $T ** 2 + 0.017998 * $T ** 3) / 3600 * $R;
            my $z     = (2306.2181 * $T + 1.09468 * $T ** 2 + 0.018203 * $T ** 3) / 3600 * $R;
            my $theta = (2004.3109 * $T - 0.42665 * $T ** 2 - 0.041833 * $T ** 3) / 3600 * $R;
            my $A = cos($d0) * sin($a0 + $zeta);
            my $B = cos($theta) * cos($d0) * cos($a0 + $zeta) - sin($theta) * sin($d0);
            my $C = sin($theta) * cos($d0) * cos($a0 + $zeta) + cos($theta) * sin($d0);
            my $a = atan2($A, $B) + $z;
            my $d = asin($C);
            # to the ecliptic of date, by the mean obliquity of the date (22.2)
            my $eps = (23 + 26 / 60 + 21.448 / 3600 + (-46.8150 * $T - 0.00059 * $T ** 2 + 0.001813 * $T ** 3) / 3600) * $R;
            my $l2 = atan2(sin($a) * cos($eps) + tan($d) * sin($eps), cos($a)) / $R;
            my $b2 = asin(sin($d) * cos($eps) - cos($d) * sin($eps) * sin($a)) / $R;
            my $sep = sqrt((angle_diff($l1, $l2) * cos($b1 * $R)) ** 2 + ($b1 - $b2) ** 2) * 3600;
            $worst = $sep if $sep > $worst;
        }
    }
    cmp_ok($worst, '<=', 0.01, "the ecliptic precession is the equatorial route's, a century either way (worst $worst arcseconds)");
    my ($l, $b) = Time::Keeper::Sun::_precess_ecliptic(0, 123.4, -5.6);
    ok(abs($l - 123.4) < 1e-12 && abs($b + 5.6) < 1e-12, 'and nothing at J2000.0');
}
sub asin { atan2($_[0], sqrt(1 - $_[0] * $_[0])) }
sub tan { sin($_[0]) / cos($_[0]) }

# ---- a position --------------------------------------------------------------------

my $t = utc(year => 2026, month => 10, day => 19, hour => 21);
my $sky = Time::Keeper::Sky->new(place => 'Europe/London');
{
    my $p = Time::Keeper::Planet->position('jupiter', $t);
    is_deeply([sort keys %$p], [qw(constellation declination diameter distance elongation illumination latitude light_time longitude magnitude phase_angle right_ascension)],
              'a geocentric position\'s keys');
    my $q = Time::Keeper::Planet->position('jupiter', $t, place => $sky);
    is_deeply([sort keys %$q], [sort(keys(%$p), qw(altitude apparent_altitude azimuth hour_angle))], 'with a place, its altitude and azimuth too');
    is($q->{$_}, $p->{$_}, "  $_ the same") for qw(right_ascension declination distance magnitude);
    near($p->{light_time}, $p->{distance} * 499.004784, 0.001, 'the light-time is the distance over c, in seconds');
    near($p->{illumination}, (1 + cos($p->{phase_angle} * $R)) / 2, 1e-12, 'the illumination from the phase angle (41.1)');
    near($p->{diameter}, 2 * atan2(71492, $p->{distance} * 149597870.7) / $R * 3600, 1e-9, 'the diameter from the equatorial radius');
    cmp_ok($p->{magnitude}, '<', -1.5, "Jupiter is bright ($p->{magnitude})");
    ok(!defined Time::Keeper::Planet->position('pluto', $t)->{magnitude}, 'Pluto has no magnitude: Mallama and Hilton give none');
    my $v = Time::Keeper::Planet->position('venus', $t);
    cmp_ok($v->{elongation}, '<', 15, "Venus near inferior conjunction in October 2026 ($v->{elongation} degrees from the sun)");
    cmp_ok($v->{illumination}, '<', 0.05, '  a thin crescent');
    # the topocentric altitude differs from the geocentric by the parallax at most
    for my $name (qw(venus mars saturn)) {
        my $g = Time::Keeper::Planet->position($name, $t);
        my $w = Time::Keeper::Planet->position($name, $t, place => $sky);
        my (undef, $theta) = Time::Keeper::Sun::_sidereal($t);
        my $h = ($theta + $sky->longitude - $g->{right_ascension}) * $R;
        my $alt = asin(sin($sky->latitude * $R) * sin($g->{declination} * $R) + cos($sky->latitude * $R) * cos($g->{declination} * $R) * cos($h)) / $R;
        my $pi = 8.794148 / 3600 / $g->{distance};
        cmp_ok(abs($w->{altitude} - $alt), '<=', $pi * 1.01, "$name: the altitude from the place is the geocentric one less its parallax at most");
        # and the parallax is there: a near planet is lowered by about pi cos(h)
        near($alt - $w->{altitude}, $pi * cos($alt * $R), $pi * 0.15, "$name: lowered by its parallax times the cosine of the altitude")
            if $name eq 'venus';
    }
}

# ---- the magnitude formulae, against Skyfield's on the same numbers -------------------

{
    my %ix = (mercury => 0, venus => 1, mars => 3, jupiter => 4, saturn => 5, uranus => 6, neptune => 7);
    my $file = -e 't/mallama-magnitudes.tsv' ? 't/mallama-magnitudes.tsv' : 'mallama-magnitudes.tsv';
    open my $fh, '<', $file or die "$file: $!";
    my ($n, $worst, $nans) = (0, 0, 0);
    while (<$fh>) {
        next if /^#/;
        chomp;
        my ($p, $r, $d, $i, $a, $b, $want) = split /\t/;
        my ($sa, $sb, $year) = $p eq 'neptune' ? (0, 0, $a) : ($a, $b, 2000);
        my $got = Time::Keeper::Sun::_magnitude($ix{$p}, $r, $d, $i, $sa, $sb, $year);
        if ($want eq 'nan') {
            ok($got != $got, "$p at a phase angle of $i: no magnitude, as Skyfield");
            $nans++;
        }
        else {
            my $diff = abs($got - $want);
            $worst = $diff if $diff > $worst;
        }
        $n++;
    }
    is($n, 34, 'the 34 cases (both sides of every branch, the clamps, the limits)');
    cmp_ok($worst, '<=', 1e-12, "every magnitude is Skyfield's (Mallama and Hilton) to the last digit (worst $worst)");
}

# ---- the track and the sub-point ----------------------------------------------------

{
    my $tr = Time::Keeper::Planet->track('mars', from => $t, to => $t->epoch + 86400, step => 3600, place => $sky);
    is(scalar @{ $tr->{epoch} }, 25, 'a day hourly');
    is_deeply([sort keys %$tr], [qw(altitude apparent_altitude azimuth distance epoch illumination magnitude sub_latitude sub_longitude)], 'the track\'s keys');
    my $worst = 0;
    for my $k (0 .. 24) {
        my $p = Time::Keeper::Planet->position('mars', $tr->{epoch}[$k], place => $sky);
        my ($lat, $lon) = Time::Keeper::Planet->sub_point('mars', $tr->{epoch}[$k]);
        for ([altitude => $p->{altitude}], [azimuth => $p->{azimuth}], [magnitude => $p->{magnitude}],
             [distance => $p->{distance}], [sub_latitude => $lat], [sub_longitude => $lon]) {
            my $d = abs($tr->{ $_->[0] }[$k] - $_->[1]);
            $worst = $d if $d > $worst;
        }
    }
    cmp_ok($worst, '<=', 1e-9, "every sample is position and sub_point at its instant (worst $worst)");
    my $geo = Time::Keeper::Planet->track('neptune', from => $t, to => $t->epoch + 3600);
    ok(!exists $geo->{altitude}, 'no place, no altitude');
    my ($lat) = Time::Keeper::Planet->sub_point('saturn', $t);
    is($lat, Time::Keeper::Planet->position('saturn', $t)->{declination}, 'the sub-latitude is the declination');
}

# ---- the range and the arguments -------------------------------------------------------

{
    ok(!eval { Time::Keeper::Planet->position('pluto', utc(year => 1884, month => 12, day => 31)); 1 }, 'Pluto before 1885 dies');
    like($@, qr/Pluto's place is computed from 1885 to 2099 only/, '  naming the range');
    ok(!eval { Time::Keeper::Planet->position('pluto', utc(year => 2100, month => 1, day => 1)); 1 }, 'and from 2100');
    ok(eval { Time::Keeper::Planet->position('neptune', utc(year => 2500, month => 1, day => 1)); 1 }, 'the others go on');
    ok(!eval { Time::Keeper::Planet->track('pluto', from => utc(year => 2099, month => 12, day => 31), to => utc(year => 2100, month => 1, day => 2), step => 86400); 1 }, 'a Pluto track past 2099 dies');
    ok(!eval { Time::Keeper::Planet->position('earth', $t); 1 }, 'the earth has no position from the earth');
    like($@, qr/position: no planet is called 'earth' \(mercury, venus, mars/, '  and the list leaves it out');
    ok(!eval { Time::Keeper::Planet->position('mars', $t, colour => 'red'); 1 }, 'an unknown argument dies');
    like($@, qr/position: unknown argument 'colour'/, '  by name');
    ok(!eval { Time::Keeper::Planet->position('mars', $t, 'place'); 1 }, 'an odd list dies');
    like($@, qr/takes a planet, an instant and then name and value pairs/, '  saying so');
    ok(!eval { Time::Keeper::Planet->position('mars', $t, place => 'London'); 1 }, 'a place must be one');
    like($@, qr/not a Time::Keeper::Sun place/, '  by name');
    ok(!eval { Time::Keeper::Planet->position('mars', utc(year => 3001, month => 1, day => 1)); 1 }, 'the dist\'s range holds');
}

done_testing;
