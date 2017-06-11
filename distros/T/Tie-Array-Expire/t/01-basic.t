#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Tie::Array::Expire;
use Time::HiRes qw(sleep);

tie my @ary, 'Tie::Array::Expire', 0.15;

push @ary, 1, 2;
is_deeply([@ary], [1, 2]);
is(scalar(@ary), 2);

sleep 0.1;
is_deeply([@ary], [1, 2]);
is(scalar(@ary), 2);

unshift @ary, 3, 4;
is_deeply([@ary], [3, 4, 1, 2]);
is(scalar(@ary), 4);

sleep 0.1;
is_deeply([@ary], [3, 4]);
is(scalar(@ary), 2);

sleep 0.1;
is_deeply([@ary], []);
is(scalar(@ary), 0);

# XXX more tests: splice(), pop, shift, ...

done_testing;
