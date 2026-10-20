#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Sun;
use Time::Keeper::Moon;

# Tracks: every sample is what position gives at its instant, for the sun
# and for the moon, at places where the sun never sets, never rises, and on
# a day the clocks change; the count of samples; the limits.

sub utc { Time::Keeper->new(@_, zone => 'UTC') }

my %where = (
    London  => [51.5074, -0.1278, 'Europe/London', [2026, 10, 19]],
    DST     => [51.5074, -0.1278, 'Europe/London', [2026, 10, 25]],
    Tromso  => [69.6496, 18.9560, 'Europe/Oslo', [2026, 6, 21]],
    Quito   => [-0.1807, -78.4678, 'America/Guayaquil', [2026, 3, 20]],
    McMurdo => [-77.8463, 166.6683, 'Pacific/Auckland', [2026, 6, 21]],
);

for my $name (sort keys %where) {
    my ($lat, $lon, $zone, $ymd) = @{ $where{$name} };
    my $sun = Time::Keeper::Sun->new(latitude => $lat, longitude => $lon, zone => $zone);
    my $from = Time::Keeper->new(year => $ymd->[0], month => $ymd->[1], day => $ymd->[2], zone => $zone)->epoch - 3600;
    my $to = $from + 26 * 3600;
    my $st = $sun->track(from => $from, to => $to, step => 120);
    my $mt = Time::Keeper::Moon->track(from => $from, to => $to, step => 120, place => $sun);
    is(scalar @{ $st->{epoch} }, 781, "$name: 26 hours at 2 minutes is 781 samples");
    is(scalar @{ $mt->{$_} }, 781, "$name: the moon's $_ too") for qw(epoch altitude illumination sub_longitude);
    my ($worst_s, $worst_m, $ok_e) = (0, 0, 1);
    for my $k (0 .. 780) {
        my $e = $st->{epoch}[$k];
        $ok_e &&= $e == $from + 120 * $k && $mt->{epoch}[$k] == $e;
        my $p = $sun->position($e);
        my ($slat, $slon) = $sun->sub_point($e);
        for ([altitude => $p->{altitude}], [apparent_altitude => $p->{apparent_altitude}], [azimuth => $p->{azimuth}],
             [sub_latitude => $slat], [sub_longitude => $slon]) {
            my $d = abs($st->{ $_->[0] }[$k] - $_->[1]);
            $worst_s = $d if $d > $worst_s;
        }
        my $q = Time::Keeper::Moon->position($e, place => $sun);
        my ($mlat, $mlon) = Time::Keeper::Moon->sub_point($e);
        for ([altitude => $q->{altitude}], [apparent_altitude => $q->{apparent_altitude}], [azimuth => $q->{azimuth}],
             [distance => $q->{distance}], [illumination => Time::Keeper::Moon->illumination($e)],
             [sub_latitude => $mlat], [sub_longitude => $mlon]) {
            my $d = abs($mt->{ $_->[0] }[$k] - $_->[1]);
            $worst_m = $d if $d > $worst_m;
        }
    }
    ok($ok_e, "$name: the epochs are from plus whole steps");
    cmp_ok($worst_s, '<=', 1e-9, "$name: every sun sample is position and sub_point at its instant (worst $worst_s)");
    cmp_ok($worst_m, '<=', 1e-9, "$name: every moon sample is position, illumination and sub_point (worst $worst_m)");
}

# The kinds of day the places were chosen for, read from the tracks.
{
    my $t = Time::Keeper::Sun->new(latitude => 69.6496, longitude => 18.9560, zone => 'Europe/Oslo');
    my $tr = $t->track(from => utc(year => 2026, month => 6, day => 21), to => utc(year => 2026, month => 6, day => 22));
    ok(!(grep { $_ < 0 } @{ $tr->{altitude} }), 'Tromso at midsummer: the sun never goes down');
    my $m = Time::Keeper::Sun->new(latitude => -77.8463, longitude => 166.6683, zone => 'Pacific/Auckland');
    $tr = $m->track(from => utc(year => 2026, month => 6, day => 21), to => utc(year => 2026, month => 6, day => 22));
    ok(!(grep { $_ > 0 } @{ $tr->{altitude} }), 'McMurdo at midwinter: it never comes up');
    is(scalar @{ $tr->{epoch} }, 1441, 'and the step is a minute unless given');
}

# ---- the shape --------------------------------------------------------------

{
    my $sun = Time::Keeper::Sun->new(place => 'Europe/London');
    my $t0 = utc(year => 2026, month => 10, day => 19);
    my $tr = $sun->track(from => $t0, to => $t0->epoch + 600, step => 120);
    is_deeply([sort keys %$tr], [qw(altitude apparent_altitude azimuth epoch sub_latitude sub_longitude)], 'the sun track\'s keys');
    is_deeply($tr->{epoch}, [map { $t0->epoch + 120 * $_ } 0 .. 5], 'both ends in when the span is whole steps');
    $tr = $sun->track(from => $t0, to => $t0->epoch + 599, step => 120);
    is(scalar @{ $tr->{epoch} }, 5, 'the end left out when it is not');
    $tr = $sun->track(from => $t0->epoch + 0.25, to => $t0->epoch + 240, step => 120);
    is_deeply($tr->{epoch}, [$t0->epoch + 0.25, $t0->epoch + 120.25], 'a fraction of a second in from is kept in every epoch');
    ok(abs($tr->{altitude}[1] - $sun->position($t0->epoch + 120.25)->{altitude}) <= 1e-9, 'and in the instant computed');
    my $mt = Time::Keeper::Moon->track(from => $t0, to => $t0->epoch + 600);
    is_deeply([sort keys %$mt], [qw(bright_limb distance epoch illumination sub_latitude sub_longitude)], 'the moon with no place: no altitude, azimuth or parallactic angle');
    $mt = Time::Keeper::Moon->track(from => $t0, to => $t0->epoch + 600, place => $sun);
    is_deeply([sort keys %$mt], [qw(altitude apparent_altitude azimuth bright_limb distance epoch illumination parallactic_angle sub_latitude sub_longitude)], 'with one, all three');
    is(scalar @{ $sun->track(from => $t0, to => $t0->epoch + 19999 * 60)->{epoch} }, 20000, '20,000 samples is the most');
    is(scalar @{ $sun->track(from => $t0, to => $t0->epoch + 86400, step => 86400)->{epoch} }, 2, 'a step of a day');
}

