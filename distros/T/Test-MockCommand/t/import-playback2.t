# -*- perl -*-
# test import line magic works for 'playback'

use Test::More tests => 4;
use warnings;
use strict;

BEGIN { use_ok 'Test::MockCommand', playback => 'testdb.dat'; }
ok(!Test::MockCommand->recording(), 'recording not enabled by import');
ok(!Test::MockCommand->auto_save(), 'auto_save not set by import');
is scalar(Test::MockCommand->find()), 1, 'testdb.dat was loaded';

unlink 'testdb.dat';
