#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Sun;
use Time::Keeper::Moon;

# The moon's place: example 47.a and example 40.a (the Go port's digits,
# plan_time_keeper_sun_2/sources), and USNO's celestial navigation data for
# the Moon (t/usno-celnav-moon.tsv), an independent ephemeris.

sub utc { Time::Keeper->new(@_, zone => 'UTC') }
sub near { my ($got, $want, $tol, $name) = @_; cmp_ok(abs($got - $want), '<=', $tol, "$name: $got within $tol of $want") }
sub hms { my ($h, $m, $s) = @_; ($h + $m / 60 + $s / 3600) * 15 }
sub dms { my ($d, $m, $s) = @_; my $sign = $d < 0 || $d eq '-0' ? -1 : 1; $sign * (abs($d) + $m / 60 + $s / 3600) }
sub angle_diff { my $d = abs($_[0] - $_[1]); $d -= 360 * int($d / 360); $d > 180 ? 360 - $d : $d }

# ---- example 47.a: 1992 April 12, 0h TD ----------------------------------------

{
    my ($lon_geo, $lat, $dist, $pi, $lon, $ra, $dec) = Time::Keeper::Sun::_moon_place_jde(2448724.5);
    near($lon_geo, 133.162655, 1e-6, 'example 47.a: the geometric longitude');
    near($lat, -3.229126, 1e-6, 'the latitude');
    near($dist, 368409.7, 0.05, 'the distance in km');
    near($pi, 0.991990, 1e-6, 'the horizontal parallax');
    near($lon, 133.167265, 0.0002, 'the apparent longitude, the book\'s 133.167265 within the short nutation\'s half arcsecond');
    near($ra, 134.6885, 0.0002, 'the apparent right ascension, as 48.a takes it');
    near($dec, 13.7684, 0.0002, 'the apparent declination');
}

# ---- example 40.a: Mars from Palomar, 2003 August 28 at 3h17m UT ---------------

{
    my ($rs, $rc) = Time::Keeper::Sun::_parallax_constants(dms(33, 21, 22), 1706);
    near($rs, 0.546861, 1e-6, 'example 40.a: rho sin phi\'');
    near($rc, 0.836339, 1e-6, 'rho cos phi\'');
    my $t = utc(year => 2003, month => 8, day => 28, hour => 3, minute => 17);
    my (undef, $theta) = Time::Keeper::Sun::_sidereal($t);
    my $lon_east = -hms(7, 47, 27);
    my $H = Time::Keeper::Sun::_deg_norm($theta + $lon_east - 339.530208);
    $H -= 360 if $H > 180;
    my $pi = 23.592 / 3600;
    my ($Ht, $dect) = Time::Keeper::Sun::_topocentric($H, -15.771083, $pi, $rs, $rc);
    near($Ht, -hms(4, 44, 50.28), 0.0002, 'the topocentric hour angle, -4h44m50.28s');
    near($dect, dms(-15, 46, 30.0), 0.05 / 3600, 'the topocentric declination, -15 46 30.0');
    my $ra_t = Time::Keeper::Sun::_deg_norm($theta + $lon_east - $Ht);
    near($ra_t, hms(22, 38, 8.54), 0.01 / 240, 'and the topocentric right ascension, 22h38m08.54s');
    my ($H0) = Time::Keeper::Sun::_topocentric($H, -15.771083, 0, $rs, $rc);
    near($H0, $H, 1e-9, 'no parallax, no shift');
}

# ---- position, geocentric (T6) -----------------------------------------------------

{
    my $t = utc(year => 2026, month => 10, day => 15, hour => 12);
    my $p = Time::Keeper::Moon->position($t);
    is(ref $p, 'HASH', 'position is a hash ref');
    is(join(' ', sort keys %$p), 'bright_limb constellation declination distance latitude longitude parallax right_ascension', 'with eight keys, and no altitude or azimuth without a place');
    ok($p->{distance} > 356000 && $p->{distance} < 407000, "a distance the moon keeps ($p->{distance} km)");
    near($p->{parallax}, 180 / 3.14159265358979 * asin_(6378.14 / $p->{distance}), 1e-9, 'the parallax from the distance');
    ok(abs($p->{latitude}) < 5.3, 'the latitude within the orbit\'s tilt');
    is_deeply(Time::Keeper::Moon->position($t->in_zone('Asia/Tokyo')), $p, 'the same instant in another zone is the same place');
    is(Time::Keeper::Moon->position($t->epoch)->{longitude}, $p->{longitude}, 'an epoch is the same');
    my ($lo, $hi) = (1e9, 0);
    for my $d (0 .. 365) {
        my $q = Time::Keeper::Moon->position($t->plus(days => $d));
        $lo = $q->{distance} if $q->{distance} < $lo;
        $hi = $q->{distance} if $q->{distance} > $hi;
    }
    ok($lo > 356000 && $lo < 360000, "the nearest of a year's days, $lo km, is a perigee");
    ok($hi > 404000 && $hi < 407000, "the farthest, $hi km, an apogee");
    ok(!eval { Time::Keeper::Moon->position(utc(year => 3001, month => 1, day => 1)); 1 }, 'the year 3001 dies');
    like($@, qr/^Time::Keeper::Moon->position: the year 3001 is outside/, 'by name');
    ok(!eval { Time::Keeper::Moon->position('soon'); 1 }, 'a word dies');
    like($@, qr/'soon' is neither a Time::Keeper value nor an epoch/, 'by name');
}
sub asin_ { atan2($_[0], sqrt(1 - $_[0] * $_[0])) }

