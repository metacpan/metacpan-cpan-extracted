use strict;
use warnings;
use Test::More;

use lib 't/lib';
use FakeGit '1.6.5';

use Test::Requires::Git;

plan tests => 3;

pass('initial pass');

test_requires_git version_gt => '1.7.0';

fail( 'cannot happen' );
fail( 'cannot happen either' );

