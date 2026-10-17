#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Time::Keeper;

my $before = time;
my ($sec, $nsec) = Time::Keeper::_now();
my $after = time;

cmp_ok($sec, '>=', $before, 'now is not before time() was');
cmp_ok($sec, '<=', $after, 'nor after');
cmp_ok($nsec, '>=', 0, 'its nanoseconds are not negative');
cmp_ok($nsec, '<', 1_000_000_000, 'and less than a second');

my $res = Time::Keeper::_now_resolution();
ok($res == 1 || $res == 100 || $res == 1000, "a resolution of $res ns");
is($nsec % $res, 0, 'and the nanoseconds are a multiple of it');

my @seen = map { join '.', Time::Keeper::_now() } 1 .. 1000;
my %distinct = map { $_ => 1 } @seen;
cmp_ok(scalar(keys %distinct), '>', 1, 'the clock moves within a thousand reads');

diag("clock resolution ${res}ns");

done_testing;
