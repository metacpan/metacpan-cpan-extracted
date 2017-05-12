#perl -T

use strict;
use warnings;

use Test::More tests => 2 + 1;
use Test::NoWarnings;

BEGIN {
    use_ok('Tie::Sub');
}

tie my %sub, 'Tie::Sub', sub {
    my ($p1, $p2) = @_;

    return [$p1, $p2];
};
is_deeply(
    $sub{ [ 1, 2 ] },
    [ 1, 2 ],
    'check subroutine 2 parmams, 2 returns',
);
