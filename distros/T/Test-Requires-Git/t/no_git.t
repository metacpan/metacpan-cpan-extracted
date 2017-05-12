use strict;
use warnings;
use Test::More;

use lib 't/lib';
use FakeGit 'broken';

use Test::Requires::Git -nocheck;

plan tests => 1;

test_requires_git;

fail('cannot happen');
