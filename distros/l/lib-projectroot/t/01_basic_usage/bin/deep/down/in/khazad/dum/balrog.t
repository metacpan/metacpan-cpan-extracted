#!/usr/bin/perl
use Test::More;
use lib qw(t);
use testlib qw(cleanup);

my @pre_inc;
BEGIN {
    @pre_inc = @INC;
}

use lib::projectroot qw(lib);

my @post_inc = @INC;
is(scalar @post_inc, scalar @pre_inc + 1, 'added one element to @INC');
is(cleanup($post_inc[0]), 't/01_basic_usage/lib', 'lib added to @INC');

done_testing();

