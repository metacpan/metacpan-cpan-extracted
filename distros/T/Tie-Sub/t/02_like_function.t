#perl -T

use strict;
use warnings;

use Test::More tests => 2 + 1;
use Test::NoWarnings;

BEGIN {
    use_ok('Tie::Sub');
}

tie my %sub, 'Tie::Sub', sub{ shift() + 1 };
cmp_ok(
    $sub{1},
    '==',
    '2',
    'check function',
);
