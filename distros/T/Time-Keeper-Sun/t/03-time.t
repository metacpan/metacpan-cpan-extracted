#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Sun;

# The time scales under everything: the Julian Day, Delta T, sidereal time,
# the nutation and the obliquity, against the book's worked examples (the
# figures are the port's, sources/meeus-examples.tsv) and the observed
# Delta T. Pinned comparisons are within a tolerance, never equal: libm's
# last bit differs between platforms.

sub utc { Time::Keeper->new(@_, zone => 'UTC') }
sub near { my ($got, $want, $tol, $name) = @_; cmp_ok(abs($got - $want), '<=', $tol, "$name: $got within $tol of $want") }
sub hms { my ($h, $m, $s) = @_; ($h + $m / 60 + $s / 3600) * 15 }
sub dms { my ($d, $m, $s) = @_; $d + $m / 60 + $s / 3600 }

# ---- the Julian Day -------------------------------------------------------

near(Time::Keeper::Sun::_jd(utc(year => 1957, month => 10, day => 4, hour => 19, minute => 26, second => 24)),
     2436116.31, 1e-6, 'example 7.a: Sputnik');
is(Time::Keeper::Sun::_jd(utc(year => 2000, month => 1, day => 1, hour => 12)), 2451545.0, 'J2000.0 exactly');
near(Time::Keeper::Sun::_jd(utc(year => 1987, month => 4, day => 10)), 2446895.5, 1e-9, 'example 12.a: the JD');
near(Time::Keeper::Sun::_jd(0), 2440587.5, 0, 'the epoch, as a number');
near(Time::Keeper::Sun::_jd('1760000000.5'), 2440587.5 + 1760000000.5 / 86400, 1e-9, 'an epoch with a fraction');

{
    my $t = Time::Keeper->from_epoch('1760000000.123456789');
    my $jd = Time::Keeper::Sun::_jd($t);
    my ($sec, $nsec) = Time::Keeper::Sun::_instant_from_jd($jd);
    is($sec, 1760000000, 'a JD goes back to its second');
    cmp_ok(abs($nsec - 123456789), '<', 100_000, 'and within a tenth of a millisecond of its nanoseconds (a double JD holds no more)');
    my ($rs) = Time::Keeper::Sun::_instant_from_jd($jd, 1);
    is($rs, 1760000000, 'rounded to the second, .12 rounds down');
    ($rs) = Time::Keeper::Sun::_instant_from_jd(Time::Keeper::Sun::_jd('1760000000.6'), 1);
    is($rs, 1760000001, '.6 rounds up');
    ($rs) = Time::Keeper::Sun::_instant_from_jd(Time::Keeper::Sun::_jd('-100.5'), 1);
    is($rs, -100, 'half rounds up before the epoch too');
}

{
    my $before = utc(year => 2016, month => 12, day => 31, hour => 23, minute => 59, second => 59);
    my $leap   = utc(year => 2016, month => 12, day => 31, hour => 23, minute => 59, second => 60);
    my $after  = utc(year => 2017, month => 1, day => 1);
    is($leap->second, 60, 'the leap second is second 60');
    near(Time::Keeper::Sun::_jd($leap) - Time::Keeper::Sun::_jd($before), 1 / 86400, 2e-9, 'and its JD is one second on');
    near(Time::Keeper::Sun::_jd($after) - Time::Keeper::Sun::_jd($leap), 0, 2e-9, 'the same JD as the midnight that follows: UT has no leap seconds');
}

# ---- Delta T ----------------------------------------------------------------

{
    my $t = utc(year => 1977, month => 2, day => 18, hour => 3, minute => 37, second => 40);
    my $dt = Time::Keeper::Sun->delta_t($t);
    near($dt, 47.6, 1, 'example 10.a: within a second of the book\'s table');
    near($dt, 32.184 + 16, 1e-9, 'and exactly 32.184 plus the 16 s of TAI minus UTC in 1977');
    near(Time::Keeper::Sun->delta_t($t->epoch), $dt, 0, 'an epoch gives the same');
    near(Time::Keeper::Sun::_jde($t) - Time::Keeper::Sun::_jd($t), $dt / 86400, 1e-9, 'the JDE is the JD plus Delta T (a JD difference holds about a tenth of a millisecond)');
}

near(Time::Keeper::Sun->delta_t(utc(year => 2026, month => 10, day => 1)), 69.184, 1e-9, '2026: 32.184 + 37');
near(Time::Keeper::Sun->delta_t(utc(year => 2500, month => 1, day => 1)), 69.184, 1e-9, '2500: the last entry held');
near(Time::Keeper::Sun->delta_t(utc(year => 3000, month => 12, day => 31, hour => 23, minute => 59, second => 59)), 69.184, 1e-9, 'to the end of the range');

