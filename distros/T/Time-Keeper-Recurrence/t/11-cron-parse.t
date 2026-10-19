#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Recurrence;

# Punk::Queue's cron grammar, read into a rule and written back: the
# aliases, @every, the Vixie rule, the fold of day 7, what counts as
# restricted, and Punk::Queue's rejections word for word.

my $R = 'Time::Keeper::Recurrence';
sub cron { $R->cron(@_) }
sub dies_like {
    my ($code, $re, $name) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok && $@ =~ $re, $name) or diag($ok ? 'did not die' : $@);
}

# each spelling to its RRULE
my %rrule = (
    '* * * * *'        => 'FREQ=MINUTELY',
    '0 3 * * *'        => 'FREQ=MINUTELY;BYMINUTE=0;BYHOUR=3',
    '*/15 * * * *'     => 'FREQ=MINUTELY;BYMINUTE=0,15,30,45',
    '30 2 * * 1-5'     => 'FREQ=MINUTELY;BYMINUTE=30;BYHOUR=2;BYDAY=MO,TU,WE,TH,FR',
    '0 12 * * 7'       => 'FREQ=MINUTELY;BYMINUTE=0;BYHOUR=12;BYDAY=SU',
    '0 12 * * 0'       => 'FREQ=MINUTELY;BYMINUTE=0;BYHOUR=12;BYDAY=SU',
    '0 12 * * fri-mon' => 'FREQ=MINUTELY;BYMINUTE=0;BYHOUR=12;BYDAY=MO,FR,SA,SU',
    '0 0 29 feb *'     => 'FREQ=MINUTELY;BYMINUTE=0;BYHOUR=0;BYMONTHDAY=29;BYMONTH=2',
    '0 0 1 1,7 *'      => 'FREQ=MINUTELY;BYMINUTE=0;BYHOUR=0;BYMONTHDAY=1;BYMONTH=1,7',
    '5/20 * * * *'     => 'FREQ=MINUTELY;BYMINUTE=5,25,45',
    '0 9-17/4 * * *'   => 'FREQ=MINUTELY;BYMINUTE=0;BYHOUR=9,13,17',
    '0 0 1-31 * *'     => 'FREQ=MINUTELY;BYMINUTE=0;BYHOUR=0',
    '0 0 * * 0-7'      => 'FREQ=MINUTELY;BYMINUTE=0;BYHOUR=0',
    '@yearly'          => 'FREQ=MINUTELY;BYMINUTE=0;BYHOUR=0;BYMONTHDAY=1;BYMONTH=1',
    '@annually'        => 'FREQ=MINUTELY;BYMINUTE=0;BYHOUR=0;BYMONTHDAY=1;BYMONTH=1',
    '@monthly'         => 'FREQ=MINUTELY;BYMINUTE=0;BYHOUR=0;BYMONTHDAY=1',
    '@weekly'          => 'FREQ=MINUTELY;BYMINUTE=0;BYHOUR=0;BYDAY=SU',
    '@daily'           => 'FREQ=MINUTELY;BYMINUTE=0;BYHOUR=0',
    '@midnight'        => 'FREQ=MINUTELY;BYMINUTE=0;BYHOUR=0',
    '@hourly'          => 'FREQ=MINUTELY;BYMINUTE=0',
    '  0   3 * * *  '  => 'FREQ=MINUTELY;BYMINUTE=0;BYHOUR=3',
    '0 12 8 * 0'       => 'FREQ=MINUTELY;BYMINUTE=0;BYHOUR=12;BYDAY=SU;BYMONTHDAY=8',
);
for my $expr (sort keys %rrule) {
    is(cron($expr)->rrule, $rrule{$expr}, "'$expr' is $rrule{$expr}");
}
is(cron('0 0 * * 7')->rrule, cron('0 0 * * 0')->rrule, '7 is Sunday, as 0 is');
is(cron('* * * * 7')->rrule, 'FREQ=MINUTELY;BYDAY=SU', 'the fold of 7 happens after the mask is built: 7 alone is Sunday');
is(cron('* * * * *')->rrule, 'FREQ=MINUTELY', 'and * is every day, not Sunday only');

