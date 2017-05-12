use strict;
use warnings;
use Test::More;

use lib 't/lib';
use FakeGit '1.2.3';

use Test::Requires::Git;

# run some tests before
pass('initial test');

# ok
test_requires_git version_gt => 'v1.2.0';

# skip
test_requires_git version_lt => '1.2.1';

fail('cannot happen');

done_testing;
