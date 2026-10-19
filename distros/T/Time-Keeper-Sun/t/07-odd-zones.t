#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Sun;

# Days that are not 24 hours, days that do not start at midnight, zones far
# from their sun, the horizon's height, and the leap second.

sub near { my ($got, $want, $tol, $name) = @_; cmp_ok(abs($got - $want), '<=', $tol, "$name: $got within $tol of $want") }

my $london = Time::Keeper::Sun->new(latitude => 51.5074, longitude => -0.1278, zone => 'Europe/London');

{
    my $d = $london->on(year => 2026, month => 10, day => 25);     # the clocks go back at 02:00
    is($d->end->epoch - $d->start->epoch, 25 * 3600, 'a 25-hour day');
    is("${\ $d->start }", '2026-10-25T00:00:00+01:00', 'starting in summer time');
    is("${\ $d->end }", '2026-10-26T00:00:00+00:00', 'ending in winter time');
    is(scalar(my @r = $d->sunrises), 1, 'still one sunrise');
    like("${\ $d->sunrise }", qr/^2026-10-25T06:4[12]:\d\d\+00:00$/, 'at 06:42 GMT (USNO)');
    like("${\ $d->sunset }", qr/^2026-10-25T16:4[67]:\d\d\+00:00$/, 'set 16:47 GMT');
    is(scalar(my @m = $d->solar_midnights), 2, 'two lower transits: they are 24 hours apart and the day is 25 hours long');
    like("$m[0]", qr/^2026-10-25T00:4\d:\d\d\+01:00$/, 'the first at 00:4x summer time');
    like("$m[1]", qr/^2026-10-25T23:4\d:\d\d\+00:00$/, 'the second at 23:4x winter time');
    is(scalar(my @nn = $d->solar_noons), 1, 'and one noon');
    my $e = $london->on(year => 2026, month => 3, day => 29);      # forward at 01:00
    is($e->end->epoch - $e->start->epoch, 23 * 3600, 'a 23-hour day');
    like("${\ $e->sunrise }", qr/^2026-03-29T06:4[23]:\d\d\+01:00$/, 'sunrise 06:43 BST (USNO)');
    is($e->start->epoch, $london->on(year => 2026, month => 3, day => 28)->end->epoch, 'the day starts where the one before ended');
    is($d->start->epoch, $london->on(year => 2026, month => 10, day => 24)->end->epoch, 'and the long day too');
}

# The window's edges by the engine's own test: the start is in, the end is not.
{
    my $d = $london->on(year => 2026, month => 10, day => 15);
    my ($s, $e) = ($d->start->epoch, $d->end->epoch);
    ok(Time::Keeper::Sun::_day_holds($d, $s), 'the first second of the day is in it');
    ok(!Time::Keeper::Sun::_day_holds($d, $s - 1), 'the second before is not');
    ok(Time::Keeper::Sun::_day_holds($d, $e - 1), 'the last second is in it');
    ok(!Time::Keeper::Sun::_day_holds($d, $e), "the next midnight is the next day's");
}

# Havana's clocks go back at midnight: 1 November 2026 has two of them, and
# the day starts at the EARLIER, so the hour between belongs to it.
{
    my $hav = Time::Keeper::Sun->new(latitude => 23.1136, longitude => -82.3666, zone => 'America/Havana');
    my $d = $hav->on(year => 2026, month => 11, day => 1);
    is("${\ $d->start }", '2026-11-01T00:00:00-04:00', 'the day starts at the first midnight, still in summer time');
    is($d->end->epoch - $d->start->epoch, 25 * 3600, 'and is 25 hours long');
    is($d->start->epoch, $hav->on(year => 2026, month => 10, day => 31)->end->epoch, 'meeting the day before exactly');
    is("${\ $d->end }", '2026-11-02T00:00:00-05:00', 'and ending at the standard-time midnight');
}

{
    my $scl = Time::Keeper::Sun->new(latitude => -33.4489, longitude => -70.6693, zone => 'America/Santiago');
    my $d = $scl->on(year => 2026, month => 9, day => 6);        # the clocks go from 24:00 to 01:00: no midnight
    is("${\ $d->start }", '2026-09-06T01:00:00-03:00', 'a day whose midnight did not exist starts at the first moment that did');
    is($d->start->epoch, $scl->on(year => 2026, month => 9, day => 5)->end->epoch, 'and meets the day before exactly');
    is($d->end->epoch - $d->start->epoch, 23 * 3600, '23 hours');
    like("${\ $d->sunrise }", qr/^2026-09-06T07:5[34]:\d\d-03:00$/, 'sunrise 07:54 (USNO)');
    my $e = $scl->on(year => 2026, month => 4, day => 4);        # back from 24:00 to 23:00: the Saturday is 25 hours
    is($e->end->epoch - $e->start->epoch, 25 * 3600, 'the long day in April is the Saturday the clocks go back at midnight');
    is("${\ $e->end }", '2026-04-05T00:00:00-04:00', 'ending at the standard-time midnight');
    like("${\ $e->sunrise }", qr/^2026-04-04T07:5[67]:\d\d-03:00$/, 'sunrise 07:57 summer time (USNO)');
    my $f = $scl->on(year => 2026, month => 4, day => 5);
    is($f->end->epoch - $f->start->epoch, 24 * 3600, 'the Sunday is an ordinary 24 hours');
    like("${\ $f->sunrise }", qr/^2026-04-05T06:5[78]:\d\d-04:00$/, 'sunrise 06:58 standard time (USNO)');
}

