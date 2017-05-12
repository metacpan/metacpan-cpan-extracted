# -*- perl -*-
# test recording possible in perl >= 5.9.5: qx// and `backticks`

use Test::More;
use warnings;
use strict;

BEGIN {
    if ($] < 5.009005) {
	plan skip_all => 'perl >= 5.9.5 required to test qx// and backticks';
    }
    else {
	plan tests => 7;
    }
}

BEGIN { use_ok 'Test::MockCommand'; }

# turn on recording
Test::MockCommand->recording(1);

# readpipe() via qx//
my $hello_out = qx/echo hello/;
my $hello_exit = $?;

# readpipe() via `backticks`
my $world_out = `echo world`;
my $world_exit = $?;

# turn off recording
Test::MockCommand->recording(0);

# check that the commands above got recorded correctly
my $out;

# check we have an entry for readpipe() via qx//
($out) = Test::MockCommand->find(function => 'readpipe', command => 'echo hello');
ok $out, 'recorded readpipe() via qx//';
is $out->return_value(), $hello_out, 'recorded readpipe() qx// output';
is $out->exit_code(), $hello_exit, 'recorded readpipe() qx// exit code';

# check we have an entry for readpipe() via backticks
($out) = Test::MockCommand->find(function => 'readpipe', command => 'echo world');
ok $out, 'recorded readpipe() via backticks';
is $out->return_value(), $world_out, 'recorded readpipe() backticks output';
is $out->exit_code(), $world_exit, 'recorded readpipe() backticks exit code';