# ---- from a place ---------------------------------------------------------------------

{
    my $london = Time::Keeper::Sun->new(latitude => 51.5074, longitude => -0.1278);
    my $t = utc(year => 2026, month => 10, day => 26, hour => 4);
    my ($H, $alt_geo, $az_geo, $dect, $alt, $app, $az) = Time::Keeper::Sun::_moon_view($london, $t);
    ok($alt < $alt_geo, 'parallax lowers the moon seen from the surface');
    near($alt_geo - $alt, 0.9 * cos($alt_geo * 3.14159265358979 / 180), 0.1, 'by about the horizontal parallax times the cosine of the altitude');
    ok($app > $alt, 'refraction lifts it');
    my $cliff = Time::Keeper::Sun->new(latitude => 51.5074, longitude => -0.1278, elevation => 5000);
    my (undef, undef, undef, undef, $alt_high) = Time::Keeper::Sun::_moon_view($cliff, $t);
    ok(abs($alt_high - $alt) > 1e-6 && abs($alt_high - $alt) < 0.01, 'a height of 5 km moves it by thousandths of a degree');
}

# ---- USNO's celestial navigation data for the Moon -------------------------------------

{
    my $file = -e 't/usno-celnav-moon.tsv' ? 't/usno-celnav-moon.tsv' : 'usno-celnav-moon.tsv';
    open my $fh, '<', $file or BAIL_OUT("$file: $!");
    my ($rows, %worst) = (0);
    while (<$fh>) {
        next if /^#/;
        chomp;
        my ($place, $date, $time, $lat, $lon, $dec, $gha, $hc, $zn, $pa) = split /\t/;
        next unless defined $pa;
        my ($y, $mo, $d) = split /-/, $date;
        my ($h, $mi, $s) = split /:/, $time;
        my $t = utc(year => $y, month => $mo, day => $d, hour => $h, minute => $mi, second => $s);
        my $p = Time::Keeper::Moon->position($t);
        my (undef, $theta) = Time::Keeper::Sun::_sidereal($t);
        my $here = Time::Keeper::Sun->new(latitude => $lat, longitude => $lon);
        my ($H, $alt_geo, $az_geo, undef, $alt) = Time::Keeper::Sun::_moon_view($here, $t);
        my %diff = (
            declination => abs($p->{declination} - $dec),
            gha         => angle_diff(Time::Keeper::Sun::_deg_norm($theta - $p->{right_ascension}), $gha),
            altitude    => abs($alt_geo - $hc),
            azimuth     => angle_diff($az_geo, $zn),
        );
        $diff{parallax} = abs(($alt_geo - $alt) - $pa) if $pa ne '---';
        for my $k (keys %diff) { $worst{$k} = $diff{$k} if !defined $worst{$k} || $diff{$k} > $worst{$k} }
        my $label = "$place $date $time";
        cmp_ok($diff{declination}, '<=', 0.005, "$label: declination within 0.005");
        cmp_ok($diff{gha}, '<=', 0.01, "$label: the Greenwich hour angle within 0.01");
        cmp_ok($diff{altitude}, '<=', 0.02, "$label: the geocentric altitude within 0.02");
        cmp_ok($diff{azimuth}, '<=', 0.03, "$label: the azimuth within 0.03") if abs($hc) < 85;
        cmp_ok($diff{parallax}, '<=', 0.01, "$label: the parallax in altitude within 0.01") if exists $diff{parallax};
        $rows++;
    }
    close $fh;
    cmp_ok($rows, '>=', 30, "$rows rows against USNO");
    note(sprintf 'worst against USNO over %d rows: declination %.4f, gha %.4f, altitude %.4f, azimuth %.4f, parallax in altitude %.4f degrees',
         $rows, @worst{qw(declination gha altitude azimuth parallax)});
}

done_testing;
