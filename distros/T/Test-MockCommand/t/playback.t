# -*- perl -*-
# test recording and playback

use Test::More tests => 9;
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

# open() from pipe, multiple lines
my $dir_out;
if (open my $fh, "dir |") {
    $dir_out = join '', <$fh>;
    close $fh;
}

# readpipe(), multiple lines
my $dir2_out = join '', readpipe('dir');
my $dir2_exit = $?;

# turn off recording
Test::MockCommand->recording(0);

# check that the commands above got recorded correctly
system('dir');
my $dir_exit2 = $?;
is $dir_exit2, $dir_exit, 'matching system:dir';

system('echo test');
my $test_exit2 = $?;
is $test_exit2, $test_exit, 'matching system:echo test';

my $hello_out2 = join '', readpipe('echo hello');
my $hello_exit2 = $?;
is $hello_out2, $hello_out, 'matching output readpipe:echo hello';
is $hello_exit2, $hello_exit, 'matching exit code readpipe:echo hello';

my $world_out2;
if (open my $fh, "echo world |") {
    $world_out2 = join '', <$fh>;
    close $fh;
}
is $world_out2, $world_out, 'matching output open:echo world';

my $dir_out2;
if (open my $fh, "dir |") {
    $dir_out2 = join '', <$fh>;
    close $fh;
}
is $dir_out2, $dir_out, 'matching output open:dir';

my $dir2_out2 = join '', readpipe('dir');
my $dir2_exit2 = $?;
is $dir2_out2, $dir2_out, 'matching output readpipe:dir';
is $dir2_exit, $dir2_exit, 'matching exit code readpipe:dir';
