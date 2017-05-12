use strict;
use warnings;
use Test::More;

use lib 't/lib';
use FakeGit 'broken';

use Test::Requires::Git -nocheck;

plan tests => 3;

pass('initial pass');

SKIP: {
    test_requires_git skip => 1;
    fail('cannot happen');
}

pass 'skipped one';
