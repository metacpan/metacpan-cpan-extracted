# -*- perl -*-
# test import line magic works for 'record'

use Test::More tests => 3;
use warnings;
use strict;

BEGIN { use_ok 'Test::MockCommand', record => 'test.db'; }
ok(Test::MockCommand->recording(), 'recording enabled by import');
is(Test::MockCommand->auto_save(), 'test.db', 'auto_save set by import');

# avoid actually creating the autosave file
Test::MockCommand->auto_save(undef);
