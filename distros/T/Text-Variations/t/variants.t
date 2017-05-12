use strict;
use warnings;

use Test::More tests => 2;

use_ok 'Text::Variations';

my $tv = Text::Variations->new(
    [ 'one', 'two', 'three' ],
    ' ', [ 'alpha', 'beta', 'gamma' ],
);

# generate 1000 strings and check that the mix is correct
my %counts = ();
$counts{"$tv"}++ for 1 .. 10000;

# use Data::Dumper;
# warn Dumper(\%counts);

# check that we have all the keys we would expect
is_deeply [ sort keys %counts ],
    [
    'one alpha',
    'one beta',
    'one gamma',
    'three alpha',
    'three beta',
    'three gamma',
    'two alpha',
    'two beta',
    'two gamma',
    ],
    "have all expected keys";

