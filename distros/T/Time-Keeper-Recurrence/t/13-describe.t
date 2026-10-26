#!perl
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Recurrence;

# describe: a rule in English words, from the compiled rule.

my $R = 'Time::Keeper::Recurrence';
my $start = Time::Keeper->parse('2026-01-01T09:00:00Z');

my @cron = (
    ['* * * * *',         'Every minute'],
    ['*/15 * * * *',      'Every 15 minutes'],
    ['0 * * * *',         'Every hour, on the hour'],
    ['5 * * * *',         'Every hour, at 5 minutes past the hour'],
    ['15,45 * * * *',     'At 15 and 45 minutes past the hour'],
    ['0 9 * * 1-5',       'At 09:00, Monday to Friday'],
    ['30 1 * * *',        'At 01:30 every day'],
    ['0 9,17 * * *',      'At 09:00 and 17:00 every day'],
    ['0 9,12,18 * * 1',   'At 09:00, 12:00 and 18:00, on Monday'],
    ['*/15 9-17 * * 1-5', 'Every 15 minutes from 09:00 to 17:45, Monday to Friday'],
    ['0 8-18 * * *',      'Every hour from 08:00 to 18:00'],
    ['0 */2 * * *',       'Every 2 hours, on the hour'],
    ['0 1-23/2 * * *',    'Every 2 hours from 01:00, on the hour'],
    ['0 13-23/2 * * *',   'At 13:00, 15:00, 17:00, 19:00, 21:00 and 23:00 every day'],
    ['0 11-23/2 * * *',   'Every 2 hours from 11:00, on the hour'],
    ['20,35,50 * * * *',  'At 20, 35 and 50 minutes past the hour'],
    ['0 0 1 * *',         'At 00:00, on the 1st of the month'],
    ['0 9 1,15 * *',      'At 09:00, on the 1st and the 15th of the month'],
    ['0 0 1 1 *',         'At 00:00, on the 1st of January'],
    ['0 9 * * 6,0',       'At 09:00, on Saturday and Sunday'],
    ['0 9 * * 1,3,5',     'At 09:00, on Monday, Wednesday and Friday'],
    ['0 9 13 * 5',        'At 09:00, on the 13th of the month, or on Friday'],
    ['0 12 * 3-10 *',     'At 12:00, from March to October'],
    ['@daily',            'At 00:00 every day'],
    ['@weekly',           'At 00:00, on Sunday'],
    ['@every 90m',        'Every 90 minutes, counted from the last run'],
    ['@every 2h',         'Every 2 hours, counted from the last run'],
);
for (@cron) {
    my ($expr, $want) = @$_;
    is($R->cron($expr)->describe, $want, "cron '$expr'");
}

my @rrule = (
    ['FREQ=DAILY;COUNT=10',                           'Every day, 10 times'],
    ['FREQ=DAILY;INTERVAL=2',                         'Every 2 days'],
    ['FREQ=HOURLY;INTERVAL=3',                        'Every 3 hours'],
    ['FREQ=SECONDLY;INTERVAL=30',                     'Every 30 seconds'],
    ['FREQ=MONTHLY;BYDAY=1MO',                        'On the first Monday of every month'],
    ['FREQ=MONTHLY;BYDAY=2TU,4TU',                    'On the second and fourth Tuesday of every month'],
    ['FREQ=MONTHLY;BYDAY=-2FR',                       'On the second to last Friday of every month'],
    ['FREQ=MONTHLY;BYMONTHDAY=-1',                    'On the last day of every month'],
    ['FREQ=MONTHLY;BYMONTHDAY=1,-1;COUNT=1',          'On the 1st and the last day of every month, once'],
    ['FREQ=MONTHLY;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=-1', 'On the last weekday of every month'],
    ['FREQ=MONTHLY;BYDAY=FR;BYMONTHDAY=13',           'On Friday the 13th, every month'],
    ['FREQ=MONTHLY;INTERVAL=3',                       'Every 3 months'],
    ['FREQ=WEEKLY;INTERVAL=2;BYDAY=TU',               'Every 2 weeks on Tuesday'],
    ['FREQ=WEEKLY;BYDAY=TU,TH;UNTIL=20261231T235959Z', 'Every Tuesday and Thursday, until 2026-12-31 23:59 UTC'],
    ['FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR;BYHOUR=9;BYMINUTE=0', 'At 09:00 every Monday to Friday'],
    ['FREQ=YEARLY',                                   'Every year'],
    ['FREQ=YEARLY;BYMONTH=11;BYDAY=4TH',              'On the fourth Thursday of November, every year'],
    ['FREQ=YEARLY;BYMONTH=6,7,8',                     'From June to August, every year'],
    ['FREQ=YEARLY;BYYEARDAY=1,100,200',               'On days 1, 100 and 200 of the year, every year'],
    ['FREQ=YEARLY;BYWEEKNO=20;BYDAY=MO',              'On Monday, in week 20 of the year, every year'],
    ['FREQ=YEARLY;BYDAY=20MO',                        'On the 20th Monday of every year'],
    ['FREQ=MINUTELY;INTERVAL=20;BYHOUR=9,10,11,12,13,14,15,16', 'Every 20 minutes from 09:00 to 16:40'],
    ['RSCALE=HEBREW;FREQ=YEARLY;BYMONTH=1;BYMONTHDAY=1', 'On the 1st of month 1, every year, in the Hebrew calendar'],
);
for (@rrule) {
    my ($rule, $want) = @$_;
    is($R->new(rrule => $rule, start => $start)->describe, $want, $rule);
}
is($R->every(3, 'day', start => $start)->describe, 'Every 3 days', 'every(3, day)');

# the same rule by two doors reads the same
is($R->new(rrule => 'FREQ=DAILY;BYHOUR=9;BYMINUTE=30', start => $start)->describe, 'At 09:30 every day', 'an RRULE ...');
is($R->cron('30 9 * * *')->describe, 'At 09:30 every day', '  ... and the cron that says it');

# every RFC 5545 example reads as words: no rule has none, and none leaks its parts
open my $fh, '<', 't/rfc5545-examples.tsv' or die $!;
my $n = 0;
while (<$fh>) {
    next if /^#/;
    chomp;
    my ($name, $ds, $rule) = split /\t/;
    my $r = $R->new(rrule => $rule, start => Time::Keeper->parse("${ds}Z"));
    my $d = $r->describe;
    $n++;
    ok(length $d && $d =~ /\A[A-Z]/ && $d !~ /FREQ|BY[A-Z]+|INTERVAL|;|  /, "RFC example '$name': $d");
}
is($n, 43, 'all 43 RFC 5545 examples read');
is($R->new(rrule => 'FREQ=MONTHLY;BYMONTHDAY=10,11,12,13,14,15;INTERVAL=18;COUNT=10', start => $start)->describe,
   'On the 10th to the 15th of every 18 months, 10 times', 'a run of days as a run');
is($R->new(rrule => 'FREQ=DAILY;BYMONTH=1;UNTIL=20000131T140000Z', start => Time::Keeper->parse('1998-01-01T09:00:00Z'))->describe,
   'Every day in January, until 2000-01-31 14:00 UTC', 'a daily rule keeps its "every day"');

done_testing;
