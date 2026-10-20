#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Sun;

# The sun's apparent place, the equation of time, the altitude and azimuth
# from a place, and the place object itself: against the book's examples
# 25.a, 28.b and 13.b (the port's digits, sources/meeus-examples.tsv) and
# against USNO's celestial navigation data (t/usno-celnav.tsv), which is an
# independent ephemeris to six decimals.

sub utc { Time::Keeper->new(@_, zone => 'UTC') }
sub near { my ($got, $want, $tol, $name) = @_; cmp_ok(abs($got - $want), '<=', $tol, "$name: $got within $tol of $want") }
sub hms { my ($h, $m, $s) = @_; ($h + $m / 60 + $s / 3600) * 15 }
sub dms { my ($d, $m, $s) = @_; my $sign = $d < 0 || $d eq '-0' ? -1 : 1; $sign * (abs($d) + $m / 60 + $s / 3600) }

# ---- example 25.a: 1992 October 13, 0h TD ---------------------------------------

{
    my ($T, $L0, $M, $e, $true, $app, $ra, $dec, $R, $eot) = Time::Keeper::Sun::_sun_at_jde(2448908.5);
    near($T, -0.072183436, 1e-9, 'T');
    near($M, -2241.00603 + 7 * 360, 1e-5, 'the mean anomaly, reduced');
    near($e, 0.016711668, 1e-9, 'the eccentricity');
    near($true, 199.90987, 1e-5, 'the true longitude');
    near($app, dms(199, 54, 32), 1 / 3600, 'the apparent longitude, within the book\'s arcsecond');
    near($ra, hms(13, 13, 31.4), 0.1 / 240, 'the apparent right ascension, within the book\'s tenth of a second');
    near($dec, dms(-7, 47, 6), 1 / 3600, 'the apparent declination, within the book\'s arcsecond');
    near($R, 0.99766, 1e-5, 'the radius vector');
    # Example 28.b, the same date, by Smart's formula (28.3): +13m42.7s.
    near($eot, 13 * 60 + 42.7, 0.1, 'example 28.b: the equation of time');
}

# ---- example 13.b: Venus from Washington, 1987 April 10, 19h21m UT --------------

{
    my $t = utc(year => 1987, month => 4, day => 10, hour => 19, minute => 21);
    my ($alt, $az, $H) = Time::Keeper::Sun::_altaz($t, dms(38, 55, 17), -dms(77, 3, 56), hms(23, 9, 16.641), dms(-6, 43, 11.61));
    near($H, 64.352133, 0.002, 'the local hour angle (the book\'s 64.352133, within the short nutation)');
    near($az, 68.0337 + 180, 0.002, 'the azimuth, the book\'s +68.0337 from the south, so 248.034 from the north');
    near($alt, 15.1249, 0.002, 'the altitude');
}

# ---- refraction -------------------------------------------------------------------

{
    my $r0 = Time::Keeper::Sun::_refraction(0);
    ok($r0 > 28 && $r0 < 30, "refraction at the geometric horizon is about 29 arcminutes ($r0)");
    cmp_ok(abs(Time::Keeper::Sun::_refraction(90)), '<', 0.001, 'and nothing at the zenith');
    is(Time::Keeper::Sun::_refraction(-1.5), 0, 'and not applied a degree and a half below the horizon');
    cmp_ok(Time::Keeper::Sun::_refraction(-0.9), '>', 30, 'but still applied just under it');
    cmp_ok(Time::Keeper::Sun::_refraction(45), '<', 1.1, 'about an arcminute at 45 degrees');
}

# ---- the place ----------------------------------------------------------------------

