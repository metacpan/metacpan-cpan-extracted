use strict;
use warnings;
use lib 't/lib';
use InterpolationTest;

use Test::More tests => 2;

my $t = InterpolationTest->new;

for (1..2) {
    my $m = "test_$_";
    is($t->$m, "hello");
}
