use strict;
use warnings;

use Scalar::Util 'refaddr';

use Test::More tests => 3;

our $original;

BEGIN {
    $original = refaddr \&subtest;
    is $original => refaddr \&Test::More::subtest, "original is T::M, straight up";
}

# if there are no options, subtest is not replaced
use Test::Some '!foo';

isnt refaddr \&subtest => $original, "subtest replaced locally";
is refaddr \&Test::More::subtest => $original, "but NOT globally";



