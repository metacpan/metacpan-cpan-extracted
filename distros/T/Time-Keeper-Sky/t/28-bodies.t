#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Sky;
use Time::Keeper::Moon;
use Time::Keeper::Planet;
use Time::Keeper::Star;

# Any body by name from a Sky: position, track and on hand the moon, a
# planet or a star to its own class with place => the Sky, and give the
# same answers; the sun's are the Sky's own. A star's rise, set and transit:
# its centre at the planets' horizon (34 arcminutes) at a rise or set, on
# the meridian at a transit, a sidereal day (3 m 56 s short of a day) to the
# next; circumpolar and never-rising stars say so.

my $london = Time::Keeper::Sky->new(place => 'Europe/London');
my $sydney = Time::Keeper::Sky->new(place => 'Australia/Sydney');
my $t = Time::Keeper->new(year => 2026, month => 10, day => 19, hour => 21, zone => 'Europe/London');

# ---- position, track and on by name -----------------------------------------------------

is_deeply($london->position('sun', $t), $london->position($t), 'position: the sun by name is the Sky\'s own');
is_deeply($london->position('sun', $t, precise => 1), $london->position($t, precise => 1), '  with precise =>');
is_deeply($london->position('moon', $t), Time::Keeper::Moon->position($t, place => $london), 'the moon\'s is Moon->position with place =>');
is_deeply($london->position('jupiter', $t), Time::Keeper::Planet->position('jupiter', $t, place => $london), 'a planet\'s is Planet->position');
is_deeply($london->position('Jupiter', $t), $london->position('jupiter', $t), '  its name in any case');
is_deeply($london->position('Sirius', $t), Time::Keeper::Star->position('Sirius', $t, place => $london), 'a star\'s is Star->position');
is_deeply($london->position('alpha CMa', $t), $london->position('Sirius', $t), '  by designation');
is_deeply($london->position('HR 2491', $t), $london->position('Sirius', $t), '  by HR number');
is_deeply($london->position(2491, $t), $london->position('Sirius', $t), '  or the number alone');
ok(defined $london->position('pluto', $t)->{altitude}, 'pluto is a planet');

my %span = (from => $t, to => $t->epoch + 3600, step => 600);
is_deeply($london->track('sun', %span), $london->track(%span), 'track: the sun by name');
is_deeply($london->track('moon', %span), Time::Keeper::Moon->track(%span, place => $london), 'the moon');
is_deeply($london->track('venus', %span), Time::Keeper::Planet->track('venus', %span, place => $london), 'a planet');
is_deeply($london->track('Vega', %span), Time::Keeper::Star->track('Vega', %span, place => $london), 'a star');

my $date = $t->to_date;
isa_ok($london->on($date, 'sun'), 'Time::Keeper::Sun::Day', 'on: the sun\'s day');
is($london->on($date, 'sun')->sunrise->epoch, $london->on($date)->sunrise->epoch, '  the Sky\'s own');
{
    my $march = Time::Keeper->new(year => 2026, month => 3, day => 1, hour => 12, zone => 'Europe/London');
    is($london->on($march, 'sun')->sunrise->epoch, $london->on($march)->sunrise->epoch, '  on its date, not today');
    is($london->on($march->to_date, 'moon')->date . '', '2026-03-01', '  the moon\'s too');
}
isa_ok($london->on($date, 'moon'), 'Time::Keeper::Moon::Day', 'the moon\'s');
is($london->on($date, 'moon')->moonrise->epoch, Time::Keeper::Moon->on($date, place => $london)->moonrise->epoch, '  Moon->on\'s');
isa_ok($london->on($date, 'saturn'), 'Time::Keeper::Planet::Day', 'a planet\'s');
isa_ok($london->on($date, 'saturn'), 'Time::Keeper::Body::Day', '  which is a Body::Day');
is($london->on($t, 'saturn')->rise->epoch, Time::Keeper::Planet->on($t, 'saturn', place => $london)->rise->epoch, '  Planet->on\'s, from a value too');
isa_ok($london->on($date, 'Arcturus'), 'Time::Keeper::Star::Day', 'a star\'s');
isa_ok($london->on($date, 'Arcturus'), 'Time::Keeper::Body::Day', '  which is a Body::Day');
isa_ok($london->on('moon'), 'Time::Keeper::Moon::Day', 'on with a body alone: today\'s');
isa_ok($london->on('sun'), 'Time::Keeper::Sun::Day', '  the sun\'s too');

