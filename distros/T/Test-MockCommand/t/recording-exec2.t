# -*- perl -*-
# test exec() recording functionality, part 2 (check exec() was recorded)

use Test::More tests => 3;
use warnings;
use strict;

BEGIN { use_ok 'Test::MockCommand'; }

# load previous test's autosaved db
Test::MockCommand->load('testdb.dat');

# check that the command got recorded correctly
my ($out) = Test::MockCommand->find(function => 'exec',
                                    command  => 'echo test exec');
ok $out, 'recorded exec() 1-arg';

# check that it's the only thing that got recorded
is scalar(Test::MockCommand->all_commands()), 1, 'only 1 recorded command';

die "deleting file: $!" unless unlink 'testdb.dat';
