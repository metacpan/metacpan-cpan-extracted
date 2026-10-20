#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
BEGIN { require './xt/skyfield_oracle.pl' }
use Time::Keeper;
use Time::Keeper::Sky;
use Time::Keeper::Star;

# Author test: the stars' rises, sets and transits against Skyfield and
# DE421 (set TKS_SKYFIELD and TKS_SKYFIELD_DATA as for xt/04), its Star made
# from the same catalogue numbers, at the same horizon (a point's 34
# arcminutes). The marks, set in plan_time_keeper_sky/09 before any number
# was seen, are the planets': within 5 s below 60 degrees of latitude (120 s
# above), every count the same.

my $why = SkyfieldOracle::usable();
plan skip_all => $why if $why;

my @places = (
    ['London', 51.5074, -0.1278, 'Europe/London'],     ['Tromso', 69.6496, 18.9560, 'Europe/Oslo'],
    ['Reykjavik', 64.1466, -21.9426, 'Atlantic/Reykjavik'], ['Quito', -0.1807, -78.4678, 'America/Guayaquil'],
    ['Singapore', 1.3521, 103.8198, 'Asia/Singapore'], ['Sydney', -33.8688, 151.2093, 'Australia/Sydney'],
    ['Cape Town', -33.9249, 18.4241, 'Africa/Johannesburg'], ['Denver', 39.7392, -104.9903, 'America/Denver'],
    ['Tokyo', 35.6762, 139.6503, 'Asia/Tokyo'],         ['Ushuaia', -54.8019, -68.3030, 'America/Argentina/Ushuaia'],
    ['Honolulu', 21.3069, -157.8583, 'Pacific/Honolulu'], ['Delhi', 28.6139, 77.2090, 'Asia/Kolkata'],
);
my @dates = ([2026, 3, 20], [2026, 6, 21], [2026, 10, 19], [2026, 12, 21]);
my @stars = (Time::Keeper::Star->brighter_than(1.0), 'Polaris', 'Deneb', 'Fomalhaut');

my (@rows, @jobs);
for my $p (@places) {
    my ($name, $lat, $lon, $zone) = @$p;
    my $sky = Time::Keeper::Sky->new(latitude => $lat, longitude => $lon, zone => $zone);
    for my $d (@dates) {
        for my $star (@stars) {
            my $day = Time::Keeper::Star->on(Time::Keeper->new(year => $d->[0], month => $d->[1], day => $d->[2], hour => 12, zone => $zone), $star, place => $sky);
            my $f = Time::Keeper::Star->find($star);
            push @rows, [$name, "@$d", $lat, $day->body, $day];
            push @jobs, { kind => 'events', body => 'star', lat => $lat, lon => $lon, start => $day->start->epoch, end => $day->end->epoch,
                          ra => $f->{right_ascension} + 0, dec => $f->{declination} + 0, pmra => $f->{proper_motion_ra} + 0,
                          pmdec => $f->{proper_motion_dec} + 0, plx => $f->{parallax} + 0, rv => $f->{radial_velocity} + 0 };
        }
    }
}
my $answers = SkyfieldOracle::ask(\@jobs);
my ($n, $worst, $worst_hi, $where) = (0, 0, 0, '');
for my $i (0 .. $#rows) {
    my ($name, $date, $lat, $star, $day) = @{ $rows[$i] };
    my %theirs;
    push @{ $theirs{ $_->[0] } }, $_->[1] for @{ $answers->[$i] };
    for my $kind (qw(rise set transit)) {
        my $method = "${kind}s";
        my @ours = map { $_->epoch } $day->$method;
        my @sky = @{ $theirs{$kind} || [] };
        is(scalar @ours, scalar @sky, "$name $date $star: " . scalar(@sky) . " $kind");
        my $mark = abs($lat) > 60 ? 120 : 5;
        for my $j (0 .. $#sky) {
            next unless defined $ours[$j];
            my $d = abs($ours[$j] - $sky[$j]);
            cmp_ok($d, '<=', $mark, "  within $mark s ($d)");
            if (abs($lat) > 60) { $worst_hi = $d if $d > $worst_hi }
            elsif ($d > $worst) { ($worst, $where) = ($d, "$name $date $star $kind") }
            $n++;
        }
    }
    my $none = !@{ $theirs{rise} || [] } && !@{ $theirs{set} || [] };
    ok(!$none || $day->is_up_all_day || $day->is_down_all_day, "  neither a rise nor a set: up or down all day") if $none;
}
note(sprintf 'star events: %d compared; worst below 60 degrees %.1f s (%s), above %.1f s', $n, $worst, $where, $worst_hi);

done_testing;
