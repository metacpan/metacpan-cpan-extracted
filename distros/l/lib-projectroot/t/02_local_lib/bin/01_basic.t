#!/usr/bin/perl
use Test::More;
use lib qw(t);
use testlib qw(cleanup);

my @pre_inc;
BEGIN {
    @pre_inc = @INC;
}

use lib::projectroot qw(lib local::lib=local);

my @post_inc = @INC;
is(scalar @post_inc, scalar @pre_inc + 6, 'added 6 element to @INC (1 lib, 5 local::lib)');
like(cleanup($post_inc[0]), qr{/02_local_lib/lib$}, 'lib added to @INC');
foreach my $i (1 .. 5) {
    like(cleanup($post_inc[$i]), qr{02_local_lib/local}, 'a local::lib dir added to @INC' );
}

done_testing();

