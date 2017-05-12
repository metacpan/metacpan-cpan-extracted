use strict;
use warnings;
use Test::More;

use lib 't/lib';
use FakeGit '1.2.3';

use Test::Requires::Git;

plan 'no_plan';

# ok
test_requires_git version_gt => '1.2.0';

# skip
test_requires_git
  version_lt => '1.2.1',
  version_eq => '1.2.3',
  version_ne => '1.2.3';

fail('cannot happen');