{
    my $lh = Time::Keeper::Sun->new(latitude => -31.5553, longitude => 159.0821, zone => 'Australia/Lord_Howe');
    my $d = $lh->on(year => 2026, month => 4, day => 5);
    is($d->end->epoch - $d->start->epoch, 24 * 3600 + 1800, 'Lord Howe\'s half-hour change makes a 24 and a half hour day');
    like("${\ $d->sunrise }", qr/^2026-04-05T06:0[67]:\d\d\+10:30$/, 'sunrise 06:07 (USNO)');
}

# A zone far from its sun: at longitude 180 on UTC the sun's lower transit is
# at noon by the clock, so the civil day's sunset comes before its sunrise.
{
    my $dl = Time::Keeper::Sun->new(latitude => 0, longitude => 180, zone => 'UTC');
    my $d = $dl->on(year => 2026, month => 10, day => 15);
    like("${\ $d->sunset }", qr/^2026-10-15T05:4[89]/, 'sunset at 05:49 by the clock (USNO)');
    like("${\ $d->sunrise }", qr/^2026-10-15T17:4[12]/, 'sunrise at 17:42');
    like("${\ $d->solar_noon }", qr/^2026-10-15T23:4[56]/, 'noon at 23:46');
    ok($d->sunset < $d->sunrise, 'the sunset is earlier in the day');
    near($d->day_length->total('hours'), 12.1, 0.05, 'day_length is positive: the sunrise to the NEXT day\'s sunset');
    my @ev = $d->events;
    is($ev[0][0], 'sunset', 'the day\'s first event is a sunset');
}

# Six hours east of the zone's meridian the sunrise comes last in the civil
# day, after a solar midnight in the afternoon: the walk must run to the
# window's end to find it (USNO: Rise 23:42, Set 11:49, Lower Transit 17:46).
{
    my $east = Time::Keeper::Sun->new(latitude => 0, longitude => 90, zone => 'UTC');
    my $d = $east->on(year => 2026, month => 10, day => 15);
    is(scalar(my @r = $d->sunrises), 1, 'one sunrise');
    like("$r[0]", qr/^2026-10-15T23:4[123]/, 'at 23:42, the last event of the day');
    like("${\ $d->sunset }", qr/^2026-10-15T11:4[89]/, 'the sunset at 11:49');
    like("${\ $d->solar_midnight }", qr/^2026-10-15T17:4[5-7]/, 'solar midnight at 17:46');
    like("${\ $d->dawn }", qr/^2026-10-15T23:2[0-2]/, 'civil dawn 23:21');
    my @ev = $d->events;
    is($ev[-1][0], 'sunrise', 'the sunrise is the last event');
    near($d->day_length->total('hours'), 12 + 7 / 60, 0.05, 'day_length runs into the next day');
}

# The horizon from a height (S6): the depression grows with the dip.
{
    my $sea = Time::Keeper::Sun->new(latitude => 51.5074, longitude => -0.1278, zone => 'Europe/London');
    my $cliff = Time::Keeper::Sun->new(latitude => 51.5074, longitude => -0.1278, zone => 'Europe/London', elevation => 100);
    near(Time::Keeper::Sun::_horizon($sea), -50 / 60, 1e-9, 'at sea level the horizon is 50 arcminutes down');
    near(Time::Keeper::Sun::_horizon($cliff), -(50 / 60 + 0.3209 + 0.0528), 0.002, 'from 100 metres, the dip and the height term added');
    my ($a, $b) = ($sea->on(year => 2026, month => 10, day => 15), $cliff->on(year => 2026, month => 10, day => 15));
    ok($b->sunrise < $a->sunrise, 'the sun rises earlier seen from a cliff');
    ok($b->sunset > $a->sunset, 'and sets later');
    near($b->sunrise->epoch - $a->sunrise->epoch, -150, 30, 'by about two and a half minutes at London in October (0.37 degrees more depression at 0.15 degrees a minute)');
    is("${\ $a->dawn }", "${\ $b->dawn }", 'the twilights take no height term');
}

# A leap-second day is an ordinary day to the sun.
{
    my $d = $london->on(year => 2016, month => 12, day => 31);
    is($d->end->epoch - $d->start->epoch, 86400, 'the window is 86,400 epoch seconds');
    like("${\ $d->sunrise }", qr/^2016-12-31T08:0[56]/, 'sunrise about 08:06');
    like("${\ $d->sunset }", qr/^2016-12-31T16:0[01]/, 'sunset about 16:01');
}

# Every result carries the place's locale.
{
    my $fr = Time::Keeper::Sun->new(latitude => 48.8566, longitude => 2.3522, zone => 'Europe/Paris', locale => 'fr');
    my $d = $fr->on(year => 2026, month => 10, day => 15);
    is($d->sunrise->locale, 'fr', 'the sunrise is in French');
    like($d->sunrise->format('EEEE d MMMM'), qr/^jeudi 15 octobre$/, 'and formats so');
    is($fr->next_sunset($d->sunrise)->locale, 'fr', 'so is a searched event');
}

done_testing;