# ---- a star's day -------------------------------------------------------------------------

sub alt_at { my ($sky, $star, $v) = @_; Time::Keeper::Star->position($star, $v, place => $sky)->{altitude} }

{
    my $d = Time::Keeper::Star->on($date, 'Sirius', place => $london);
    is($d->body, 'Sirius', 'Star::Day body is the star\'s name');
    is($d->hr, 2491, '  hr its number');
    is($d->date . '', $date . '', '  date the date');
    is($d->zone_name, 'Europe/London', '  zone_name the place\'s');
    my %ev = map { $_->[0] => $_->[1] } $d->events;
    is_deeply([sort keys %ev], [qw(rise set transit)], 'Sirius rises, transits and sets from London on 19 October');
    cmp_ok(abs(alt_at($london, 'Sirius', $d->rise) + 34 / 60), '<', 0.01, '  its centre 34 arcminutes down at the rise');
    cmp_ok(abs(alt_at($london, 'Sirius', $d->set) + 34 / 60), '<', 0.01, '  and at the set');
    my $h = Time::Keeper::Star->position('Sirius', $d->transit, place => $london)->{hour_angle};
    cmp_ok(abs($h), '<', 0.01, '  on the meridian at the transit');
    ok($d->rise->epoch < $d->transit->epoch && $d->transit->epoch < $d->set->epoch, '  rise, transit, set in order');
    is(Time::Keeper::Star->next_rise('Sirius', $d->rise->epoch - 60, place => $london)->epoch, $d->rise->epoch, 'next_rise from a minute before is the day\'s rise');
    is(Time::Keeper::Star->previous_set('Sirius', $d->set->epoch + 60, place => $london)->epoch, $d->set->epoch, 'previous_set from a minute after is its set');
    is(Time::Keeper::Star->next_transit('Sirius', $d->transit->epoch - 60, place => $london)->epoch, $d->transit->epoch, 'next_transit');
    is(Time::Keeper::Star->previous_transit('Sirius', $d->transit->epoch + 60, place => $london)->epoch, $d->transit->epoch, 'previous_transit');
    my $nt = Time::Keeper::Star->next_transit('Sirius', $d->transit->epoch + 60, place => $london)->epoch - $d->transit->epoch;
    cmp_ok(abs($nt - 86164), '<=', 2, "  next_transit from just after one is a sidereal day on ($nt s)");
    my $pt = $d->transit->epoch - Time::Keeper::Star->previous_transit('Sirius', $d->transit->epoch - 60, place => $london)->epoch;
    cmp_ok(abs($pt - 86164), '<=', 2, "  previous_transit from just before one a sidereal day back ($pt s)");
    my $next = Time::Keeper::Star->next_rise('Sirius', $d->rise, place => $london);
    cmp_ok(abs(($next->epoch - $d->rise->epoch) - 86164), '<=', 3, '  the next rise a sidereal day on (' . ($next->epoch - $d->rise->epoch) . ' s)');
    my $prev = Time::Keeper::Star->previous_rise('Sirius', $d->rise, place => $london);
    cmp_ok(abs(($d->rise->epoch - $prev->epoch) - 86164), '<=', 3, '  the previous a sidereal day back');
    is(Time::Keeper::Star->next_set('Sirius', $d->rise, place => $london)->epoch, $d->set->epoch, 'next_set after the rise is the day\'s set');
    is($london->on($date, 'Sirius')->rise->epoch, $d->rise->epoch, 'the Sky\'s on gives the same day');
}

