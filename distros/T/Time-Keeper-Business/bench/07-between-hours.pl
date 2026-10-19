#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Business;
my $b = Time::Keeper::Business->new(holidays => Time::Keeper::Business::Rule->uk, weekend => 'en-GB', zone => 'Europe/London',
                                    hours => { default => ['09:00-12:30', '13:30-17:30'], fri => ['09:00-13:00'] });
my ($t, $u) = (Time::Keeper->new(year => 2026, month => 10, day => 12, hour => 11, zone => 'Europe/London'),
               Time::Keeper->new(year => 2026, month => 10, day => 19, hour => 11, zone => 'Europe/London'));
$b->business_hours_between($t, $u);
my $num = rate(sub { $b->business_hours_between($t, $u, number => 1) }, 'as a number');
my $dur = rate(sub { $b->business_hours_between($t, $u) }, 'as a Duration');
printf "info business_hours_between as a Duration: %s (two method calls into the core)\n", fmt_rate($dur);
mark_rate('business_hours_between, a week, number => 1', $num, 1e6);
if (eval { require Business::Hours; 1 }) {
    my $bh = Business::Hours->new;
    $bh->business_hours(map { $_ => { Name => $_, Start => ($_ >= 1 && $_ <= 5 ? '9:00' : undef), End => ($_ >= 1 && $_ <= 5 ? '17:00' : undef) } } 0 .. 6);
    my ($e, $f) = ($t->epoch, $u->epoch);
    mark('business_hours_between', $num, rate(sub { $bh->between($e, $f) }, 'Business::Hours'), 20, 'Business::Hours between');
}
else { absent('Business::Hours', 'between') }
if (eval { require DateTime::BusinessHours; require DateTime; 1 }) {
    my ($d1, $d2) = (DateTime->from_epoch(epoch => $t->epoch), DateTime->from_epoch(epoch => $u->epoch));
    mark('business_hours_between', $num, rate(sub { DateTime::BusinessHours->new(datetime1 => $d1, datetime2 => $d2, worktiming => [9, 17], weekends => [6, 7])->gethours }, 'DateTime::BusinessHours'), 20, 'DateTime::BusinessHours');
}
else { absent('DateTime::BusinessHours', 'gethours') }
done();
