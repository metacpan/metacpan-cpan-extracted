#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# Author test: the real Date::Holidays, from TK_BENCH_LIB, as a source.

BEGIN {
    if ($ENV{TK_BENCH_LIB}) {
        require Config;
        unshift @INC, map { ("$_/lib/perl5/$Config::Config{archname}", "$_/lib/perl5", $_) } split /:/, $ENV{TK_BENCH_LIB};
    }
    eval { require Date::Holidays; require Date::Holidays::GB; 1 }
        or plan skip_all => 'Date::Holidays and Date::Holidays::GB are needed (TK_BENCH_LIB)';
}
use Time::Keeper;
use Time::Keeper::Business;

my $dh = Date::Holidays->new(countrycode => 'gb');
my $b = Time::Keeper::Business->new(holidays => [$dh]);
sub d { Time::Keeper::Date->parse($_[0]) }

ok($b->is_holiday(d('2026-12-25')), 'Christmas Day 2026 is a holiday through Date::Holidays::GB');
ok($b->is_holiday(d('2026-12-28')), 'and the substitute for Boxing Day (a Saturday)');
ok(!$b->is_holiday(d('2026-12-22')), 'a plain Tuesday is not');
is($b->is_business_day(d('2026-12-28')), 0, 'the substitute day is closed');
my @h = $b->holidays(year => 2026);
cmp_ok(scalar @h, '>=', 8, 'England has at least eight bank holidays in 2026');
diag(join ', ', map { "$_->[0] " . ($_->[1] // '') } @h);

done_testing;