my $london = Time::Keeper::Sun->new(latitude => 51.5074, longitude => -0.1278, zone => 'Europe/London');
isa_ok($london, 'Time::Keeper::Sun');
is($london->latitude, 51.5074, 'latitude');
is($london->longitude, -0.1278, 'longitude');
is($london->elevation, 0, 'elevation defaults to 0');
is($london->zone_name, 'Europe/London', 'zone_name');
is($london->locale, 'en', 'the locale defaults to en');
{
    my $p = Time::Keeper::Sun->new(latitude => -33.8688, longitude => 151.2093, elevation => 58, zone => 'Australia/Sydney', locale => 'fr');
    is($p->elevation, 58, 'elevation given');
    is($p->locale, 'fr', 'locale given');
    is(Time::Keeper::Sun->new(latitude => 0, longitude => 0)->zone_name, 'UTC', 'the zone defaults to UTC');
    is(Time::Keeper::Sun->new(latitude => 0, longitude => 0, zone => '+05:30')->zone_name, '+05:30', 'an offset is a zone');
}
for my $bad (
    [[latitude => 91, longitude => 0], qr/latitude must be between -90 and 90, not 91/],
    [[latitude => -90.5, longitude => 0], qr/latitude must be between/],
    [[latitude => 0, longitude => 180.5], qr/longitude must be between -180 and 180, not 180\.5/],
    [[latitude => 'north', longitude => 0], qr/latitude must be a number of degrees, north positive/],
    [[latitude => 0, longitude => 0, elevation => -430], qr/elevation is the height above the horizon seen and cannot be negative \(-430\)/],
    [[latitude => 0, longitude => 0, zone => 'floating'], qr/a place has an offset; the floating zone cannot be one/],
    [[latitude => 0, longitude => 0, zone => 'Nowhere/City'], qr/no such zone 'Nowhere\/City'/],
    [[latitude => 0, longitude => 0, locale => 'xx-YY'], qr/no such locale 'xx-YY'/],
    [[latitude => 0, longitude => 0, colour => 'red'], qr/unknown argument 'colour'/],
    [[latitude => 0], qr/needs latitude and longitude/],
    [[longitude => 0], qr/needs latitude and longitude/],
    [[latitude => 0, longitude => 0, 'odd'], qr/takes name and value pairs/],
) {
    my ($args, $re) = @$bad;
    ok(!eval { Time::Keeper::Sun->new(@$args); 1 }, "new(@$args) dies");
    like($@, $re, 'by name');
}
ok(!eval { Time::Keeper::Sun::latitude(bless(\(my $s = 'x'), 'Time::Keeper::Sun')); 1 }, 'a forged place is refused');
like($@, qr/^latitude: not a Time::Keeper::Sun place/, 'by name');
ok(!eval { Time::Keeper::Sun::latitude([]); 1 }, 'an array is not a place');

# ---- position ------------------------------------------------------------------------

{
    my $t = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 12, zone => 'UTC');
    my $p = $london->position($t);
    is(ref $p, 'HASH', 'position is a hash ref');
    is(join(' ', sort keys %$p), 'altitude apparent_altitude azimuth declination distance equation_of_time hour_angle right_ascension', 'with the eight keys');
    ok($p->{altitude} > 25 && $p->{altitude} < 35, "London at noon UT in mid October: the sun about 30 degrees up ($p->{altitude})");
    ok($p->{azimuth} > 175 && $p->{azimuth} < 195, "and nearly south ($p->{azimuth})");
    ok($p->{apparent_altitude} > $p->{altitude}, 'refraction lifts the apparent altitude');
    ok($p->{declination} < -7 && $p->{declination} > -9, "declination about -8 ($p->{declination})");
    ok($p->{distance} > 0.99 && $p->{distance} < 1.0, "distance under an AU in October ($p->{distance})");
    ok($p->{equation_of_time} > 13 * 60 && $p->{equation_of_time} < 15 * 60, "the equation of time about 14 minutes ($p->{equation_of_time})");
    ok(abs($p->{hour_angle}) < 5, "the hour angle near zero at noon ($p->{hour_angle})");
    my $q = $london->position($t->in_zone('Asia/Tokyo'));
    is($q->{altitude}, $p->{altitude}, 'the same instant in another zone is the same position');
    is($london->position($t->epoch)->{altitude}, $p->{altitude}, 'an epoch is the same');

    my $mid = Time::Keeper->new(year => 2026, month => 10, day => 15, zone => 'Europe/London');
    cmp_ok($london->position($mid)->{altitude}, '<', -30, 'London at midnight in October: the sun far below the horizon');
    my $svalbard = Time::Keeper::Sun->new(latitude => 78.2232, longitude => 15.6267, zone => 'Arctic/Longyearbyen');
    cmp_ok($svalbard->position(Time::Keeper->new(year => 2026, month => 6, day => 21, zone => 'Arctic/Longyearbyen'))->{altitude}, '>', 10,
           'Longyearbyen at midnight in June: the sun up');
}

