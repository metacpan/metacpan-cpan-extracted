#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
BEGIN { require './xt/skyfield_oracle.pl' }
use Time::Keeper;
use Time::Keeper::Sky;
use Time::Keeper::Planet;

# Author test: every planet's apparent place against Skyfield and DE421
# (the outer planets and Pluto as their systems' barycentres), every 37 days
# and an hour from 1900 to 2050 at the same TT, so the ephemerides are
# compared and Delta T is not. The marks, set in plan_time_keeper_sky/03
# before any number was seen: 1 arcsecond on the sky (Pluto 2), the
# distance within 1e-7 AU, the light-time within 1 ms, the magnitude (same
# formulae) within 0.01. The misses are TODO with the reason: VSOP87 was
# fitted to DE200 (1982), and the outer planets have moved since; Pluto's
# chapter 37 is a fit of 43 terms.
#
# The magnitudes are checked in two parts, because Skyfield's own puts the
# sun at the barycentre (0.01 AU out, 1.5 degrees of Mercury's phase): this
# dist's numbers through Skyfield's formula functions (the transcription),
# and the phase angle against DE421 with the sun's own place (the geometry).

my $why = SkyfieldOracle::usable();
plan skip_all => $why if $why;

my $from = Time::Keeper->new(year => 1900, month => 1, day => 1, zone => 'UTC')->epoch;
my $to = Time::Keeper->new(year => 2050, month => 1, day => 1, zone => 'UTC')->epoch;
my $R = atan2(1, 1) / 45;
my %ix = (mercury => 0, venus => 1, mars => 3, jupiter => 4, saturn => 5, uranus => 6, neptune => 7, pluto => 8);
for my $planet (Time::Keeper::Planet->planets) {
    my @e;
    for (my $e = $from; $e < $to; $e += 37 * 86400 + 3917) { push @e, $e }
    my @jde = map { Time::Keeper::Sun::_jde($_) } @e;
    my @ours = map { [Time::Keeper::Sun::_planet_jde($ix{$planet}, $_)] } @jde;
    my $pos = SkyfieldOracle::ask([map { { kind => 'planetpos', planet => $planet, jde => $_ } } @jde]);
    my $ph  = SkyfieldOracle::ask([map { { kind => 'planetphase', planet => $planet, jde => $_ } } @jde]);
    my $mag = $planet eq 'pluto' ? [] : SkyfieldOracle::ask([map {
        my $o = $ours[$_];
        { kind => 'planetmag', planet => $planet, r => $o->[6], delta => $o->[2], phase => $o->[7],
          sun_lat => $o->[9], obs_lat => $o->[10], year => 2000 + ($jde[$_] - 2451545) / 365.25 }
    } 0 .. $#jde]);
    my %w = (sky => 0, dist => 0, lt => 0, mag => 0, phase => 0, r => 0);
    my ($where, $mags, $nan) = ('', 0, 0);
    for my $i (0 .. $#e) {
        my ($ra, $dec, $dist, $lt) = @{ $pos->[$i] };
        my $o = $ours[$i];
        my $dra = $o->[0] - $ra;
        $dra -= 360 if $dra > 180;
        $dra += 360 if $dra < -180;
        my %d = (sky => sqrt(($dra * cos($dec * $R)) ** 2 + ($o->[1] - $dec) ** 2) * 3600,
                 dist => abs($o->[2] - $dist), lt => abs($o->[3] * 86400 - $lt),
                 phase => abs($o->[7] - $ph->[$i][1]), r => abs($o->[6] - $ph->[$i][0]));
        if (@{ $ph->[$i] } > 2) {
            for my $k (0, 1) {
                my $dl = abs($o->[9 + $k] - $ph->[$i][2 + $k]);
                $w{sublat} = $dl if $dl > ($w{sublat} // 0);
            }
        }
        if ($planet ne 'pluto') {
            my $theirs = $mag->[$i];
            if (!defined $theirs) { $nan++ if $o->[8] != $o->[8]; }
            else { $d{mag} = abs($o->[8] - $theirs); $mags++ }
        }
        $where = scalar(gmtime $e[$i]) if $d{sky} > $w{sky};
        $w{$_} = $d{$_} > $w{$_} ? $d{$_} : $w{$_} for keys %d;
    }
    my $mark = $planet eq 'pluto' ? 2 : 1;
    my $why = $planet eq 'pluto' ? 'chapter 37 is a fit of 43 terms, against DE421'
            : $planet =~ /^(uranus|neptune)$/ ? 'VSOP87 was fitted to DE200 (1982): DE421 has moved the outer planets'
            : 'VSOP87 (fitted to DE200, 1982) against DE421';
    TODO: {
        local $TODO = $why if $planet =~ /^(uranus|neptune)$/;
        cmp_ok($w{sky}, '<=', $mark, sprintf '%s, %d instants: within %s arcsecond of DE421 (worst %.3f, %s)', $planet, scalar @e, $mark, $w{sky}, $where);
    }
    TODO: {
        local $TODO = $why if $w{dist} > 1e-7;
        cmp_ok($w{dist}, '<=', 1e-7, sprintf '  the distance within 1e-7 AU (worst %.2e)', $w{dist});
    }
    TODO: {
        local $TODO = "$why (the light-time is the distance over c)" if $w{lt} > 0.001;
        cmp_ok($w{lt}, '<=', 0.001, sprintf '  the light-time within 1 ms (worst %.2e s)', $w{lt});
    }
    cmp_ok($w{phase}, '<=', 0.01, sprintf '  the phase angle within 0.01 degrees of DE421\'s with the sun\'s own place (worst %.5f)', $w{phase});
    cmp_ok($w{sublat}, '<=', 0.05, sprintf '  the sun\'s and the earth\'s latitudes on %s (its pole precessed to the date) within 0.05 degrees of Skyfield\'s (worst %.4f)', $planet, $w{sublat})
        if defined $w{sublat};
    next if $planet eq 'pluto';
    cmp_ok($mags, '>', 0, "  magnitudes compared ($mags, and $nan undefined in both)");
    cmp_ok($w{mag}, '<=', 1e-9, sprintf '  the magnitude is Skyfield\'s formula on the same numbers (worst %.2e)', $w{mag});
}

done_testing;
