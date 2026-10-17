#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Time::Keeper;

my $K = 'Time::Keeper';
my $x = $K->new(year => 2026, month => 10, day => 15, hour => 9, zone => 'Asia/Tokyo');   # 00:00 UTC
my $y = $K->new(year => 2026, month => 10, day => 15, hour => 1, zone => 'Europe/London'); # 00:00 UTC
my $z = $K->new(year => 2026, month => 10, day => 15, hour => 0, nanosecond => 1);

ok($x == $y, 'the same instant in two zones is equal');
ok($x eq $y, 'with eq too');
ok(!($x != $y), 'and not unequal');
ok($x < $z, 'a nanosecond later is later');
ok($z > $y, 'from either side');
is($x <=> $z, -1, '<=> gives -1');
is($z <=> $x, 1, 'and 1');
is($x <=> $y, 0, 'and 0');
is_deeply([map { "$_" } sort { $a <=> $b } $z, $x, $K->min, $K->max],
          [map { "$_" } $K->min, $x, $z, $K->max], 'sort');

is("$x", '2026-10-15T09:00:00+09:00', 'a value in a string is its ISO 8601 form');
is($x->TO_JSON, "$x", 'TO_JSON is the same');
ok($x ? 1 : 0, 'a value is true');
ok($K->from_epoch(0) ? 1 : 0, 'even the epoch');

# Floating time is a wall-clock time: against anything, wall clocks compare.
{
    my $f = $K->new(year => 2026, month => 10, day => 15, hour => 9, zone => 'floating');
    ok($f == $x, 'floating 09:00 equals 09:00 in Tokyo');
    ok($f > $y, 'and is after 01:00 in London');
    ok($x == $f, 'from the other side too');
    ok($y < $f, 'both ways');
}

ok(!eval { my $r = $x < 5; 1 }, 'a value compared with a number');
like($@, qr/can be compared only with another Time::Keeper value/, 'is an error that says so');
ok(!eval { my $r = $x eq '2026-10-15T09:00:00+09:00'; 1 }, 'and with a string');

# A leap second sorts between the second before it and midnight.
{
    my $l = $K->new(year => 2016, month => 12, day => 31, hour => 23, minute => 59, second => 60, nanosecond => 5);
    my $before = $K->new(year => 2016, month => 12, day => 31, hour => 23, minute => 59, second => 59, nanosecond => 999_999_999);
    my $after = $K->new(year => 2017);
    ok($before < $l && $l < $after, '23:59:59.999999999 < 23:59:60.000000005 < midnight');
}

done_testing;