# written back
for my $expr ('0 3 * * *', '30 2 * * 1-5', '0 12 * * 0', '0 0 29 2 *', '0 0 1 1,7 *', '0 12 8 * 0', '* * * * *', '0,15,30,45 * * * *', '5,25,45 * * * *') {
    is(cron($expr)->cron, $expr, "'$expr' writes back as itself");
}
is(cron('*/15 * * * *')->cron, '0,15,30,45 * * * *', 'a step is written out');
is(cron('0 9-17/4 * * *')->cron, '0 9,13,17 * * *', 'a stepped range too');
is(cron('0 12 * * fri-mon')->cron, '0 12 * * 0,1,5,6', 'names and wrapped ranges as numbers');
is(cron('0 0 1-31 * *')->cron, '0 0 * * *', 'a field spelling out everything is *');
is(cron('@daily')->cron, '0 0 * * *', 'an alias as its fields');
is(cron('0 0 * * 1-7')->cron, '0 0 * * *', '1-7 is every day');
is(cron('0 0 * * 1-6')->cron, '0 0 * * 1-6', 'a run of weekdays');
for my $expr (sort keys %rrule) {
    my $again = cron(cron($expr)->cron);
    is($again->rrule, cron($expr)->rrule, "written and read again, '$expr' is the same rule");
}

# @every
my $e = cron('@every 15m');
is($e->freq, 'every', '@every is its own frequency');
is($e->cron, '@every 15m', 'and writes back');
is(cron('@every 90m')->cron, '@every 90m', '90 minutes stays minutes');
is(cron('@every 120m')->cron, '@every 2h', '120 minutes is 2h');
is(cron('@every 86400s')->cron, '@every 1d', '86400 seconds is a day');
is(cron('@every 30s')->cron, '@every 30s', 'seconds');
ok(!$e->is_finite, 'an @every cron never ends');
dies_like(sub { $e->rrule }, qr/an \@every cron is an interval from the last occurrence, which no RRULE says/, 'it has no RRULE');

# what a cron says about itself
my $c = cron('0 3 * * *', zone => 'America/New_York');
is($c->zone, 'America/New_York', 'the zone given');
is($c->gap . ' ' . $c->overlap, 'skip both', 'a cron skips a gap and fires at every real minute of a doubled hour, as cron does');
ok(!defined $c->start, 'a cron has no start');
ok(!defined $c->count && !defined $c->until, 'nor an end');
ok(!$c->is_finite, 'so it is not finite');
is(cron('0 3 * * *')->zone, 'UTC', 'UTC when no zone is given');
is(cron('0 3 * * *', zone => '+05:30')->zone, '+05:30', 'a fixed offset');
is(cron('0 3 * * *', zone => 'floating')->zone, 'floating', 'floating');
my $t = Time::Keeper->new(year => 2026, month => 10, day => 15, zone => 'Europe/London');
is(cron('0 3 * * *', start => $t)->zone, 'Europe/London', 'a start gives the zone');
is(cron('0 3 * * *', start => $t)->start->iso8601, '2026-10-15T00:00:00+01:00', 'and is kept');
is(cron('0 3 * * *', gap => 'forward')->gap, 'forward', 'gap can be chosen');
dies_like(sub { cron('0 3 * * *', start => $t, zone => 'UTC') }, qr/start => carries the zone/, 'start and zone together die');
dies_like(sub { cron('0 3 * * *', zone => 'Mars/Olympus') }, qr/'Mars\/Olympus' is not a time zone/, 'a bad zone dies');
ok($R->check('0 3 * * *'), 'check accepts');
ok($R->check('30 2 * * *', 'America/New_York'), 'check with a zone');

