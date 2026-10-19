#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# Every arithmetic calendar, every day from Gregorian -1000 to 3000 (and the
# whole of the Umm al-Qura table): from_days then to_days gives the day
# back, the fields step by one, the month lengths add up to the year. The
# C door does the sweep; Perl reads the count of failures. Author only.
use Time::Keeper;

my ($from, $to) = (-1084500, 376200);
for my $cal (Time::Keeper::Calendar->ids) {
    my ($f, $t) = ($from, $to);
    if (Time::Keeper::Calendar->kind($cal) eq 'astronomical') {
        $f = Time::Keeper->new(year => $cal =~ /^islamic/ ? 390 : 1000, month => 1, day => 1, calendar => $cal)->epoch / 86400;
        $t = Time::Keeper->new(year => $cal =~ /^islamic/ ? 2452 : 3000, month => 1, day => 1, calendar => $cal)->plus(months => 11)->epoch / 86400;
    }
    my $bad = Time::Keeper::_cal_sweep($cal, $f, $t);
    is($bad, 0, sprintf '%-17s %d days sweep clean', $cal, $t - $f + 1);
}
is(Time::Keeper::_cal_sweep('hebrew', Time::Keeper::_cal_to_days('hebrew', 1, 1, 1) - 400, Time::Keeper::_cal_to_days('hebrew', 1, 1, 1) + 800), 0, 'the Hebrew epoch neighbourhood');
is(Time::Keeper::_cal_sweep('persian', Time::Keeper::_cal_to_days('persian', 1, 1, 1) - 400, Time::Keeper::_cal_to_days('persian', 3300, 12, 29)), 0, 'the Persian calendar across every moved leap year');

done_testing;
