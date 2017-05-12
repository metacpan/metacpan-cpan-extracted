# -*- perl -*-
# test basic recording functionality - system(), readpipe() and open()

use Test::More tests => 11;
use warnings;
use strict;

BEGIN { use_ok 'Test::MockCommand'; }

# turn on recording
Test::MockCommand->recording(1);

# system() with scalar arg
system('dir');
my $dir_exit = $?;

# system() with array args
system('echo test');
my $test_exit = $?;

# readpipe()
my $hello_out = join '', readpipe('echo hello');
my $hello_exit = $?;

# open() from pipe
my $world_out;
if (open my $fh, "echo world |") {
    $world_out = join '', <$fh>;
    close $fh;
}

# turn off recording
Test::MockCommand->recording(0);

# run another command, it shouldn't be recorded.
# we'll get a carp about there being no suitable result to
# emulate it, so silence that with a __WARN__ handler.
$SIG{'__WARN__'} = sub {};
system('echo bogus');
delete $SIG{'__WARN__'};

# check that the commands above got recorded correctly
my $out;

# check we have an entry for system() with scalar arg
($out) = Test::MockCommand->find(function => 'system', command => 'dir');
ok $out, 'recorded system() 1-arg';
is $out->exit_code(), $dir_exit, 'recorded system() 1-arg exit code';

# check we have an entry for system() with array args
($out) = Test::MockCommand->find(function => 'system', command => 'echo test');
ok $out, 'recorded system() multi-arg';
is $out->exit_code(), $test_exit, 'recorded system() multi-arg exit code';

# check we have an entry for readpipe()
($out) = Test::MockCommand->find(function => 'readpipe', command => 'echo hello');
ok $out, 'recorded readpipe()';
is $out->return_value(), $hello_out, 'recorded readpipe() output';
is $out->exit_code(), $hello_exit, 'recorded readpipe() exit code';

# check we have an entry for open()
($out) = Test::MockCommand->find(function => 'open', command => 'echo world');
ok $out, 'recorded open()';
is $out->output_data(), $world_out, 'recorded open() output';

# check that 'echo bogus' wasn't recorded
is 4, Test::MockCommand->all_commands(), 'no commands while recording off';
