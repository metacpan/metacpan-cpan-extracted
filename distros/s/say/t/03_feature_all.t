use strict;
use warnings;
use Test::More;

use say ':5.10';

if( $] < 5.010 ) {
    plan skip_all => 'no support feature';
}

eval <<'_EVAL_';
    state $foo = 1;

    given ($foo) {
        when (1) { ok 1 }
        default  { say "default" }
    }
_EVAL_

ok !$@;

done_testing;
