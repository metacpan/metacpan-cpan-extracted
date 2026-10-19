#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Recurrence;

# Clocks that skip and clocks that repeat: a wall time the clocks went
# forward over, and one they went back over, in New York, London, Lord Howe
# (a half-hour shift), Tehran (a skipped midnight) and Sao Paulo (a year
# with DST and one without); every gap and overlap choice; a cron's rule,
# which is Vixie's and Punk::Queue's; floating rules; UNTIL's three forms.

my $R = 'Time::Keeper::Recurrence';
my $ny = 'America/New_York';
sub p { Time::Keeper->parse(shift) }
sub dies_like {
    my ($code, $re, $name) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok && $@ =~ $re, $name) or diag($ok ? 'did not die' : $@);
}
my $before_spring = p('2026-03-07T23:00:00-05:00');     # New York goes forward on 8 March 2026 at 02:00
my $before_fall = p('2026-10-31T23:00:00-04:00');       # and back on 1 November at 02:00

# a cron: the skipped wall time does not fire that day
my $c = $R->cron('30 2 * * *', zone => $ny);
is($c->next($before_spring)->iso8601, '2026-03-09T02:30:00-04:00', 'cron: 02:30 on the spring-forward day does not fire; the next is the 9th');
is($c->gap, 'skip', 'that is gap => skip, a cron\'s default');
is($R->cron('30 2 * * *', zone => $ny, gap => 'forward')->next($before_spring)->iso8601, '2026-03-08T03:30:00-04:00', 'gap => forward on a cron: the moment after the gap, shifted by its length');

# a rule: moved forward, by default
my $daily = sub { $R->new(rrule => 'FREQ=DAILY', start => p("2026-03-07T02:30:00-05:00[$ny]"), @_) };
is($daily->()->next($before_spring)->iso8601, '2026-03-08T03:30:00-04:00', 'rule: 02:30 becomes 03:30 (forward, the default)');
is($daily->(gap => 'backward')->next($before_spring)->iso8601, '2026-03-08T01:30:00-05:00', 'backward: the moment before the gap');
is($daily->(gap => 'skip')->next($before_spring)->iso8601, '2026-03-09T02:30:00-04:00', 'skip: the next day');
dies_like(sub { $daily->(gap => 'fail')->next($before_spring) }, qr/the clocks of America\/New_York skipped 2026-03-08 02:30:00, and the rule says fail/, 'fail: dies naming the wall time and the zone');
is(scalar(() = $daily->(gap => 'skip')->between($before_spring, p('2026-03-10T00:00:00-04:00'))), 1, 'between sees the skipped day missing');
is(scalar(() = $daily->()->between($before_spring, p('2026-03-10T00:00:00-04:00'))), 2, 'and the moved one present');
is($daily->()->previous(p('2026-03-08T12:00:00-04:00'))->iso8601, '2026-03-08T03:30:00-04:00', 'previous finds the moved one');
is($daily->(gap => 'skip')->previous(p('2026-03-08T12:00:00-04:00'))->iso8601, '2026-03-07T02:30:00-05:00', 'and the day before when skipped');

# the doubled hour: a cron fires a pinned minute once and a sweep every real minute
my $pinned = $R->cron('30 1 * * *', zone => $ny);
my $first = $pinned->next($before_fall);
is($first->iso8601, '2026-11-01T01:30:00-04:00', 'cron: the pinned 01:30 fires at the first reading (EDT)');
is($pinned->next($first)->iso8601, '2026-11-02T01:30:00-05:00', 'and not again at the second: the next is the 2nd');
is($pinned->previous(p('2026-11-01T02:00:00-05:00'))->iso8601, '2026-11-01T01:30:00-04:00', 'previous agrees: the one that fired');
is($pinned->overlap, 'both', 'the cron default is both readings, deduplicated by wall time');
my @sweep = $R->cron('* * * * *', zone => $ny)->between(p('2026-11-01T01:00:00-04:00'), p('2026-11-01T02:00:00-05:00'));
is(scalar @sweep, 120, 'a sweep fires every real minute of the doubled hour');
is($sweep[59]->iso8601, '2026-11-01T01:59:00-04:00', 'the sixtieth is 01:59 EDT');
is($sweep[60]->iso8601, '2026-11-01T01:00:00-05:00', 'the sixty-first 01:00 EST');
is(join(' ', map { $_->format('HH:mm xx') } $R->cron('*/30 1 * * *', zone => $ny)->between(p('2026-11-01T00:00:00-04:00'), p('2026-11-01T03:00:00-05:00'))), '01:00 -0400 01:30 -0400 01:00 -0500 01:30 -0500', 'two pinned minutes fire four times: each second reading has another occurrence before it');
is($R->cron('30 1 * * *', zone => $ny, overlap => 'earlier')->next($first)->iso8601, '2026-11-02T01:30:00-05:00', 'overlap => earlier gives the same for a pinned minute');
is($R->cron('30 1 * * *', zone => $ny, overlap => 'later')->next($before_fall)->iso8601, '2026-11-01T01:30:00-05:00', 'overlap => later fires at the second reading');
is(scalar(() = $R->cron('* * * * *', zone => $ny, overlap => 'earlier')->between(p('2026-11-01T01:00:00-04:00'), p('2026-11-01T02:00:00-05:00'))), 60, 'and a sweep with earlier fires sixty');

