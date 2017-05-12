# -*- perl -*-
# test the simple status functions, recording() and auto_save()

use Test::More tests => 7;
use warnings;
use strict;

BEGIN { use_ok 'Test::MockCommand'; }

ok(! Test::MockCommand->recording(), 'recording off by default');
Test::MockCommand->recording(1);
ok(Test::MockCommand->recording(), 'recording can be turned on');
Test::MockCommand->recording(0);
ok(!Test::MockCommand->recording(), 'recording can be turned off');

ok(! defined Test::MockCommand->auto_save(), 'auto-save off by default');
Test::MockCommand->auto_save('test.db');
is(Test::MockCommand->auto_save(), 'test.db', 'auto_save can be turned on');
Test::MockCommand->auto_save(undef);
ok(! defined Test::MockCommand->auto_save(), 'auto_save can be turned off');