ok(!eval { $london->position(utc(year => 3001, month => 1, day => 1)); 1 }, 'position refuses the year 3001');
like($@, qr/^position: the year 3001 is outside/, 'by name');
ok(!eval { $london->position('noon'); 1 }, 'and a word');

# ---- USNO's celestial navigation data ------------------------------------------------

{
    my $file = -e 't/usno-celnav.tsv' ? 't/usno-celnav.tsv' : 'usno-celnav.tsv';
    open my $fh, '<', $file or BAIL_OUT("$file: $!");
    my ($rows, %worst) = (0);
    while (<$fh>) {
        next if /^#/;
        chomp;
        my ($place, $date, $time, $lat, $lon, $dec, $gha, $hc, $zn) = split /\t/;
        next unless defined $zn;
        my ($y, $mo, $d) = split /-/, $date;
        my ($h, $mi, $s) = split /:/, $time;
        my $t = utc(year => $y, month => $mo, day => $d, hour => $h, minute => $mi, second => $s);
        my $p = Time::Keeper::Sun->new(latitude => $lat, longitude => $lon)->position($t);
        my %diff = (
            declination => abs($p->{declination} - $dec),
            altitude    => abs($p->{altitude} - $hc),
            azimuth     => abs(Time::Keeper::Sun::_deg_norm($p->{azimuth} - $zn + 180) - 180),
        );
        # The Greenwich hour angle is the apparent sidereal time less the right
        # ascension; USNO gives it directly, and the equation of time follows
        # from it: the hour angle of the mean sun is 15 UT - 180.
        my ($mean, $app) = Time::Keeper::Sun::_sidereal($t);
        $diff{gha} = abs(Time::Keeper::Sun::_deg_norm($app - $p->{right_ascension} - $gha + 180) - 180);
        my $eot_usno = (Time::Keeper::Sun::_deg_norm($gha - (15 * ($h + $mi / 60 + $s / 3600) - 180) + 180) - 180) * 240;
        $diff{eot} = abs($p->{equation_of_time} - $eot_usno);
        for my $k (keys %diff) { $worst{$k} = $diff{$k} if !defined $worst{$k} || $diff{$k} > $worst{$k} }
        cmp_ok($diff{declination}, '<=', 0.01, "$place $date $time: declination within 0.01");
        cmp_ok($diff{altitude}, '<=', 0.02, "$place $date $time: altitude within 0.02");
        cmp_ok($diff{azimuth}, '<=', 0.03, "$place $date $time: azimuth within 0.03") if abs($hc) < 85;
        cmp_ok($diff{gha}, '<=', 0.02, "$place $date $time: the Greenwich hour angle within 0.02");
        cmp_ok($diff{eot}, '<=', 5, "$place $date $time: the equation of time within 5 s");
        $rows++;
    }
    close $fh;
    cmp_ok($rows, '>=', 24, "$rows rows against USNO");
    note(sprintf 'worst against USNO over %d rows: declination %.4f, altitude %.4f, azimuth %.4f, gha %.4f degrees, equation of time %.2f s',
         $rows, @worst{qw(declination altitude azimuth gha eot)});
}

done_testing;