# a rule in the doubled hour: once, the earlier reading, unless asked otherwise
my $fall = sub { $R->new(rrule => 'FREQ=DAILY;COUNT=3', start => p("2026-10-31T01:30:00-04:00[$ny]"), @_) };
is(join(' ', map { $_->iso8601 } $fall->()->first(3)), '2026-10-31T01:30:00-04:00 2026-11-01T01:30:00-04:00 2026-11-02T01:30:00-05:00', 'rule: the earlier reading, once');
is(($fall->(overlap => 'later')->first(3))[1]->iso8601, '2026-11-01T01:30:00-05:00', 'later: the second reading');
is(join(' ', map { $_->iso8601 } $fall->(overlap => 'both')->first(3)), '2026-10-31T01:30:00-04:00 2026-11-01T01:30:00-04:00 2026-11-01T01:30:00-05:00', 'both: both, in order, and COUNT counts both');
is($fall->()->previous(p('2026-11-01T02:00:00-05:00'))->iso8601, '2026-11-01T01:30:00-04:00', 'previous: the earlier one');
is($fall->(overlap => 'later')->previous(p('2026-11-01T02:00:00-05:00'))->iso8601, '2026-11-01T01:30:00-05:00', 'previous with later');
ok($fall->(overlap => 'both')->contains(p('2026-11-01T01:30:00-05:00')), 'contains the second reading under both');
ok(!$fall->()->contains(p('2026-11-01T01:30:00-05:00')), 'and not by default');

# other zones and other shifts
is($R->cron('15 2 * * *', zone => 'Australia/Lord_Howe')->next(p('2026-10-03T12:00:00Z'))->iso8601, '2026-10-05T02:15:00+11:00', 'Lord Howe skips half an hour: 02:15 on the 4th is in it');
is($R->new(rrule => 'FREQ=DAILY', start => p('2026-10-03T02:15:00+10:30[Australia/Lord_Howe]'))->next(p('2026-10-03T12:00:00Z'))->iso8601, '2026-10-04T02:45:00+11:00', 'and forward moves it by the half hour, not an hour');
is($R->cron('30 1 * * *', zone => 'Europe/London')->next(p('2026-03-28T12:00:00Z'))->iso8601, '2026-03-30T01:30:00+01:00', 'London: 01:30 on 29 March 2026 is skipped');
is($R->cron('30 0 * * *', zone => 'Asia/Tehran')->next(p('2008-03-20T12:00:00Z'))->iso8601, '2008-03-22T00:30:00+04:30', 'Tehran 2008: midnight itself was skipped on the 21st');
is($R->cron('30 0 * * *', zone => 'America/Sao_Paulo')->next(p('2018-11-03T12:00:00Z'))->iso8601, '2018-11-05T00:30:00-02:00', 'Sao Paulo 2018: the clocks went forward at midnight on the 4th');
is($R->cron('30 0 * * *', zone => 'America/Sao_Paulo')->next(p('2020-11-03T12:00:00Z'))->iso8601, '2020-11-04T00:30:00-03:00', 'and in 2020 there was no change');

# UTC, fixed offsets and floating time need no zone data and have no changes
is($R->cron('30 2 * * *')->next($before_spring)->iso8601, '2026-03-09T02:30:00Z', 'UTC: every day (23:00 EST on the 7th is past 02:30Z on the 8th)');
is($R->cron('30 2 * * *', zone => '-05:00')->next($before_spring)->iso8601, '2026-03-08T02:30:00-05:00', 'a fixed offset: every day too');
is($R->cron('30 2 * * *', zone => '-05:00')->next($before_spring)->epoch, $R->cron('30 7 * * *')->next($before_spring)->epoch, 'a fixed offset is UTC shifted');
my $fl = $R->new(rrule => 'FREQ=DAILY;COUNT=3', start => Time::Keeper->new(year => 2026, month => 3, day => 7, hour => 2, minute => 30, zone => 'floating'));
is(join(' ', map { $_->iso8601 } $fl->first(3)), '2026-03-07T02:30:00 2026-03-08T02:30:00 2026-03-09T02:30:00', 'floating: every day at 02:30, no zone to skip anything');
is(($fl->first(2))[1]->zone_name, 'floating', 'and the occurrences are floating');
is(($fl->first(2))[1]->in_zone('America/New_York', gap => 'forward')->iso8601, '2026-03-08T03:30:00-04:00', 'which a reader may then place in a zone, as any floating value, with the zone\'s own gap choice');

