# -*- perl -*-
# test that playback doesn't really invoke commands

use Test::More tests => 2;
use warnings;
use strict;

BEGIN { use_ok 'Test::MockCommand'; }

# turn on recording
Test::MockCommand->recording(1);

# list directory without 'testfile.dat'
unlink 'testfile.dat';
my $list = readpipe('dir');

# go into playback mode
Test::MockCommand->recording(0);

# create 'testfile.dat' file in the directory
die "create file: $!" unless open my $fh, '>testfile.dat';
die "close file: $!" unless close $fh;

# run 'dir' again while extra file is in the directory. should pull
# result from store, not real life, thus should not see the extra file
my $again = readpipe('dir');
is $list, $again, 'dir comes from within';

die "delete file: $!" unless unlink 'testfile.dat';
