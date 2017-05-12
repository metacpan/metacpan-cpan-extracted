use strict;
use warnings;
use Test::More;

use lib 't/lib';
use FakeGit '1.2.3';

use Test::Requires::Git;

plan tests => 3;

# ok
test_requires_git
  version_gt => '1.2.0',
  version_lt => '1.3.0';

# skip
test_requires_git version_lt => '1.2.1';

fail('cannot happen');