# The seam at 1972: the polynomial on one side, the table on the other.
near(Time::Keeper::Sun::_delta_t_poly(1972.0), 42.184, 1, 'the 1961 to 1986 piece at 1972.0 is within a second of the table\'s 42.184');
{
    my $a = Time::Keeper::Sun->delta_t(utc(year => 1971, month => 12, day => 31, hour => 23, minute => 59, second => 59));
    my $b = Time::Keeper::Sun->delta_t(utc(year => 1972, month => 1, day => 1));
    near($a, 42.25, 0.01, 'the last second of 1971 is the polynomial');
    near($b, 42.184, 1e-9, 'the first second of 1972 is the table');
    near($a - $b, 0, 1, 'and the seam is under a second');
}

# The pieces against table 10.A's values the port pins, and their joins.
near(Time::Keeper::Sun::_delta_t_poly(1800), 13.1, 2.3, '1800 against table 10.A (the paper\'s own error there)');
near(Time::Keeper::Sun::_delta_t_poly(1900), -2.8, 1, '1900 against table 10.A');
near(Time::Keeper::Sun::_delta_t_poly(1950), 29.1, 1, '1950 against table 10.A');
near(Time::Keeper::Sun::_delta_t_poly(1996), 61.6, 1, '1996 against table 10.A');
# Table 1 of the NASA page (Morrison and Stephenson 2004), which the pieces from
# -500 to 1600 were fitted to; the page says within 4 s for -500 to 500. The year
# 333 of example 10.b is 7360 here, not the book's 6146: the book's chapter 10
# is an older fit and is not what this dist computes.
{
    my @table = ([-500, 17190], [-400, 15530], [-300, 14080], [-200, 12790], [-100, 11640],
                 [0, 10580], [100, 9600], [200, 8640], [300, 7680], [400, 6700], [500, 5710],
                 [600, 4740], [700, 3810], [800, 2960], [900, 2200], [1000, 1570], [1100, 1090],
                 [1200, 740], [1300, 490], [1400, 320], [1500, 200], [1600, 120]);
    for my $row (@table) {
        my ($y, $v) = @$row;
        my $tol = $y <= 500 ? 4 : 10;
        $tol = 20 if $y == -500;
        cmp_ok(abs(Time::Keeper::Sun::_delta_t_poly($y) - $v), '<=', $tol, "Table 1, the year $y: within $tol s of $v");
    }
    near(Time::Keeper::Sun::_delta_t_poly(333.1), 7680 - 0.331 * 980, 10, 'the year 333 of example 10.b against Table 1, not the book');
}
for my $join (-500, 500, 1600, 1700, 1800, 1860, 1900, 1920, 1941, 1961, 1986, 2005, 2050, 2150) {
    my $lo = Time::Keeper::Sun::_delta_t_poly($join - 1e-6);
    my $hi = Time::Keeper::Sun::_delta_t_poly($join + 1e-6);
    near($lo, $hi, 1, "the pieces join at $join");
}
near(Time::Keeper::Sun::_delta_t_poly(-1999), -20 + 32 * ((-1999 - 1820) / 100)**2, 1e-6, 'the first year of the range');
near(Time::Keeper::Sun::_delta_t_poly(2026), 75.1, 0.1, 'the 2005 to 2050 piece overshoots 2026 (75.1 against the real 69.2), which is why the table is used there');

# Observed Delta T (IERS, t/deltat.data: year month day value) from 1973,
# within a second: the difference is UT1 minus UTC, under 0.9 s.
{
    my $file = -e 't/deltat.data' ? 't/deltat.data' : 'deltat.data';
    open my $fh, '<', $file or BAIL_OUT("$file: $!");
    my ($rows, $worst) = (0, 0);
    while (<$fh>) {
        my ($y, $m, $d, $v) = split ' ';
        next unless defined $v;
        my $dt = Time::Keeper::Sun->delta_t(utc(year => $y, month => $m, day => $d));
        my $diff = abs($dt - $v);
        $worst = $diff if $diff > $worst;
        $rows++;
    }
    close $fh;
    cmp_ok($rows, '>', 600, "$rows observed rows read");
    cmp_ok($worst, '<', 1, "every observed Delta T within a second (worst $worst)");
}

# ---- angles -------------------------------------------------------------------

