#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Sun;

# The days at the edges of polar day and polar night, where a civil day
# holds two sunsets or none and the singular and plural methods part; the
# search from an instant across them; a grazing horizon; the pole itself.
# The expected minutes are USNO's (t/usno-oneday.tsv).

sub near { my ($got, $want, $tol, $name) = @_; cmp_ok(abs($got - $want), '<=', $tol, "$name: $got within $tol of $want") }
sub local_minute { my ($v) = @_; $v->strftime('%Y-%m-%d %H:%M') }

my $utq = Time::Keeper::Sun->new(latitude => 71.2906, longitude => -156.7886, zone => 'America/Anchorage');
my $lyr = Time::Keeper::Sun->new(latitude => 78.2232, longitude => 15.6267, zone => 'Arctic/Longyearbyen');
my $mcm = Time::Keeper::Sun->new(latitude => -77.8419, longitude => 166.6863, zone => 'Antarctica/McMurdo');

# ---- Longyearbyen, 25 August 2026: two sunsets and one sunrise --------------------

{
    my $d = $lyr->on(year => 2026, month => 8, day => 25);
    my @sets = $d->sunsets;
    is(scalar @sets, 2, 'two sunsets in one civil day');
    like(local_minute($sets[0]), qr/^2026-08-25 00:(28|29|30)$/, 'the first at 00:29 (USNO)');
    like(local_minute($sets[1]), qr/^2026-08-25 23:5[5-7]$/, 'the second at 23:56 (USNO)');
    is("${\ $d->sunset }", "$sets[0]", 'the singular is the first');
    my @rises = $d->sunrises;
    is(scalar @rises, 1, 'one sunrise');
    like(local_minute($rises[0]), qr/^2026-08-25 01:3[2-4]$/, 'at 01:33 (USNO)');
    ok(!$d->is_polar_day && !$d->is_polar_night, 'not a polar day: it set');
    near($d->day_length->total('hours'), 22 + 23 / 60, 0.05, 'day_length runs from the sunrise to the sunset that follows it');
    my @ev = $d->events;
    is(join(' ', map { $_->[0] } grep { $_->[0] =~ /^sun/ } @ev), 'sunset sunrise sunset', 'events show the order');
    ok(!defined $d->dawn, 'no civil dawn: the sun never six degrees down');
}

# ---- Utqiagvik, the sun stops setting in May and starts in August -------------------

{
    my $d = $utq->on(year => 2026, month => 5, day => 10);
    like(local_minute($d->sunset), qr/^2026-05-10 01:4[7-9]$/, 'the last sunset of spring, 01:48');
    like(local_minute($d->sunrise), qr/^2026-05-10 02:5[7-9]$/, 'then a sunrise at 02:58');
    ok($d->sunset < $d->sunrise, 'the sunset comes before the sunrise in this civil day');
    ok(!defined $d->day_length, 'and the sun does not set again for months, so no day_length');
    ok(!$d->is_polar_day, 'not yet polar day');

    my $e = $utq->on(year => 2026, month => 5, day => 11);
    ok($e->is_polar_day, 'the next day the sun is up throughout');
    ok(!defined $e->sunrise && !defined $e->sunset, 'no events');
    is(scalar(my @x = $e->sunsets), 0, 'the plural is empty');
    like(local_minute($e->solar_midnight), qr/^2026-05-11 02:2[3-5]$/, 'the lower transit is still there, 02:24');
    is($e->day_length->total('hours'), 24, 'day_length is the whole day');
    ok(!defined $e->dawn, 'and no civil twilight');

    my $f = $utq->on(year => 2026, month => 8, day => 2);
    like(local_minute($f->sunset), qr/^2026-08-02 0(1:59|2:0[01])$/, 'the first sunset of August at 02:00');
    like(local_minute($f->sunrise), qr/^2026-08-02 03:0[7-9]$/, 'and a sunrise at 03:08');
    ok(!$f->is_polar_day, 'no longer polar day');
    ok(defined $f->day_length, 'the day has a length: the next sunset is the next day\'s');
    near($f->day_length->total('hours'), 22 + 34 / 60, 0.1, 'from 03:08 to the 3rd\'s 01:42');
}

