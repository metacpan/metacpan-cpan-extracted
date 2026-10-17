#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Time::Keeper;

my @ends = Time::Keeper::_leap_ends();
is(scalar @ends, 27, '27 leap seconds');
is_deeply([map { [(Time::Keeper::_civil_from_instant($_, 0))[0 .. 3]] } @ends[0, -1]],
          [[1972, 7, 1, 0], [2017, 1, 1, 0]], 'the first ended on 1 July 1972, the last on 1 January 2017');
is(scalar(grep { $_ % 86400 } @ends), 0, 'every one ends at a midnight');

my ($expires, $updated) = Time::Keeper::_leap_dates();
is_deeply([(Time::Keeper::_civil_from_instant($expires, 0))[0 .. 2]], [2027, 6, 28], 'the list expires on 28 June 2027');
cmp_ok($updated, '<', $expires, 'and was updated before that');

# Every leap second: 23:59:60 is a time, at its start and its last
# nanosecond, and comes back as second 60; the day before and the day after
# have none.
my $bad = 0;
for my $end (@ends) {
    my ($y, $m, $d) = Time::Keeper::_civil_from_instant($end - 1, 0);
    my @t = Time::Keeper::_instant_from_civil($y, $m, $d, 23, 59, 60, 0);
    $bad++ unless "@t" eq ($end - 1) . " 1000000000";
    my @c = Time::Keeper::_civil_from_instant($end - 1, 1_999_999_999);
    $bad++ unless "@c[3 .. 6]" eq "23 59 60 999999999";
    my @p = Time::Keeper::_civil_from_instant($end - 1 - 86400, 0);
    $bad++ if eval { Time::Keeper::_instant_from_civil(@p[0 .. 2], 23, 59, 60, 0); 1 };
    my @n = Time::Keeper::_civil_from_instant($end, 0);
    $bad++ if eval { Time::Keeper::_instant_from_civil(@n[0 .. 2], 23, 59, 60, 0); 1 };
    $bad++ if eval { Time::Keeper::_civil_from_instant($end, 1_000_000_000); 1 };
    $bad++ if eval { Time::Keeper::_civil_from_instant($end - 2, 1_000_000_000); 1 };
    $bad++ if eval { Time::Keeper::_civil_from_instant($end - 1, 2_000_000_000); 1 };
}
is($bad, 0, 'each of the 27 is 23:59:60 on its day and no other second');

ok(!eval { Time::Keeper::_instant_from_civil(2026, 10, 15, 23, 59, 60, 0); 1 }, 'no leap second today');
ok(!eval { Time::Keeper::_instant_from_civil(2016, 12, 31, 23, 58, 60, 0); 1 }, 'nor at 23:58:60');
ok(!eval { Time::Keeper::_instant_from_civil(2016, 12, 31, 23, 59, 61, 0); 1 }, 'nor a second 61');
ok(!eval { Time::Keeper::_instant_from_civil(1971, 12, 31, 23, 59, 60, 0); 1 }, 'nor at the end of 1971, when TAI - UTC became 10');

my $l2016 = 1483228799;
is_deeply([Time::Keeper::_instant_from_local(2017, 1, 1, 8, 59, 60, 0, 32400)], [$l2016, 1_000_000_000],
          'in Tokyo it was 08:59:60 on 1 January');
is_deeply([Time::Keeper::_instant_from_local(2016, 12, 31, 18, 59, 60, 0, -18000)], [$l2016, 1_000_000_000],
          'in New York 18:59:60 on 31 December');
ok(!eval { Time::Keeper::_instant_from_local(2016, 12, 31, 23, 59, 60, 0, 32400); 1 }, 'and not at 23:59:60 in Tokyo');

is(Time::Keeper::_leaps_before($ends[0] - 1), 0, 'no leap seconds before the first ended');
is(Time::Keeper::_leaps_before($ends[0]), 1, 'one from the midnight it ended');
is(Time::Keeper::_leaps_before($ends[-1] - 1), 26, '26 before the last ended');
is(Time::Keeper::_leaps_before($ends[-1]), 27, 'and 27 since');
ok(Time::Keeper::_is_leap_day_end($l2016), '23:59:59 on 31 December 2016 was followed by a leap second');
ok(!Time::Keeper::_is_leap_day_end($l2016 + 1), 'midnight was not');
ok(!Time::Keeper::_is_leap_day_end($l2016 - 86400), 'nor was the day before\'s');

is(Time::Keeper::_tai_minus_utc(63071999, 0), undef, 'no TAI - UTC before 1972');
is(Time::Keeper::_tai_minus_utc(63072000, 0), 10, '10 seconds from 1972');
is(Time::Keeper::_tai_minus_utc($ends[0] - 1, 0), 10, 'until the first leap second');
is(Time::Keeper::_tai_minus_utc($ends[0], 0), 11, 'and 11 after it');
is(Time::Keeper::_tai_minus_utc($l2016, 999_999_999), 36, '36 at 23:59:59.999999999 on 31 December 2016');
is(Time::Keeper::_tai_minus_utc($l2016, 1_500_000_000), 36, 'still 36 during 23:59:60');
is(Time::Keeper::_tai_minus_utc($l2016 + 1, 0), 37, '37 from midnight');
is(Time::Keeper::_tai_minus_utc(1792022400, 0), 37, 'and 37 now');

sub abs_ { join ' ', Time::Keeper::_minus_absolute(@_) }
is(abs_($l2016 + 1, 0, $l2016, 0), '2 0', '23:59:59 to midnight is two seconds, over a leap second');
is(abs_($l2016 + 1, 0, $l2016, 1_000_000_000), '1 0', '23:59:60 to midnight is one');
is(abs_($l2016, 1_000_000_000, $l2016, 0), '1 0', '23:59:59 to 23:59:60 is one');
is(abs_($l2016, 1_500_000_000, $l2016, 750_000_000), '0 750000000', 'a fraction across it');
is(abs_($l2016, 0, $l2016 + 1, 0), '-2 0', 'and backwards, negative');
is(abs_($l2016, 750_000_000, $l2016, 1_000_000_000), '-1 750000000', 'a quarter of a second back is -1 and three quarters');
is(abs_($l2016 + 1, 0, $l2016 + 1 - 366 * 86400, 0), 366 * 86400 + 1 . ' 0', '2016 lasted 366 days and a second');
is(abs_($l2016 + 1 - 86400, 0, $l2016 + 1 - 2 * 86400, 0), '86400 0', 'and 30 December an ordinary day');
is(abs_($ends[-1], 0, 63072000, 0), ($ends[-1] - 63072000 + 27) . ' 0', '1972 to 2017: the POSIX difference and 27');
is(abs_(0, 0, -86400, 0), '86400 0', 'before 1972 nothing is added');

{
    my @rd = Time::Keeper::_day_numbers($l2016, 1_250_000_000);
    is_deeply([@rd[1, 2]], [86400, 250_000_000], 'Rata Die counts 23:59:60.25 as second 86400 of its day');
}

done_testing;
