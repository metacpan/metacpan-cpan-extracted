# -*- perl -*-
# test that auto save actually happens

use Test::More tests => 2;
use warnings;
use strict;

BEGIN { use_ok 'Test::MockCommand', record => 'test.db'; }

unlink 'test.db';
ok ! -f 'test.db', 'check that test.db does not exist';

# test.db should be created when this script exits
