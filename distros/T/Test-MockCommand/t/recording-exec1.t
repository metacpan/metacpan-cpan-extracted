# -*- perl -*-
# test exec() recording functionality, part 1 (use the exec function)

use Test::More tests => 1;
use warnings;
use strict;

BEGIN { use_ok 'Test::MockCommand'; }

# turn on recording to a file
Test::MockCommand->recording(1);
Test::MockCommand->auto_save('testdb.dat');

# run command using exec(), it should be substituted behind the scenes
# with system() followed by an autosave
exec('echo test exec');
