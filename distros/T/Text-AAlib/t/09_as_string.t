use strict;
use warnings;
use Test::More;

use Text::AAlib;

my $aa = Text::AAlib->new(
    width  => 100,
    height => 200,
);

can_ok $aa, "as_string";

done_testing;
