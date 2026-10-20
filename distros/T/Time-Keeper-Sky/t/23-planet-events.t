#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Sky;
use Time::Keeper::Planet;

# The planets' events, each checked by what defines it: at a rise or a set
# the planet's centre is 34 arcminutes down, at a transit its hour angle is
# 0; at a conjunction its longitude is the sun's, at an opposition opposite;
# a greatest elongation is a maximum and a station a turn of the motion; a
# closest approach a minimum. Then the days at the poles, the searches, and
# the refusals.

sub near { my ($got, $want, $tol, $name) = @_; cmp_ok(abs($got - $want), '<=', $tol, "$name: $got within $tol of $want") }
sub utc { Time::Keeper->new(@_, zone => 'UTC') }
sub wrap { my $d = $_[0] - 360 * int($_[0] / 360); $d -= 360 if $d > 180; $d += 360 if $d <= -180; $d }

my $t = utc(year => 2026, month => 10, day => 19);

# ---- rise, set, transit ----------------------------------------------------------------

{
    # Half a second of rounding, at a planet's fastest vertical motion
    # (0.0042 degrees a second at the equator), is 0.0021 degrees.
    my ($n, $worst_alt, $worst_h) = (0, 0, 0);
    for my $where (['Europe/London'], ['Australia/Sydney'], ['America/Denver'], ['Asia/Singapore']) {
        my $sky = Time::Keeper::Sky->new(place => $where->[0]);
        for my $day (0, 50, 100) {
            for my $planet (Time::Keeper::Planet->planets) {
                my $d = Time::Keeper::Planet->on(Time::Keeper->from_epoch($t->epoch + $day * 86400, zone => $where->[0]), $planet, place => $sky);
                for my $r ($d->rises, $d->sets) {
                    my $p = Time::Keeper::Planet->position($planet, $r, place => $sky);
                    my $x = abs($p->{altitude} + 34 / 60);
                    $worst_alt = $x if $x > $worst_alt;
                    $n++;
                }
                for my $tr ($d->transits) {
                    my $h = abs(Time::Keeper::Planet->position($planet, $tr, place => $sky)->{hour_angle});
                    $worst_h = $h if $h > $worst_h;
                }
                my @e = map { $_->[1]->epoch } $d->events;
                ok(!grep({ $e[$_] < $e[$_ - 1] } 1 .. $#e), "$where->[0] +$day $planet: the events in order") if $day == 0;
            }
        }
    }
    cmp_ok($n, '>', 150, "rises and sets checked ($n)");
    cmp_ok($worst_alt, '<=', 0.0022, "at each the centre is 34 arcminutes down (worst $worst_alt)");
    cmp_ok($worst_h, '<=', 0.0022, "at each transit the hour angle is 0 (worst $worst_h)");
}

{
    my $lyr = Time::Keeper::Sky->new(latitude => 78.2232, longitude => 15.6267, zone => 'Arctic/Longyearbyen');
    my $mars = Time::Keeper::Planet->on($t, 'mars', place => $lyr);
    ok($mars->is_up_all_day && !$mars->rise && !$mars->set, 'Longyearbyen, October 2026: Mars (declination +18) never sets');
    my $venus = Time::Keeper::Planet->on($t, 'venus', place => $lyr);
    ok($venus->is_down_all_day && !$venus->is_up_all_day, '  and Venus (-19) never rises');
    ok(defined $mars->transit, '  Mars still transits');

    my $sky = Time::Keeper::Sky->new(place => 'Europe/London');
    my $d = Time::Keeper::Planet->on($t, 'jupiter', place => $sky);
    is($d->planet, 'jupiter', 'the day knows its planet');
    is($d->zone_name, 'Europe/London', '  and its zone');
    is($d->date->epoch_days, Time::Keeper::Date->new(year => 2026, month => 10, day => 19)->epoch_days, '  its date');
    is($d->start->epoch, Time::Keeper->new(year => 2026, month => 10, day => 19, zone => 'Europe/London')->epoch, '  its first moment');
    ok($d->place->isa('Time::Keeper::Sky'), '  and its place');
    my $before = $d->start->epoch - 1;
    is(Time::Keeper::Planet->next_rise('jupiter', $before, place => $sky)->epoch, $d->rise->epoch, 'next_rise from the night before is the day\'s rise');
    is(Time::Keeper::Planet->next_transit('jupiter', $before, place => $sky)->epoch, $d->transit->epoch, 'and next_transit its transit');
    is(Time::Keeper::Planet->previous_set('jupiter', $d->end->epoch, place => $sky)->epoch, $d->set->epoch, 'previous_set from the end of the day is its set');
    is(Time::Keeper::Planet->previous_rise('jupiter', $d->rise->epoch + 1, place => $sky)->epoch, $d->rise->epoch, 'previous_rise just after a rise is that rise');
    like(Time::Keeper::Planet->next_set('jupiter', $before, place => $sky) . '', qr/\+01:00$/, 'in the place\'s zone');
}

# ---- configurations ---------------------------------------------------------------------

{
    my $jde = sub { Time::Keeper::Sun::_jde($_[0]) };
    my $dlon = sub {
        my ($planet, $v) = @_;
        my %ix = (mercury => 0, venus => 1, mars => 3, jupiter => 4, saturn => 5, uranus => 6, neptune => 7, pluto => 8);
        my (undef, undef, undef, undef, $lon) = Time::Keeper::Sun::_planet_jde($ix{$planet}, $jde->($v));
        my ($slon) = Time::Keeper::Sun::_sun_precise_jde($jde->($v));
        return wrap($lon - $slon);
    };
    for my $c ([qw(mars opposition 180)], [qw(jupiter opposition 180)], [qw(saturn conjunction 0)], [qw(neptune opposition 180)],
               [qw(pluto conjunction 0)], [qw(venus inferior_conjunction 0)], [qw(venus superior_conjunction 0)],
               [qw(mercury inferior_conjunction 0)], [qw(mercury superior_conjunction 0)]) {
        my ($planet, $event, $target) = @$c;
        my $v = Time::Keeper::Planet->next(event => $event, planet => $planet, after => $t);
        ok($v && $v->epoch > $t->epoch, "$planet: the next $event is after the instant ($v)");
        # the longitude difference moves at most 1.6 degrees a day (Mercury's
        # inferior conjunction): half a second is 1e-5
        near(abs(wrap($dlon->($planet, $v) - $target)), 0, 2e-5, "  the longitude difference is $target there");
        my $p = Time::Keeper::Planet->previous(event => $event, planet => $planet, before => $v->epoch + 3600);
        is($p->epoch, $v->epoch, '  and previous from an hour after finds it again');
    }
    my $inf = Time::Keeper::Planet->next(event => 'inferior_conjunction', planet => 'venus', after => $t);
    my $sup = Time::Keeper::Planet->next(event => 'superior_conjunction', planet => 'venus', after => $t);
    cmp_ok(Time::Keeper::Planet->position('venus', $inf)->{distance}, '<', 1, 'an inferior conjunction is on the near side');
    cmp_ok(Time::Keeper::Planet->position('venus', $sup)->{distance}, '>', 1, 'a superior one beyond the sun');
    is(Time::Keeper::Planet->next(event => 'conjunction', planet => 'venus', after => $t)->epoch, (sort { $a <=> $b } $inf->epoch, $sup->epoch)[0], 'conjunction is either, the nearer in time');

    for my $c ([qw(mercury greatest_elongation_east 1)], [qw(mercury greatest_elongation_west -1)], [qw(venus greatest_elongation_east 1)], [qw(venus greatest_elongation_west -1)]) {
        my ($planet, $event, $side) = @$c;
        my $v = Time::Keeper::Planet->next(event => $event, planet => $planet, after => $t);
        my $e = Time::Keeper::Planet->position($planet, $v)->{elongation};
        cmp_ok($e, '>', 17, "$planet $event ($v): $e degrees from the sun");
        cmp_ok($e, '>=', Time::Keeper::Planet->position($planet, $v->epoch + $_ * 43200)->{elongation}, "  more than half a day " . ($_ < 0 ? 'before' : 'after')) for -1, 1;
        ok(($dlon->($planet, $v) > 0) == ($side > 0), '  on the ' . ($side > 0 ? 'east' : 'west') . ' of the sun');
    }
    for my $c ([qw(mars station_retrograde)], [qw(mars station_direct)], [qw(mercury station_retrograde)], [qw(saturn station_direct)]) {
        my ($planet, $event) = @$c;
        my $v = Time::Keeper::Planet->next(event => $event, planet => $planet, after => $t);
        my $l = sub { Time::Keeper::Planet->position($planet, $_[0])->{longitude} };
        my $before = wrap($l->($v->epoch) - $l->($v->epoch - 2 * 86400));
        my $after  = wrap($l->($v->epoch + 2 * 86400) - $l->($v->epoch));
        if ($event eq 'station_retrograde') { ok($before > 0 && $after < 0, "$planet $event ($v): forward before, backward after") }
        else                                { ok($before < 0 && $after > 0, "$planet $event ($v): backward before, forward after") }
    }
    # Sought again from its own value, an event gives the next one, not itself:
    # the found instant is rounded to the second, and was once the same second.
    for my $c ([qw(mars station_retrograde)], [qw(mars opposition)], [qw(mercury station_direct)], [qw(venus superior_conjunction)], [qw(mercury greatest_elongation_east)], [qw(venus greatest_elongation_west)], [qw(neptune station_direct)]) {
        my ($planet, $event) = @$c;
        my $a = utc(year => 2020, month => 1, day => 1);
        my $ok = 1;
        for (1 .. 12) {
            my $v = Time::Keeper::Planet->next(event => $event, planet => $planet, after => $a);
            # an event's kind recurs months apart: a day apart is the same one twice
            $ok = 0, last unless $v && $v->epoch > $a->epoch + 86400;
            my $b = Time::Keeper::Planet->previous(event => $event, planet => $planet, before => $v);
            $ok = 0, last if $b && $b->epoch >= $v->epoch;
            $a = $v;
        }
        ok($ok, "$planet $event: next from its own value moves on, and previous from it moves back");
    }
    is(Time::Keeper::Planet->next(event => 'opposition', planet => 'mars', after => $t, place => Time::Keeper::Sky->new(place => 'Asia/Tokyo')) . '',
       Time::Keeper->from_epoch(Time::Keeper::Planet->next(event => 'opposition', planet => 'mars', after => $t)->epoch, zone => 'Asia/Tokyo') . '',
       'place => gives the value in the place\'s zone');
}

# ---- closest approach -------------------------------------------------------------------

{
    my $to = $t->epoch + 2 * 365 * 86400;
    my @a = Time::Keeper::Sky->closest_approach('venus', 'jupiter', from => $t, to => $to);
    cmp_ok(scalar @a, '>=', 2, 'Venus and Jupiter: some closest approaches in two years');
    for my $x (@a) {
        my $sep = sub { my $u = Time::Keeper::Planet->position('venus', $_[0]); my $v = Time::Keeper::Planet->position('jupiter', $_[0]);
                        my $R = atan2(1, 1) / 45; my $c = sin($u->{declination} * $R) * sin($v->{declination} * $R) + cos($u->{declination} * $R) * cos($v->{declination} * $R) * cos(($u->{right_ascension} - $v->{right_ascension}) * $R);
                        atan2(sqrt(1 - $c * $c), $c) / $R };
        near($x->[1], $sep->($x->[0]), 0.0002, "  $x->[0]: the separation is the positions'");
        cmp_ok($x->[1], '<=', $sep->($x->[0]->epoch + $_ * 7200), '  a minimum, two hours ' . ($_ < 0 ? 'before' : 'after')) for -1, 1;
    }
    my @g = Time::Keeper::Sky->closest_approach('moon', 'mars', from => $t, to => $t->epoch + 60 * 86400);
    my @l = Time::Keeper::Sky->closest_approach('moon', 'mars', from => $t, to => $t->epoch + 60 * 86400, place => Time::Keeper::Sky->new(place => 'Europe/London'));
    is(scalar @l, scalar @g, 'the moon and Mars: as many approaches from London as from the centre');
    ok(abs($l[0][1] - $g[0][1]) > 0.1, '  but the moon\'s parallax moves them');
    ok(!eval { Time::Keeper::Sky->closest_approach('venus', 'venus', from => $t, to => $to); 1 }, 'one body twice dies');
    like($@, qr/needs two different bodies/, '  saying so');
    ok(!eval { Time::Keeper::Sky->closest_approach('venus', 'earth', from => $t, to => $to); 1 }, 'the earth is not one');
    ok(!eval { Time::Keeper::Sky->closest_approach('venus', 'mars', from => $t, to => $t->epoch + 11 * 366 * 86400); 1 }, 'more than ten years dies');
    like($@, qr/a span of at most ten years/, '  saying so');
    ok(!eval { Time::Keeper::Sky->closest_approach('venus', 'mars', from => $t, to => $t->epoch - 1); 1 }, 'a span backwards dies');
    ok(!eval { Time::Keeper::Sky->closest_approach('venus', 'mars', to => $t); 1 }, 'from is needed');
}

# ---- refusals -------------------------------------------------------------------------------

{
    my $sky = Time::Keeper::Sky->new(place => 'Europe/London');
    for ([[event => 'opposition', planet => 'venus'], qr/venus has no opposition/],
         [[event => 'greatest_elongation_east', planet => 'mars'], qr/mars is an outer planet: it has no greatest_elongation_east/],
         [[event => 'inferior_conjunction', planet => 'jupiter'], qr/jupiter is an outer planet: it has no inferior_conjunction/],
         [[event => 'eclipse', planet => 'mars'], qr/no event is called 'eclipse'/],
         [[planet => 'mars'], qr/needs event =>/],
         [[event => 'opposition', planet => 'mars', before => $t], qr/unknown argument 'before'/],
         [[event => 'opposition'], qr/needs a planet's name/],
         [[event => 'opposition', planet => 'pluto', after => utc(year => 1880, month => 1, day => 1)], qr/Pluto's place is computed from 1885/]) {
        my ($args, $re) = @$_;
        ok(!eval { Time::Keeper::Planet->next(@$args); 1 }, "next(@$args) dies");
        like($@, $re, '  with its message');
    }
    ok(!eval { Time::Keeper::Planet->previous(event => 'opposition', planet => 'mars', after => $t); 1 }, 'previous takes before, not after');
    ok(!eval { Time::Keeper::Planet->on($t, 'mars'); 1 }, 'on needs a place');
    like($@, qr/on needs place =>/, '  saying so');
    ok(!eval { Time::Keeper::Planet->on($t, 'earth', place => $sky); 1 }, 'on: not the earth');
    ok(!eval { Time::Keeper::Planet->on(utc(year => 1884, month => 6, day => 1), 'pluto', place => $sky); 1 }, 'on: Pluto before 1885');
    ok(!eval { Time::Keeper::Planet->next_rise('mars', $t); 1 }, 'next_rise needs a place');
    like($@, qr/next_rise needs place =>/, '  saying so');
    ok(!eval { Time::Keeper::Body::Day::rise('x'); 1 }, 'a Day method on something else dies');
    like($@, qr/rise: not a Time::Keeper::Planet::Day/, '  by name');
}

done_testing;
