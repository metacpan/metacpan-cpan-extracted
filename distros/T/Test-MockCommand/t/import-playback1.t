# -*- perl -*-
# test the import 'playback' option, part 1 (set up testdb.dat)

use Test::More tests => 1;
use warnings;
use strict;

BEGIN { use_ok 'Test::MockCommand'; }

Test::MockCommand->recording(1);
system('echo test');
Test::MockCommand->auto_save('testdb.dat');