{
    my $d = Time::Keeper::Star->on($date, 'Polaris', place => $london);
    ok($d->is_up_all_day && !$d->is_down_all_day, 'Polaris is up all day from London');
    ok(!defined $d->rise && !defined $d->set, '  no rise, no set');
    is(scalar(my @t = $d->transits), 1, '  one transit');
    ok(!defined Time::Keeper::Star->next_rise('Polaris', $t, place => $london), '  next_rise is undef');
    ok(!defined Time::Keeper::Star->previous_set('Polaris', $t, place => $london), '  previous_set too');
    my $c = Time::Keeper::Star->on($date, 'Canopus', place => $london);
    ok($c->is_down_all_day && !$c->is_up_all_day, 'Canopus never rises over London');
    ok(!defined Time::Keeper::Star->next_rise('Canopus', $t, place => $london), '  next_rise is undef');
    my $s = Time::Keeper::Star->on($date, 'alpha Cru', place => $sydney);
    ok($s->is_up_all_day, 'Acrux never sets over Sydney');
    my $two;
    for my $day (1 .. 31) {
        my $dd = Time::Keeper::Star->on(Time::Keeper->new(year => 2026, month => 7, day => $day, hour => 12, zone => 'Europe/London'), 'Vega', place => $london);
        $two++ if scalar(my @x = $dd->transits) == 2;
    }
    ok($two, 'a civil day can hold two transits of a star (Vega from London in July, when it transits at midnight)');
}

{
    # a star's day from Sydney has a rise and a set in local time
    my $d = $sydney->on(Time::Keeper->new(year => 2026, month => 3, day => 1, hour => 12, zone => 'Australia/Sydney'), 'Rigel');
    like($d->rise . '', qr/\+11:00$/, 'a star\'s values are in the place\'s zone');
    is($d->start . '', '2026-03-01T00:00:00+11:00', '  start');
    is($d->end . '', '2026-03-02T00:00:00+11:00', '  end');
    isa_ok($d->place, 'Time::Keeper::Sky', '  place');
    is($d->place->latitude, $sydney->latitude, '  the Sky it was asked from');
}

# ---- refusals -------------------------------------------------------------------------

{
    for ([sub { $london->position('vulcan', $t) }, qr/^position takes an instant and then name and value pairs, or a body first: no body is called 'vulcan'/],
         [sub { $london->position('earth', $t) }, qr/no body is called 'earth'/],
         [sub { $london->position($t, 'x') }, qr/^position takes an instant and then name and value pairs, or a body first/],
         [sub { $london->track('nothing', from => $t, to => $t, step => 60) }, qr/^track takes name and value pairs: from, to, step, or a body first: no body is called 'nothing'/],
         [sub { $london->track(from => $t, 'to') }, qr/^track takes name and value pairs/],
         [sub { $london->on($date, 'vulcan') }, qr/^on takes .*, or a body first: no body is called 'vulcan'/],
         [sub { $london->on('2026-10-19') }, qr/^on takes a Time::Keeper::Date, a Time::Keeper value, or year, month and day, or a body first/],
         [sub { $london->position('moon', $t, colour => 1) }, qr/Moon->position: unknown argument 'colour'/],
         [sub { Time::Keeper::Star->on($date, 'Sirius') }, qr/Star->on needs place =>/],
         [sub { Time::Keeper::Star->on($date, 'Nostar', place => $london) }, qr/no star is known as 'Nostar'/],
         [sub { Time::Keeper::Star->on('x', 'Sirius', place => $london) }, qr/Star->on takes a Time::Keeper::Date or a Time::Keeper value/],
         [sub { Time::Keeper::Star->next_rise('Sirius', $t) }, qr/Star->next_rise needs place =>/],
         [sub { Time::Keeper::Star->next_set('Sirius', $t, place => $london, colour => 1) }, qr/Star->next_set: unknown argument 'colour'/],
         [sub { Time::Keeper::Star::Day::hr($london->on($date, 'venus')) }, qr/^hr: not a Time::Keeper::Star::Day/],
         [sub { Time::Keeper::Planet::Day::planet($london->on($date, 'Vega')) }, qr/^planet: not a Time::Keeper::Planet::Day/],
         [sub { Time::Keeper::Body::Day::rise($london->on($date)) }, qr/^rise: not a Time::Keeper::Planet::Day or Time::Keeper::Star::Day/]) {
        my ($code, $re) = @$_;
        ok(!eval { $code->(); 1 }, "dies: $re");
        like($@, $re, '  with its message');
    }
}

done_testing;
