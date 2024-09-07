use strict;
use warnings;
use Test::More;

use say qw/state/;

if( $] < 5.010 ) {
    plan skip_all => 'no support feature';
}

eval <<'_EVAL_';
    state $foo = 1;
_EVAL_

ok !$@;

done_testing;
