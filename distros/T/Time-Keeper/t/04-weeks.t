#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use POSIX ();

use Time::Keeper;

my %weeks53 = map { $_ => 1 } 2004, 2009, 2015, 2020, 2026, 2032;
for my $y (2000 .. 2035) {
    my ($wy, $w) = Time::Keeper::_week_info($y, 12, 28);
    is($w, $weeks53{$y} ? 53 : 52, "$y has " . ($weeks53{$y} ? 53 : 52) . ' ISO weeks');
}

is_deeply([(Time::Keeper::_week_info(2021, 1, 1))[0, 1]], [2020, 53], '2021-01-01 is in week 53 of 2020');
is_deeply([(Time::Keeper::_week_info(2023, 1, 1))[0, 1]], [2022, 52], '2023-01-01 is in week 52 of 2022');
is_deeply([(Time::Keeper::_week_info(2024, 12, 30))[0, 1]], [2025, 1], '2024-12-30 is in week 1 of 2025');
is_deeply([(Time::Keeper::_week_info(2026, 1, 1))[0, 1]], [2026, 1], '2026-01-01, a Thursday, is in week 1 of 2026');

is_deeply([(Time::Keeper::_week_info(2026, $_->[0], $_->[1]))[4, 5]], [$_->[2], $_->[3]],
          "$_->[0]/$_->[1] is in quarter $_->[2], day $_->[3]")
    for [1, 1, 1, 1], [3, 31, 1, 90], [4, 1, 2, 1], [6, 30, 2, 91], [7, 1, 3, 1],
        [9, 30, 3, 92], [10, 15, 4, 15], [12, 31, 4, 92];
is((Time::Keeper::_week_info(2024, 3, 31))[5], 91, 'a leap year\'s first quarter has 91 days');

# Against the C library's strftime for every day from 1970 to 2100: %G and %V
# are ISO 8601, %U and %W the week numbers. gmtime's own fields are passed
# in, so nothing here depends on the local zone.
my ($bad, $n) = (0, 0);
my $z0 = Time::Keeper::_days_from_civil(1970, 1, 1);
my $z1 = Time::Keeper::_days_from_civil(2100, 12, 31);
SKIP: {
    skip 'gmtime does not reach 2100 on this perl', 1
        unless defined((gmtime(4_133_894_400))[5]) && (gmtime(4_133_894_400))[5] == 200;
    for my $z ($z0 .. $z1) {
        my @g = gmtime($z * 86400);
        my $want = POSIX::strftime('%G %V %U %W', @g);
        my ($y, $m, $d) = ($g[5] + 1900, $g[4] + 1, $g[3]);
        my ($wy, $w, $u, $wk) = Time::Keeper::_week_info($y, $m, $d);
        my $got = sprintf '%d %02d %02d %02d', $wy, $w, $u, $wk;
        $n++;
        if ($got ne $want) {
            diag("$y-$m-$d: got $got, strftime says $want") if $bad < 5;
            $bad++;
        }
    }
    is($bad, 0, "ISO week, %U and %W agree with strftime on all $n days from 1970 to 2100");
}

done_testing;
