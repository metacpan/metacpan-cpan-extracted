#!/usr/bin/perl

use warnings;
use strict;

use Test::More qw(no_plan);

my $otime = time;
use Time::Mock throttle => 100, offset => 10_000;
is(Time::Mock->throttle, 100);
is(Time::Mock->offset, 10_000);
my $start = time;
cmp_ok($start, '>=', $otime + 10_000);
sleep(1);
my $end = time;
cmp_ok($end, '>=', $start + 1);
cmp_ok($end, '<=', $start + 2);

eval {Time::Mock->import(foo => 1)};
like($@, qr/^unknown method 'foo'/);
eval {Time::Mock->import('blah')};
like($@, qr/^odd number of elements/);

# vim:ts=2:sw=2:et:sta