# ---- Utqiagvik, the polar night, with its civil twilight -------------------------

{
    my $d = $utq->on(year => 2026, month => 11, day => 19);
    ok($d->is_polar_night, 'the first day without a sunrise');
    ok(!defined $d->sunrise, 'no sunrise');
    like(local_minute($d->dawn), qr/^2026-11-19 10:1[1-3]$/, 'but a civil dawn at 10:12');
    like(local_minute($d->dusk), qr/^2026-11-19 16:1[1-3]$/, 'and a civil dusk at 16:12');
    ok(defined $d->solar_noon, 'the transit exists though the sun is down');
    ok(!defined $d->day_length, 'no day_length');
    my $e = $utq->on(year => 2026, month => 11, day => 18);
    like(local_minute($e->sunrise), qr/^2026-11-18 12:4[1-3]$/, 'the day before, the last sunrise at 12:42');
    like(local_minute($e->sunset), qr/^2026-11-18 13:4[1-3]$/, 'and set at 13:42');
    near($e->day_length->total('minutes'), 60, 2, 'an hour of sun');
    my $f = $utq->on(year => 2026, month => 1, day => 22);
    like(local_minute($f->sunrise), qr/^2026-01-22 13:2[3-5]$/, 'the first sunrise of the year, 13:24');
    near($f->day_length->total('minutes'), 31, 2, 'half an hour');
    my $g = $utq->on(year => 2026, month => 1, day => 21);
    ok($g->is_polar_night && defined $g->dawn, 'the day before: polar night with a civil dawn');
}

# ---- Longyearbyen in December: no sun and no civil twilight, nautical still ------

{
    my $d = $lyr->on(year => 2026, month => 12, day => 21);
    ok($d->is_polar_night, 'polar night');
    ok(!defined $d->dawn, 'no civil twilight');
    ok(defined $d->dawn(kind => 'nautical'), 'the sun does come within twelve degrees of the horizon');
    ok(defined $d->dusk(kind => 'astronomical'), 'and so there is astronomical twilight');
    is(scalar(my @ev = $d->events), 6, 'six events: the two transits and two twilights\' ends');
}

# ---- McMurdo: a day_length that crosses the window's end ------------------------

{
    my $d = $mcm->on(year => 2026, month => 2, day => 20);
    like(local_minute($d->sunset), qr/^2026-02-20 01:2[89]$/, 'sunset 01:29');
    like(local_minute($d->sunrise), qr/^2026-02-20 02:4[6-8]$/, 'sunrise 02:47');
    near($d->day_length->total('hours'), 22 + 12 / 60, 0.1, 'to the next day\'s 00:59');
}

# ---- the search from an instant ------------------------------------------------

