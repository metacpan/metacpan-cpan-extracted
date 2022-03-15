#!/usr/bin/perl
use Test::More;
use lib qw(t);
use testlib qw(cleanup);

my @pre_inc;
BEGIN {
    @pre_inc = @INC;
}

use lib::projectroot qw(lib);
lib::projectroot->load_extra(qw(DarkPAN));

my @post_inc = @INC;
is(scalar @post_inc, scalar @pre_inc + 2, 'added 2 element to @INC (1 lib, 1 extra)');
like(cleanup($post_inc[0]), qr{/03_extra/MyProject/lib$}, 'lib added to @INC');

like(cleanup($post_inc[-1]), qr{/03_extra/DarkPAN/lib$}, 'extra added to @INC');

done_testing();

