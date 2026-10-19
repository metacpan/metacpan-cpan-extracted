#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Recurrence;

# The cron walk against Punk::Queue's own cases (its t/80-cron-parse.t): the
# step, the Vixie rule, the aliases, @every, fixed offsets, the horizon, and
# from being exclusive. Epochs in UTC as Punk writes them.

my $R = 'Time::Keeper::Recurrence';
sub utc { my ($y, $mo, $d, $h, $mi, $s) = @_; Time::Keeper->new(year => $y, month => $mo, day => $d, hour => $h // 0, minute => $mi // 0, second => $s // 0, zone => 'UTC') }
sub next_after { my ($expr, $from, $zone) = @_; my $r = $R->cron($expr, zone => $zone // 'UTC'); my $n = $r->next($from); defined $n ? $n->epoch : undef }
sub dies_like {
    my ($code, $re, $name) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok && $@ =~ $re, $name) or diag($ok ? 'did not die' : $@);
}

my @cases = (
    ['* * * * *',     utc(2026, 8, 7, 12, 30, 30), utc(2026, 8, 7, 12, 31),  'every minute: next minute boundary'],
    ['*/15 * * * *',  utc(2026, 8, 7, 12, 1),      utc(2026, 8, 7, 12, 15),  'step minutes'],
    ['0 3 * * *',     utc(2026, 8, 7, 4, 0),       utc(2026, 8, 8, 3, 0),    'daily, already past today'],
    ['0 3 * * *',     utc(2026, 8, 7, 2, 59),      utc(2026, 8, 7, 3, 0),    'daily, still ahead today'],
    ['30 2 1 * *',    utc(2026, 8, 7, 0, 0),       utc(2026, 9, 1, 2, 30),   'first of the month'],
    ['0 0 29 2 *',    utc(2026, 3, 1, 0, 0),       utc(2028, 2, 29, 0, 0),   'Feb 29 waits for the leap year'],
    ['0 12 * * 1',    utc(2026, 8, 7, 0, 0),       utc(2026, 8, 10, 12, 0),  'Monday noon (Aug 7 2026 is a Friday)'],
    ['0 12 * * 7',    utc(2026, 8, 7, 0, 0),       utc(2026, 8, 9, 12, 0),   'dow 7 is Sunday'],
    ['0 12 * * 0',    utc(2026, 8, 7, 0, 0),       utc(2026, 8, 9, 12, 0),   'dow 0 is also Sunday'],
    ['5-10 4 * * *',  utc(2026, 8, 7, 4, 7),       utc(2026, 8, 7, 4, 8),    'ranges'],
    ['0 0 * 1,7 *',   utc(2026, 8, 7, 0, 0),       utc(2027, 1, 1, 0, 0),    'month lists wrap the year'],
    ['59 23 31 12 *', utc(2026, 1, 1, 0, 0),       utc(2026, 12, 31, 23, 59), 'last minute of the year'],
);
for my $c (@cases) {
    my ($expr, $from, $want, $name) = @$c;
    is(next_after($expr, $from), $want->epoch, $name);
}
is(next_after('0 3 * * *', utc(2026, 8, 7, 3, 0)), utc(2026, 8, 8, 3, 0)->epoch, 'from is exclusive');

# the Vixie day rule: both day fields restricted, either fires
{
    my $from = utc(2026, 8, 7, 13, 0);   # the 8th is a Saturday, the 9th a Sunday
    is(next_after('0 12 8 * 0', $from), utc(2026, 8, 8, 12, 0)->epoch, 'restricted dom OR restricted dow: dom side fires first');
    is(next_after('0 12 20 * 0', $from), utc(2026, 8, 9, 12, 0)->epoch, 'and the dow side when it comes sooner');
    is(next_after('0 12 8 * *', $from), utc(2026, 8, 8, 12, 0)->epoch, 'dom restricted, dow free: dom is a filter');
    is(next_after('0 12 * * 0', $from), utc(2026, 8, 9, 12, 0)->epoch, 'dow restricted, dom free: dow is a filter');
}

# aliases and @every
{
    my $from = utc(2026, 8, 7, 13, 30);
    is(next_after('@daily', $from), utc(2026, 8, 8, 0, 0)->epoch, '@daily');
    is(next_after('@midnight', $from), utc(2026, 8, 8, 0, 0)->epoch, '@midnight');
    is(next_after('@hourly', $from), utc(2026, 8, 7, 14, 0)->epoch, '@hourly');
    is(next_after('@weekly', $from), utc(2026, 8, 9, 0, 0)->epoch, '@weekly is Sunday midnight');
    is(next_after('@monthly', $from), utc(2026, 9, 1, 0, 0)->epoch, '@monthly');
    is(next_after('@yearly', $from), utc(2027, 1, 1, 0, 0)->epoch, '@yearly');
    is(next_after('@every 15m', Time::Keeper->from_epoch(900)), 1800, '@every 15m');
    is(next_after('@every 1h', Time::Keeper->from_epoch(3599)), 7199, '@every 1h is an interval from the last occurrence, not a grid');
    is(next_after('@every 30s', Time::Keeper->from_epoch(30)), 60, '@every 30s');
    is(next_after('@every 1d', Time::Keeper->from_epoch(0)), 86400, '@every 1d');
    is($R->cron('@every 15m')->previous(Time::Keeper->from_epoch(1800))->epoch, 900, 'and back');
    dies_like(sub { $R->cron('@every 15m')->first(3) }, qr/an \@every cron has no occurrences of its own/, 'an @every cron has no first');
}

# fixed offsets
is(next_after('0 3 * * *', utc(2026, 8, 7, 12, 0), '+05:30'), utc(2026, 8, 7, 21, 30)->epoch, 'positive offset shifts the boundary');
is(next_after('0 3 * * *', utc(2026, 8, 7, 12, 0), '-04:00'), utc(2026, 8, 8, 7, 0)->epoch, 'negative offset too');

# the horizon
is(next_after('0 0 29 2 *', utc(2028, 2, 29, 0, 1)), utc(2032, 2, 29, 0, 0)->epoch, 'the walk crosses years to the next leap day inside the horizon');
dies_like(sub { $R->cron('0 0 30 2 *') }, qr/cron '0 0 30 2 \*' can never fire \(no occurrence within five years\)/, 'a cron that can never fire dies at construction');
dies_like(sub { $R->cron('0 0 31 4 *') }, qr/can never fire/, '31 April too');
dies_like(sub { $R->check('0 0 30 2 *') }, qr/can never fire \(no occurrence within five years\)/, 'and at check');

# the rest of the surface on a cron
my $c = $R->cron('0 3 * * *');
is($c->previous(utc(2026, 8, 7, 4, 0))->iso8601, '2026-08-07T03:00:00Z', 'previous');
is($c->previous(utc(2026, 8, 7, 3, 0))->iso8601, '2026-08-06T03:00:00Z', 'previous is strictly before');
is(join(' ', map { $_->format('d HH:mm') } $c->between(utc(2026, 8, 7, 3, 0), utc(2026, 8, 10, 3, 0))), '7 03:00 8 03:00 9 03:00', 'between: start inclusive, end exclusive');
is(join(' ', map { $_->ymd } $R->cron('0 0 1 * *')->first(3, )), join(' ', map { $_->ymd } $R->cron('0 0 1 * *')->between(Time::Keeper->now, Time::Keeper->now->plus(months => 4))), 'first(n) from now is what between gives') if 0;
ok($c->contains(utc(2026, 8, 7, 3, 0)), 'contains');
ok(!$c->contains(utc(2026, 8, 7, 3, 1)), 'and not');
ok(!$c->contains(Time::Keeper->new(year => 2026, month => 8, day => 7, hour => 3, nanosecond => 5, zone => 'UTC')), 'a cron fires on the second');
my $it = $c->iterate(utc(2026, 8, 7, 3, 0));
is(join(' ', map { $it->()->ymd } 1 .. 3), '2026-08-08 2026-08-09 2026-08-10', 'iterate from a moment, exclusive');
my $with_start = $R->cron('0 3 * * *', start => utc(2026, 8, 7, 3, 0));
is($with_start->next(utc(2026, 1, 1))->iso8601, '2026-08-08T03:00:00Z', 'a cron with a start fires after it, and the start itself is no occurrence');
is(join(' ', map { $_->ymd } $with_start->first(2)), '2026-08-08 2026-08-09', 'first on a cron with a start');
my $i2 = $with_start->iterate;
is($i2->()->ymd, '2026-08-08', 'iterate on a cron with a start begins after it');


# The forward walk jumps over hours and minutes a cron does not want; the
# backward walk reads every minute. On random crons the two must agree.
{
    srand($ENV{TKR_SEED} || 20261019);
    my @zones = qw(UTC America/New_York Europe/London Australia/Lord_Howe Asia/Kolkata +05:30 -03:00 UTC +00:00);
    my $bad = 0;
    my $n = 0;
    for my $i (1 .. 200) {
        my @f = map { my ($lo, $hi) = @$_; my $r = rand;
            $r < 0.3 ? '*' : $r < 0.5 ? '*/' . (2 + int rand 10) : $r < 0.8 ? join(',', map { $lo + int rand($hi - $lo + 1) } 1 .. 1 + int rand 3)
                : do { my $a = $lo + int rand($hi - $lo); $a . '-' . ($a + 1 + int rand($hi - $a)) } } ([0, 59], [0, 23], [1, 28], [1, 12], [0, 6]);
        my $expr = join ' ', @f;
        my $zone = $zones[int rand @zones];
        my $c = eval { Time::Keeper::Recurrence->cron($expr, zone => $zone) } or next;
        my $t = Time::Keeper->from_epoch(1767225600 + int rand(3 * 365 * 86400));
        my @fw;
        for (1 .. 8) { $t = $c->next($t) or last; push @fw, $t->epoch }
        next if @fw < 8;
        my @bw = ($fw[-1]);
        my $u = Time::Keeper->from_epoch($fw[-1]);
        for (1 .. 7) { $u = $c->previous($u) or last; unshift @bw, $u->epoch }
        $n++;
        next if "@fw" eq "@bw";
        $bad++;
        diag("$expr in $zone: next gives @fw, previous @bw");
        last if $bad > 3;
    }
    is($bad, 0, "next and previous agree on $n random crons");
}

done_testing;