{
    my $midsummer = Time::Keeper->new(year => 2026, month => 6, day => 21, hour => 12, zone => 'America/Anchorage');
    like(local_minute($utq->next_sunset($midsummer)), qr/^2026-08-02 0(1:59|2:0[01])$/, 'the next sunset from midsummer is August\'s first');
    like(local_minute($utq->previous_sunset($midsummer)), qr/^2026-05-10 01:4[7-9]$/, 'the previous is May\'s last');
    like(local_minute($utq->next_sunrise($midsummer)), qr/^2026-08-02 03:0[7-9]$/, 'the next sunrise follows it');
    my $midwinter = Time::Keeper->new(year => 2026, month => 12, day => 21, hour => 12, zone => 'America/Anchorage');
    my $first = $utq->next_sunrise($midwinter);
    like(local_minute($first), qr/^2027-01-2[0-4] 1[23]:/, 'the next sunrise from midwinter is late January');
    ok($utq->next_sunset($first) > $first, 'and it sets after');
    like(local_minute($utq->previous_sunset($midwinter)), qr/^2026-11-18 13:4[1-3]$/, 'the previous sunset was 18 November');
    ok($utq->next_dawn($midwinter) > $midwinter, 'a civil dawn comes the next day');
    like(local_minute($utq->next_dawn($midwinter)), qr/^2026-12-22 11:5/, 'about 11:5x');
    ok($utq->next_dawn($midwinter, kind => 'nautical') < $utq->next_dawn($midwinter), 'nautical first');
    ok($utq->previous_dusk($midwinter) < $midwinter, 'a dusk before');
    my $noon = $utq->next_solar_noon($midwinter);
    like(local_minute($noon), qr/^2026-12-21 13:2/, "the next noon from 12:00 by the clock is today's, at 13:2x (the zone is an hour and more from its sun)");
    like(local_minute($utq->next_solar_noon($noon)), qr/^2026-12-22 13:2/, "and the next after that is tomorrow's");
    like(local_minute($utq->previous_solar_noon($midwinter)), qr/^2026-12-20 13:/, 'the previous was yesterday\'s');
    my $t = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 7, minute => 24, second => 22, zone => 'Europe/London');
    my $london = Time::Keeper::Sun->new(latitude => 51.5074, longitude => -0.1278, zone => 'Europe/London');
    ok($london->next_sunrise($t) > $t, 'next is strictly after the instant given');
    ok($london->previous_sunrise($t) < $t, 'previous strictly before');
    is($london->next_sunrise($t)->epoch - $london->previous_sunrise($t)->epoch > 86000, 1, 'a day apart');
    ok(!eval { $london->next_sunrise('dawn'); 1 }, 'a word dies');
    like($@, qr/^next_sunrise: 'dawn' is neither/, 'by name');
}

# ---- a grazing horizon, and the pole -------------------------------------------------

{
    my $g = Time::Keeper::Sun->new(latitude => 65.7, longitude => 0, zone => 'UTC')->on(year => 2026, month => 6, day => 21);
    like(local_minute($g->sunrise), qr/^2026-06-21 00:1[2-6]$/, '65.7 north at midsummer: the sun rises about 00:15 (USNO; a graze, two minutes is the mark)');
    like(local_minute($g->sunset), qr/^2026-06-21 23:4[89]$/, 'and sets at 23:49');
    ok(!defined $g->dawn, 'no civil twilight');
    my $h = Time::Keeper::Sun->new(latitude => 65.9, longitude => 0, zone => 'UTC')->on(year => 2026, month => 6, day => 21);
    ok($h->is_polar_day, 'a fifth of a degree further north it does not set');
    like(local_minute($h->solar_midnight), qr/^2026-06-21 00:0[1-3]$/, 'lower transit 00:02');

    my $pole = Time::Keeper::Sun->new(latitude => 89.99, longitude => 0, zone => 'UTC');
    my $p = $pole->on(year => 2026, month => 3, day => 19);
    ok($p->is_polar_day, 'at the pole the sun is up from before the equinox (refraction)');
    my $q = $pole->on(year => 2026, month => 9, day => 25);
    is(scalar(my @s = $q->sunsets), 1, 'and sets once, in September');
    like(local_minute($s[0]), qr/^2026-09-25 0(2:[2-5]\d|3:[0-2]\d)$/, 'within half an hour of 02:50 (USNO): at the pole the sun takes a day to cross the horizon, and the parallax this method ignores is minutes');
    ok(!defined $q->sunrise, 'with no sunrise that day');
    ok(!$q->is_polar_day && !$q->is_polar_night, 'a day with a sunset is neither');
    my $r = $pole->on(year => 2026, month => 9, day => 26);
    ok($r->is_polar_night, 'the next day is the polar night');
    ok($pole->next_sunrise(Time::Keeper->new(year => 2026, month => 12, day => 21, zone => 'UTC'))->month == 3, 'the next sunrise from midwinter at the pole is in March');
}

done_testing;
