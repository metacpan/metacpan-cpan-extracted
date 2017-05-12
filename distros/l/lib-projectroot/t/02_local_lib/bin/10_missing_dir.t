#!/usr/bin/perl
use Test::More;
use lib qw(t);
use testlib qw(cleanup);
use Test::Output;

my @pre_inc;
BEGIN {
    @pre_inc = @INC;
}

stderr_like { eval "use lib::projectroot qw(lib local::lib=not-there)" } qr/Could not find root dir containing lib, not-there/, 'got warning during load';

my @post_inc = @INC;
is(scalar @post_inc, scalar @pre_inc, 'nothing added to @INC because not all dirs were found');

done_testing();

