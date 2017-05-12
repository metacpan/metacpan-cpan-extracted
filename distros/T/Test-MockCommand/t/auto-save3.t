# -*- perl -*-
# test that auto save only happens when enabled

use Test::More tests => 3;
use warnings;
use strict;

BEGIN { use_ok 'Test::MockCommand', record => 'test.db'; }

# turn off autosave
Test::MockCommand->auto_save(undef);

unlink 'test.db';
ok ! -f 'test.db', 'check that test.db does not exist';
ok ! defined Test::MockCommand->auto_save(), 'check autosave is off';

# nothing should be created when this script exits, as autosave is off
