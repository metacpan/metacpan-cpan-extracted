#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
BEGIN { require './xt/skyfield_oracle.pl' }
use Time::Keeper;
use Time::Keeper::Sun;

# Author test: crossings of golden hour's two altitudes, 6 degrees up and 4
# down, against Skyfield's risings and settings at those horizons (DE421;
# set TKS_SKYFIELD and TKS_SKYFIELD_DATA as for xt/04). Twelve places, four
# dates. The mark, set in plan_lnation_sun_moon/02 before any number was
# seen: 5 seconds below 60 degrees of latitude; 0.01's band of 120 seconds
# above, where the sun crosses slowly.

my $why = SkyfieldOracle::usable();
plan skip_all => $why if $why;

my @places = (
    ['London', 51.5074, -0.1278, 'Europe/London'],
    ['Tromso', 69.6496, 18.9560, 'Europe/Oslo'],
    ['Reykjavik', 64.1466, -21.9426, 'Atlantic/Reykjavik'],
    ['Quito', -0.1807, -78.4678, 'America/Guayaquil'],
    ['Singapore', 1.3521, 103.8198, 'Asia/Singapore'],
    ['Sydney', -33.8688, 151.2093, 'Australia/Sydney'],
    ['Cape Town', -33.9249, 18.4241, 'Africa/Johannesburg'],
    ['Denver', 39.7392, -104.9903, 'America/Denver'],
    ['Tokyo', 35.6762, 139.6503, 'Asia/Tokyo'],
    ['Ushuaia', -54.8019, -68.3030, 'America/Argentina/Ushuaia'],
    ['Honolulu', 21.3069, -157.8583, 'Pacific/Honolulu'],
    ['Delhi', 28.6139, 77.2090, 'Asia/Kolkata'],
);
my @dates = ([2026, 3, 20], [2026, 6, 21], [2026, 10, 19], [2026, 12, 21]);

my (@rows, @jobs);
for my $p (@places) {
    my ($name, $lat, $lon, $zone) = @$p;
    my $sun = Time::Keeper::Sun->new(latitude => $lat, longitude => $lon, zone => $zone);
    for my $d (@dates) {
        my $day = $sun->on(year => $d->[0], month => $d->[1], day => $d->[2]);
        for my $alt (6, -4) {
            push @rows, [$name, "@$d", $lat, $alt, [$day->crossings(altitude => $alt)]];
            push @jobs, { kind => 'crossings', lat => $lat, lon => $lon, altitude => $alt,
                          start => $day->start->epoch, end => $day->end->epoch };
        }
    }
}

my $answers = SkyfieldOracle::ask(\@jobs);
my ($worst, $where, $n) = (0, '', 0);
for my $i (0 .. $#rows) {
    my ($name, $date, $lat, $alt, $ours) = @{ $rows[$i] };
    my @sky = @{ $answers->[$i] };
    is(scalar @$ours, scalar @sky, "$name $date, $alt degrees: " . scalar(@sky) . " crossings");
    my $mark = abs($lat) > 60 ? 120 : 5;
    for my $j (0 .. $#sky) {
        next unless $ours->[$j];
        is($ours->[$j][1], $sky[$j][0], "  $sky[$j][0]");
        my $d = abs($ours->[$j][0]->epoch - $sky[$j][1]);
        cmp_ok($d, '<=', $mark, "  within $mark s ($d)");
        ($worst, $where) = ($d, "$name $date $alt") if $d > $worst && abs($lat) <= 60;
        $n++;
    }
}
note(sprintf 'worst below 60 degrees: %.1f s (%s), of %d crossings', $worst, $where, $n);

done_testing;
