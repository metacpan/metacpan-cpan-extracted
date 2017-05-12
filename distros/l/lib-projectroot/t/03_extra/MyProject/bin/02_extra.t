#!/usr/bin/perl
use Test::More;
use lib qw(t);
use testlib qw(cleanup);

my @pre_inc;
BEGIN {
    @pre_inc = @INC;
}

use lib::projectroot qw(lib extra=DarkPAN);

my @post_inc = @INC;
is(scalar @post_inc, scalar @pre_inc + 2, 'added 2 element to @INC (1 lib, 1 extra)');
is(cleanup($post_inc[0]), 't/03_extra/MyProject/lib', 'lib added to @INC');

is(cleanup($post_inc[-1]), 't/03_extra/DarkPAN/lib', 'extra added to @INC');

done_testing();

