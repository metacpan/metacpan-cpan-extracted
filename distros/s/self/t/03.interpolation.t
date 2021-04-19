use strict;
use warnings;
use lib 't/lib';
use InterpolationTest;

use Test2::V0;
plan tests => 2;

my $t = InterpolationTest->new;

for (1..2) {
    my $m = "test_$_";
    is($t->$m, "hello");
}
