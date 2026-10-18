#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use DateTime;
my $date = rate(sub { Time::Keeper::Date->new(year => 2026, month => 10, day => 15) }, 'Date->new');
mark('Time::Keeper::Date->new', $date, rate(sub { DateTime->new(year => 2026, month => 10, day => 15) }, 'DateTime date'), 10, 'DateTime');
mark('Time::Keeper::Time->new', rate(sub { Time::Keeper::Time->new(hour => 9, minute => 5) }, 'Time->new'),
     rate(sub { DateTime->new(year => 1970, month => 1, day => 1, hour => 9, minute => 5) }, 'DateTime time'), 10, 'DateTime');
my $value = rate(sub { Time::Keeper->new(year => 2026, month => 10, day => 15) }, 'Time::Keeper->new');
printf "     a date is made at %s, a UTC value at %s: the zone is not where the time goes\n", fmt_rate($date), fmt_rate($value);
my $t = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9);
my $d = $t->to_date;
my $dt = DateTime->new(year => 2026, month => 10, day => 15);
mark('to_date', rate(sub { $t->to_date }, 'to_date'), rate(sub { $t->truncate(to => 'day') }, 'truncate(day)'), 1, 'truncate');
mark("Date->format_date (MMM d, y)", rate(sub { $d->format_date }, 'Date->format_date'), rate(sub { $dt->format_cldr('MMM d, y') }, 'DateTime format_cldr'), 10, 'DateTime');
done();