# an RRULE as a cron, and the rules that have no cron spelling
my $start = Time::Keeper->new(year => 2026, month => 1, day => 1, zone => 'UTC');
sub rule { $R->new(rrule => shift, start => $start) }
is(rule('FREQ=MINUTELY;BYMINUTE=30;BYHOUR=2;BYDAY=MO,TU,WE,TH,FR')->cron, '30 2 * * 1-5', 'a minutely rule as a cron');
is(rule('FREQ=DAILY;BYHOUR=3;BYMINUTE=0')->cron, '0 3 * * *', 'a daily rule with its clock given');
is(rule('FREQ=HOURLY;BYMINUTE=15')->cron, '15 * * * *', 'an hourly rule with its minute given');
is(rule('FREQ=MINUTELY')->cron, '* * * * *', 'every minute');
my %nocron = (
    'FREQ=DAILY'                          => qr/a daily rule is a cron only with BYHOUR and BYMINUTE given/,
    'FREQ=HOURLY'                         => qr/an hourly rule is a cron only with BYMINUTE given/,
    'FREQ=WEEKLY;BYDAY=MO'                => qr/a cron steps minutes, hours or days, not weekly/,
    'FREQ=MINUTELY;INTERVAL=2'            => qr/a cron has no INTERVAL/,
    'FREQ=MINUTELY;BYSECOND=30'           => qr/a cron has no seconds/,
    'FREQ=DAILY;BYHOUR=3;BYMINUTE=0;COUNT=3' => qr/a cron has no end/,
    'FREQ=MINUTELY;BYMONTHDAY=-1'         => qr/a cron has no days counted from the end of the month/,
    'FREQ=MINUTELY;BYMONTHDAY=8;BYDAY=SU' => qr/cron reads both day fields as either, not both/,
    'FREQ=MINUTELY;BYSETPOS=1;BYHOUR=3'   => qr/a cron has no BYYEARDAY, BYWEEKNO or BYSETPOS/,
);
for my $text (sort keys %nocron) {
    dies_like(sub { rule($text)->cron }, $nocron{$text}, "no cron spelling: $text");
}
is(cron('0 12 8 * 0')->rrule, 'FREQ=MINUTELY;BYMINUTE=0;BYHOUR=12;BYDAY=SU;BYMONTHDAY=8', 'the Vixie cron reads as an RRULE with both day parts');
is(cron('0 12 8 * 0')->cron, '0 12 8 * 0', 'and writes back, since it came through the cron door');

# Punk::Queue's rejections, word for word after the method's name
my %bad = (
    ''              => qr/Time::Keeper::Recurrence->(?:cron|check): empty cron expression/,
    '   '           => qr/empty cron expression/,
    '* * * *'       => qr/cron expression has 4 field\(s\), needs 5 \(minute hour day-of-month month day-of-week\)/,
    '* * * * * *'   => qr/cron expression has more than 5 fields - second and year fields are not supported/,
    '61 * * * *'    => qr/bad cron minute field near '61/,
    '* 25 * * *'    => qr/bad cron hour field near '25/,
    '* * 0 * *'     => qr/bad cron day-of-month field near '0/,
    '* * 32 * *'    => qr/bad cron day-of-month field near '32/,
    '* * * 13 *'    => qr/bad cron month field near '13/,
    '* * * * 8'     => qr/bad cron day-of-week field near '8/,
    '* * * * L'     => qr/cron token 'L' is not supported \(L, W, # and \? are excluded in this release\)/,
    '* * 15W * *'   => qr/cron token 'W' is not supported/,
    '* * * * 5#3'   => qr/cron token '#' is not supported/,
    '* * ? * *'     => qr/cron token '\?' is not supported/,
    '@fortnightly'  => qr/unknown cron alias '\@fortnightly'/,
    '@every 5x'     => qr/\@every wants '<n>\(s\|m\|h\|d\)', not '\@every 5x'/,
    '@every'        => qr/unknown cron alias '\@every'/,
    '* * * * mon-xyz' => qr/bad cron day-of-week field near 'xyz'/,
    '*/0 * * * *'   => qr/bad cron minute field near/,
    '* * * jan-feb/0 *' => qr/bad cron month field near/,
);
for my $expr (sort keys %bad) {
    dies_like(sub { cron($expr) }, $bad{$expr}, "dies: '$expr'");
    dies_like(sub { $R->check($expr) }, $bad{$expr}, "check dies the same: '$expr'");
}

done_testing;