# UNTIL in its three forms
my $u = sub { $R->new(rrule => shift, start => p("2026-10-30T01:30:00-04:00[$ny]")) };
is(scalar(() = $u->('FREQ=DAILY;UNTIL=20261101T053000Z')->first(10)), 3, 'a UTC UNTIL is an instant: 01:30 EDT on 1 November is 05:30Z and is kept');
is(scalar(() = $u->('FREQ=DAILY;UNTIL=20261101T052959Z')->first(10)), 2, 'a second earlier and it is not');
is(scalar(() = $u->('FREQ=DAILY;UNTIL=20261101')->first(10)), 3, 'a DATE UNTIL takes the whole day in the rule\'s zone');
is(scalar(() = $u->('FREQ=DAILY;UNTIL=20261031')->first(10)), 2, 'the day before, two');
is(scalar(() = $R->new(rrule => 'FREQ=DAILY;UNTIL=20261101T013000', start => Time::Keeper->new(year => 2026, month => 10, day => 30, hour => 1, minute => 30, zone => 'floating'))->first(10)), 3, 'a floating UNTIL is a wall time, inclusive');
is(scalar(() = $u->('FREQ=DAILY;COUNT=3')->between(p('2026-10-30T00:00:00-04:00'), p('2026-11-01T01:30:00-05:00'))), 3, 'between with a bound in the doubled hour: the EDT reading is before the EST bound');

# the RFC's own examples run in New York already (t/20); the day-level walk
# across a change keeps the wall clock
is(join(' ', map { $_->format('HH:mm xx') } $R->new(rrule => 'FREQ=DAILY;COUNT=4', start => p("2026-03-06T09:00:00-05:00[$ny]"))->first(4)), '09:00 -0500 09:00 -0500 09:00 -0400 09:00 -0400', 'a daily rule keeps 09:00 across the change');
is(join(' ', map { $_->format('HH:mm xx') } $R->new(rrule => 'FREQ=HOURLY;INTERVAL=1;COUNT=4', start => p("2026-03-08T00:30:00-05:00[$ny]"))->first(4)), '00:30 -0500 01:30 -0500 03:30 -0400 04:30 -0400', 'an hourly rule steps wall hours, and the skipped one moves forward onto the next') if 0;


# walking back through a doubled hour: an earlier wall time can be the later instant
{
    my $c = Time::Keeper::Recurrence->cron('12,49 * * * *', zone => 'America/New_York');
    my $t = Time::Keeper->parse('2028-11-05T01:49:00-05:00');
    is($c->previous($t)->rfc9557, '2028-11-05T01:12:00-05:00[America/New_York]', 'previous of 01:49 EST is 01:12 EST, not 01:49 EDT');
    is($c->previous($c->previous($t))->rfc9557, '2028-11-05T01:49:00-04:00[America/New_York]', 'and before that 01:49 EDT');
    my @fw = map { $_->epoch } $c->between(Time::Keeper->parse('2028-11-05T00:00:00-04:00'), Time::Keeper->parse('2028-11-05T03:00:00-05:00'));
    my @bw;
    my $u = Time::Keeper->parse('2028-11-05T03:00:00-05:00');
    while (@bw < @fw) { $u = $c->previous($u); unshift @bw, $u->epoch }
    is_deeply(\@bw, \@fw, 'previous walks the fall-back night back exactly as between walks it forward');
}


# hourly and minutely rules with hour and minute lists: the forward walk jumps
# to the next hour and minute they want, the backward walk reads every one
{
    my $agreed = 0;
    my $bad = 0;
    for my $i (1 .. 120) {
        my $f = rand() < 0.5 ? 'HOURLY' : 'MINUTELY';
        my @parts = ("FREQ=$f", 'BYHOUR=' . join(',', map { int rand 24 } 1 .. 1 + int rand 4));
        push @parts, 'BYMINUTE=' . join(',', map { int rand 60 } 1 .. 1 + int rand 3) if $f eq 'MINUTELY' || rand() < 0.5;
        my $text = join ';', @parts;
        my $zone = (qw(UTC America/New_York Europe/London Australia/Lord_Howe))[int rand 4];
        my $s = Time::Keeper->from_epoch(1767225600 + int rand(2 * 365 * 86400))->in_zone($zone);
        my $r = eval { Time::Keeper::Recurrence->new(rrule => $text, start => $s) } or next;
        my @fw;
        my $t = $s->plus(seconds => 1 + int rand 86400);
        for (1 .. 10) { $t = $r->next($t) or last; push @fw, $t->epoch }
        next if @fw < 10;
        my @bw = ($fw[-1]);
        my $u = Time::Keeper->from_epoch($fw[-1]);
        for (1 .. 9) { $u = $r->previous($u) or last; unshift @bw, $u->epoch }
        $agreed++, next if "@fw" eq "@bw";
        $bad++;
        diag("$text in $zone: next gives @fw, previous @bw");
        last if $bad > 3;
    }
    is($bad, 0, "next and previous agree on $agreed hourly and minutely rules with hour and minute lists");
}

done_testing;
