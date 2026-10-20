#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Sky;
use Time::Keeper::Planet;

# VSOP87D, every term: IMCCE's own check values (t/vsop87d-check.tsv, from
# vsop87.chk), Meeus's examples 32.a and 25.b, and the sun from the VSOP87
# earth behind precise => 1.

sub near { my ($got, $want, $tol, $name) = @_; cmp_ok(abs($got - $want), '<=', $tol, "$name: $got within $tol of $want") }
sub angle_diff { my $d = abs($_[0] - $_[1]); $d -= 360 * int($d / 360); $d > 180 ? 360 - $d : $d }
my $PI = 4 * atan2(1, 1);
my %ix = (mercury => 0, venus => 1, earth => 2, mars => 3, jupiter => 4, saturn => 5, uranus => 6, neptune => 7);

# ---- IMCCE's check file -------------------------------------------------------------

{
    my $file = -e 't/vsop87d-check.tsv' ? 't/vsop87d-check.tsv' : 'vsop87d-check.tsv';
    open my $fh, '<', $file or die "$file: $!";
    my ($n, %w, %planets) = (0);
    while (<$fh>) {
        next if /^#/;
        chomp;
        my ($p, $jd, $l, $b, $r) = split /\t/;
        my ($L, $B, $R) = Time::Keeper::Sun::_vsop_lbr($ix{$p}, $jd);
        my $dl = $L - $l;
        $dl -= 2 * $PI * int($dl / (2 * $PI));
        $dl -= 2 * $PI if $dl > $PI;
        $dl += 2 * $PI if $dl < -$PI;
        my %d = (l => abs($dl), b => abs($B - $b), r => abs($R - $r));
        $w{$_} = $d{$_} > ($w{$_} // 0) ? $d{$_} : $w{$_} for keys %d;
        $planets{$p}++;
        $n++;
    }
    is($n, 80, 'all 80 VSOP87D entries of vsop87.chk');
    is(scalar keys %planets, 8, '  for the eight planets');
    # the file prints ten decimals: half its last place is 5e-11
    cmp_ok($w{l}, '<=', 1e-10, "longitude within 1e-10 rad (worst $w{l})");
    cmp_ok($w{b}, '<=', 1e-10, "latitude within 1e-10 rad (worst $w{b})");
    cmp_ok($w{r}, '<=', 1e-10, "radius within 1e-10 AU (worst $w{r})");
}

# ---- Meeus ---------------------------------------------------------------------------

{
    # Example 32.a: Venus, 1992 December 20 at 0h TD. The book sums its own
    # truncation (Appendix III); every term moves the result in the fifth place.
    my ($L, $B, $R) = Time::Keeper::Sun::_vsop_lbr(1, 2448976.5);
    my $deg = $L * 180 / $PI;
    near(angle_diff($deg, 26.11428), 0, 0.0003, 'example 32.a: Venus\'s longitude, 26.11428 in the book');
    near($B * 180 / $PI, -2.62070, 0.0003, '  its latitude, -2.62070');
    near($R, 0.724603, 0.000005, '  its radius, 0.724603 AU');

    # Example 25.b: the sun on 1992 October 13 at 0h TD, by VSOP87 (the book's
    # full nutation; this dist's short one is within half an arcsecond).
    my ($lon, $ra, $dec, $dist) = Time::Keeper::Sun::_sun_precise_jde(2448908.5);
    near(angle_diff($ra, 198.378121), 0, 0.5 / 3600, 'example 25.b: the apparent right ascension, 13h13m30.749s');
    near($dec, -7.783817, 0.5 / 3600, '  the declination, -7 47 01.74');
    near($dist, 0.99760853, 1e-7, '  the distance, 0.99760853 AU');
    my (undef, undef, undef, undef, $eot) = Time::Keeper::Sun::_sun_precise_jde(2448908.5);
    near($eot, 822.6, 0.2, 'example 28.a: the equation of time, 13m42.6s');
}

# ---- heliocentric ------------------------------------------------------------------

{
    my $t = Time::Keeper->new(year => 2026, month => 10, day => 19, hour => 12, zone => 'UTC');
    my $jde = Time::Keeper::Sun::_jde($t);
    for my $p (qw(mercury venus earth mars jupiter saturn uranus neptune)) {
        my $h = Time::Keeper::Planet->heliocentric($p, $t);
        my ($L, $B, $R) = Time::Keeper::Sun::_vsop_lbr($ix{$p}, $jde);
        my $l = $L * 180 / $PI;
        $l -= 360 * int($l / 360);
        $l += 360 if $l < 0;
        ok(abs($h->{longitude} - $l) < 1e-9 && abs($h->{latitude} - $B * 180 / $PI) < 1e-12 && $h->{radius} == $R,
           "$p: heliocentric is the series at the instant's TT, in degrees");
        ok($h->{longitude} >= 0 && $h->{longitude} < 360, '  the longitude from 0 to 360');
    }
    is_deeply([sort keys %{ Time::Keeper::Planet->heliocentric('mars', $t) }], [qw(latitude longitude radius)], 'three keys');
    is_deeply([Time::Keeper::Planet->planets], [qw(mercury venus mars jupiter saturn uranus neptune pluto)], 'planets: from the sun out, Pluto last, no earth');
    my $e = Time::Keeper::Planet->heliocentric('earth', $t);
    my $s = Time::Keeper::Sky->new(latitude => 0, longitude => 0)->position($t, precise => 1);
    near($e->{radius}, $s->{distance}, 1e-12, 'the earth\'s radius is the precise sun\'s distance');
    my ($l0, $b0, $r0) = Time::Keeper::Sun::_pluto_j2000($jde);
    my ($lp, $bp) = Time::Keeper::Sun::_precess_ecliptic(($jde - 2451545) / 36525, $l0, $b0);
    my $pl = Time::Keeper::Planet->heliocentric('pluto', $t);
    ok(abs($pl->{longitude} - $lp) < 1e-9 && abs($pl->{latitude} - $bp) < 1e-9 && $pl->{radius} == $r0,
       'pluto: chapter 37, precessed from J2000 to the date');
    ok(!eval { Time::Keeper::Planet->heliocentric('vulcan', $t); 1 }, 'an unknown planet dies');
    like($@, qr/heliocentric: no planet is called 'vulcan' \(mercury, venus, earth, mars, jupiter, saturn, uranus, neptune or pluto\)/, '  and the message lists the planets');
    ok(!eval { Time::Keeper::Planet->heliocentric(undef, $t); 1 }, 'a planet is needed');
    like($@, qr/heliocentric needs a planet's name/, '  by name');
    ok(!eval { Time::Keeper::Planet->heliocentric('mars', Time::Keeper->new(year => 3001, month => 1, day => 1, zone => 'UTC')); 1 }, 'the range holds');
    like($@, qr/the year 3001 is outside/, '  by name');
    {
        package Tied;
        sub TIESCALAR { my ($c, $v) = @_; bless \$v, $c }
        sub FETCH { ${ $_[0] } }
    }
    tie my $name, 'Tied', 'jupiter';
    is(Time::Keeper::Planet->heliocentric($name, $t)->{radius}, Time::Keeper::Planet->heliocentric('jupiter', $t)->{radius}, 'a tied name is read');
    is(Time::Keeper::Planet->heliocentric(substr('xsaturn', 1), $t)->{radius}, Time::Keeper::Planet->heliocentric('saturn', $t)->{radius}, 'and a substr');
}

# ---- precise => 1 -------------------------------------------------------------------

{
    my $sky = Time::Keeper::Sky->new(place => 'Europe/London');
    my $t = Time::Keeper->new(year => 2026, month => 10, day => 19, hour => 12, zone => 'UTC');
    my $c25 = $sky->position($t);
    is_deeply($sky->position($t, precise => 0), $c25, 'precise => 0 is the chapter 25 sun, to the bit');
    my $p = $sky->position($t, precise => 1);
    is_deeply([sort keys %$p], [sort keys %$c25], 'precise => 1 has the same keys');
    my $sep = sqrt((angle_diff($p->{right_ascension}, $c25->{right_ascension}) * cos($p->{declination} / 57.2958)) ** 2 + ($p->{declination} - $c25->{declination}) ** 2) * 3600;
    cmp_ok($sep, '<=', 36, "and differs from chapter 25 by under its 0.01 degree ($sep arcseconds)");
    cmp_ok($sep, '>', 0, '  but differs');
    # 28.3 (Smart's series on chapter 25's elements) was measured within 2.8 s
    # of USNO in 0.01; 28.1 on the VSOP87 sun is the exact form.
    near($p->{equation_of_time}, $c25->{equation_of_time}, 3, 'the equation of time by 28.1 agrees with 28.3 within its 3 s');
    near($p->{altitude}, $c25->{altitude}, 0.01, 'the altitude within the chapter 25 sun\'s hundredth');
    ok(!eval { $sky->position($t, exact => 1); 1 }, 'position: another argument dies');
    like($@, qr/position: unknown argument 'exact'/, '  naming it');
    ok(!eval { $sky->position($t, 'precise'); 1 }, '  and an odd list');
    like($@, qr/position takes an instant and then name and value pairs/, '  says so');
}

done_testing;
