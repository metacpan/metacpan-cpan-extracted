use strict;
use lib 't/lib';
use InterpolationTest;

use Test::More tests => 2;

my $t = InterpolationTest->new;

for (1 .. 2) {
    my $m = "test_$_";
    is(eval "\$t->$m", "hello");
}