# ---- the limits ---------------------------------------------------------------

{
    my $sun = Time::Keeper::Sun->new(place => 'Europe/London');
    my $t0 = utc(year => 2026, month => 10, day => 19)->epoch;
    my @cases = (
        [[from => $t0, to => $t0 + 60, step => 0],        qr/track: step must be a whole number of seconds from 1 to 86400/, 'a step of 0'],
        [[from => $t0, to => $t0 + 60, step => 1.5],      qr/track: step must be a whole number of seconds/, 'a fraction of a second'],
        [[from => $t0, to => $t0 + 60, step => 86401],    qr/track: step must be a whole number of seconds from 1 to 86400/, 'more than a day'],
        [[from => $t0, to => $t0 + 60, step => -60],      qr/track: step must be a whole number/, 'a negative step'],
        [[from => $t0, to => $t0 + 60, step => 'often'],  qr/track: step must be a number of seconds/, 'a word'],
        [[from => $t0, to => $t0 + 60, step => undef],    qr/track: step must be a number of seconds/, 'undef'],
        [[from => $t0, to => $t0],                        qr/track: to must be after from/, 'no span'],
        [[from => $t0, to => $t0 - 60],                   qr/track: to must be after from/, 'a span backwards'],
        [[from => $t0, to => $t0 + 20000 * 60],           qr/track: 20001 samples is more than 20000/, 'too many samples'],
        [[to => $t0 + 60],                                qr/track needs from =>/, 'no from'],
        [[from => $t0],                                   qr/track needs to =>/, 'no to'],
        [[from => $t0, to => $t0 + 60, place => $sun],    qr/track: unknown argument 'place'/, 'place on the sun\'s'],
        [[from => $t0, to => $t0 + 60, 'step'],           qr/track takes name and value pairs/, 'an odd list'],
        [[from => 'soon', to => $t0 + 60],                qr/track: 'soon' is neither a Time::Keeper value nor an epoch/, 'a word for from'],
        [[from => utc(year => 3001, month => 1, day => 1), to => utc(year => 3001, month => 1, day => 2)],
                                                          qr/track: the year 3001 is outside/, 'a year out of range'],
        [[from => utc(year => 3000, month => 12, day => 31), to => utc(year => 3001, month => 1, day => 2)],
                                                          qr/track: the year 3001 is outside/, 'an end out of range'],
    );
    for my $c (@cases) {
        my ($args, $re, $what) = @$c;
        ok(!eval { $sun->track(@$args); 1 }, "dies: $what");
        like($@, $re, "  with its message");
    }
    ok(!eval { Time::Keeper::Sun->track(from => $t0, to => $t0 + 60); 1 }, 'the sun\'s track needs a place');
    like($@, qr/track: not a Time::Keeper::Sun place/, '  and says so');
    ok(!eval { Time::Keeper::Moon->track(from => $t0, to => $t0 + 60, place => 'London'); 1 }, 'the moon\'s place must be one');
    like($@, qr/Time::Keeper::Moon->track: not a Time::Keeper::Sun place/, '  and says so');
    ok(!eval { Time::Keeper::Moon->track(from => $t0, to => $t0 + 60, zone => 'UTC'); 1 }, 'the moon\'s track takes no zone');
    like($@, qr/Time::Keeper::Moon->track: unknown argument 'zone'/, '  and names it');
}

# ---- magical arguments --------------------------------------------------------

{
    package Tied;
    sub TIESCALAR { my ($c, $v) = @_; bless \$v, $c }
    sub FETCH { ${ $_[0] } }
}
{
    my $sun = Time::Keeper::Sun->new(place => 'Europe/London');
    my $t0 = utc(year => 2026, month => 10, day => 19)->epoch;
    tie my $from, 'Tied', $t0;
    tie my $to, 'Tied', $t0 + 600;
    tie my $step, 'Tied', 300;
    tie my $key, 'Tied', 'step';
    my $tr = $sun->track(from => $from, to => $to, $key => $step);
    is_deeply($tr->{epoch}, [$t0, $t0 + 300, $t0 + 600], 'tied from, to, step and a tied key are read');
    my $s = "x${t0}y";
    $tr = $sun->track(from => substr($s, 1, -1), to => $t0 + 120, step => substr('120', 0));
    is(scalar @{ $tr->{epoch} }, 2, 'substr values are read');
    my $mt = Time::Keeper::Moon->track(from => $from, to => $to, step => $step);
    is(scalar @{ $mt->{epoch} }, 3, 'and by the moon\'s');
}

done_testing;
