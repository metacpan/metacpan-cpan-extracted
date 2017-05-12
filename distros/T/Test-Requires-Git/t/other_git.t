use strict;
use warnings;
use Test::More;

use Test::Requires::Git -nocheck;

plan tests => 2;

# run some tests before
pass('initial test');

test_requires_git git => '/zlonk/bam/kapow';

fail('cannot happen');