is(Time::Keeper::Sun::_deg_norm(370), 10, '370 degrees is 10');
is(Time::Keeper::Sun::_deg_norm(-10), 350, '-10 degrees is 350');
is(Time::Keeper::Sun::_deg_norm(-720), 0, '-720 is 0');
# fmod gives -0 for a negative multiple of 360, which perls before 5.14 print
# as -0; atan2 tells the sign apart on any perl.
is(atan2(0, Time::Keeper::Sun::_deg_norm(-720)), 0, 'and a positive zero, not -0');
is(atan2(0, Time::Keeper::Sun::_deg_norm(-360)), 0, '-360 too');
is(Time::Keeper::Sun::_deg_norm(359.5), 359.5, '359.5 stays');
near(Time::Keeper::Sun::_deg_norm(-0.25), 359.75, 1e-9, 'a small negative wraps to just under 360');

# ---- sidereal time ------------------------------------------------------------

{
    my $t = utc(year => 1987, month => 4, day => 10);
    my ($mean, $app) = Time::Keeper::Sun::_sidereal($t);
    near($mean, hms(13, 10, 46.3668), 1e-5, 'example 12.a: mean sidereal time at Greenwich');
    near($app, hms(13, 10, 46.1351), 2e-4, 'example 12.a: apparent, within the short nutation\'s half arcsecond');
    my ($mean_b) = Time::Keeper::Sun::_sidereal(utc(year => 1987, month => 4, day => 10, hour => 19, minute => 21));
    near($mean_b, hms(8, 34, 57.0896), 1e-5, 'example 12.b: 19h21m UT');
}
for my $y (-1999, 1000, 3000) {
    my ($mean, $app) = Time::Keeper::Sun::_sidereal(utc(year => $y, month => 6, day => 15, hour => 6));
    ok($mean >= 0 && $mean < 360 && $app >= 0 && $app < 360, "the year $y: both angles in [0, 360)");
}

# ---- the nutation and the obliquity -----------------------------------------

{
    my $t = utc(year => 1987, month => 4, day => 10);
    my ($dpsi, $deps) = Time::Keeper::Sun::_nutation($t);
    near($dpsi, -3.788, 0.5, 'example 22.a: nutation in longitude, within the short form\'s half arcsecond');
    near($deps, 9.443, 0.1, 'example 22.a: nutation in obliquity, within a tenth');
    my ($e0, $e) = Time::Keeper::Sun::_obliquity($t);
    near($e0, dms(23, 26, 27.407), 1e-6, 'example 22.a: the mean obliquity to the book\'s digits');
    near($e, dms(23, 26, 36.850), 0.1 / 3600, 'and the true obliquity within a tenth of an arcsecond');
}

# ---- the range and the arguments ----------------------------------------------

ok(eval { Time::Keeper::Sun->delta_t(utc(year => -1999, month => 1, day => 1)); 1 }, '-1999 is in range');
ok(eval { Time::Keeper::Sun->delta_t(utc(year => 3000, month => 12, day => 31, hour => 23, minute => 59, second => 59)); 1 }, 'the last second of 3000 is in range');
ok(!eval { Time::Keeper::Sun->delta_t(utc(year => -2000, month => 12, day => 31, hour => 23, minute => 59, second => 59)); 1 }, '-2000 is not');
like($@, qr/^Time::Keeper::Sun->delta_t: the year -2000 is outside the years Time::Keeper::Sun computes \(-1999 to 3000\)/, 'and it says so by name');
ok(!eval { Time::Keeper::Sun->delta_t(utc(year => 3001, month => 1, day => 1)); 1 }, '3001 is not');
like($@, qr/the year 3001 is outside/, 'naming the year');

ok(!eval { Time::Keeper::Sun->delta_t(); 1 }, 'no argument dies');
ok(!eval { Time::Keeper::Sun->delta_t(undef); 1 }, 'undef dies');
like($@, qr/^Time::Keeper::Sun->delta_t needs a Time::Keeper value or an epoch/, 'saying what it takes');
ok(!eval { Time::Keeper::Sun->delta_t('soon'); 1 }, 'a word dies');
like($@, qr/'soon' is neither a Time::Keeper value nor an epoch/, 'naming it');
ok(!eval { Time::Keeper::Sun->delta_t([]); 1 }, 'a reference that is not a value dies');
like($@, qr/not a Time::Keeper value/, 'saying so');
ok(!eval { Time::Keeper::Sun->delta_t(Time::Keeper::Duration->new(hours => 1)); 1 }, 'a duration dies');

done_testing;
