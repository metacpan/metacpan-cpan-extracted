#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
BEGIN { require './xt/skyfield_oracle.pl' }
use Time::Keeper;
use Time::Keeper::Sky;

# Author test: the sun from the VSOP87 earth (position with precise => 1)
# against Skyfield and DE421, every 37 days and an hour from 1900 to 2050,
# at the same TT, so the ephemerides are compared and Delta T is not. The
# mark, set in plan_time_keeper_sky/02 before any number was seen: 1
# arcsecond on the sky; and the chapter 25 sun stays the 0.01 degree it is.

my $why = SkyfieldOracle::usable();
plan skip_all => $why if $why;

my $sky = Time::Keeper::Sky->new(latitude => 0, longitude => 0);
my $from = Time::Keeper->new(year => 1900, month => 1, day => 1, zone => 'UTC')->epoch;
my $to = Time::Keeper->new(year => 2050, month => 1, day => 1, zone => 'UTC')->epoch;
my @e;
for (my $e = $from; $e < $to; $e += 37 * 86400 + 3917) { push @e, $e }
my $a = SkyfieldOracle::ask([map { { kind => 'sunpos', epoch => $_, jde => Time::Keeper::Sun::_jde($_) } } @e]);
my $R = atan2(1, 1) / 45;
my ($wp, $wc, $wd) = (0, 0, 0);
for my $i (0 .. $#e) {
    my ($ra, $dec, $dist) = @{ $a->[$i] };
    for my $precise (1, 0) {
        my $p = $sky->position($e[$i], precise => $precise);
        my $dra = $p->{right_ascension} - $ra;
        $dra -= 360 if $dra > 180;
        $dra += 360 if $dra < -180;
        my $sep = sqrt(($dra * cos($dec * $R)) ** 2 + ($p->{declination} - $dec) ** 2) * 3600;
        if ($precise) { $wp = $sep if $sep > $wp; $wd = abs($p->{distance} - $dist) if abs($p->{distance} - $dist) > $wd }
        else          { $wc = $sep if $sep > $wc }
    }
}
cmp_ok(scalar @e, '>', 1400, 'instants compared (' . scalar(@e) . ')');
cmp_ok($wp, '<=', 1, "precise => 1: within 1 arcsecond of DE421 (worst $wp)");
cmp_ok($wd, '<=', 1e-6, "  and the distance within 1e-6 AU (worst $wd)");
cmp_ok($wc, '<=', 36, "chapter 25: within its 0.01 degree (worst $wc arcseconds)");

done_testing;
