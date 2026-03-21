#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Test::MockFile qw< nostrict >;

# Assures testers don't mess up with our hard coded perms expectations.
umask 022;

note "blocks() calculation";

{
    note "empty file has 0 blocks";
    my $mock = Test::MockFile->file('/tmp/empty');
    is $mock->blocks, 0, "non-existent file: blocks is 0";

    my $mock2 = Test::MockFile->file( '/tmp/empty_content', '' );
    is $mock2->blocks, 0, "empty string content: blocks is 0";
}

{
    note "small file has 1 block";
    my $mock = Test::MockFile->file( '/tmp/small', 'x' );
    is $mock->blocks, 1, "1-byte file: 1 block";

    my $mock2 = Test::MockFile->file( '/tmp/small2', 'x' x 100 );
    is $mock2->blocks, 1, "100-byte file: 1 block";
}

{
    note "file exactly at blksize boundary";
    my $mock = Test::MockFile->file( '/tmp/exact', 'x' x 4096 );
    is $mock->blocks, 1, "4096-byte file with 4096 blksize: exactly 1 block";
}

{
    note "file one byte over blksize boundary";
    my $mock = Test::MockFile->file( '/tmp/over', 'x' x 4097 );
    is $mock->blocks, 2, "4097-byte file: 2 blocks";
}

{
    note "file at exactly 2x blksize";
    my $mock = Test::MockFile->file( '/tmp/double', 'x' x 8192 );
    is $mock->blocks, 2, "8192-byte file with 4096 blksize: exactly 2 blocks";
}

{
    note "custom blksize";
    my $mock = Test::MockFile->file( '/tmp/custom_blk', 'x' x 1024, { blksize => 512 } );
    is $mock->blocks, 2, "1024-byte file with 512 blksize: 2 blocks";

    my $mock2 = Test::MockFile->file( '/tmp/custom_blk2', 'x' x 513, { blksize => 512 } );
    is $mock2->blocks, 2, "513-byte file with 512 blksize: 2 blocks (ceiling)";

    my $mock3 = Test::MockFile->file( '/tmp/custom_blk3', 'x' x 512, { blksize => 512 } );
    is $mock3->blocks, 1, "512-byte file with 512 blksize: exactly 1 block";
}

{
    note "blocks from stat()";
    my $mock = Test::MockFile->file( '/tmp/stat_blocks', 'hello' );
    my @stat = stat('/tmp/stat_blocks');
    is $stat[12], 1, "stat[12] (blocks) is 1 for a 5-byte file";

    my $mock_empty = Test::MockFile->file( '/tmp/stat_empty', '' );
    my @stat_e = stat('/tmp/stat_empty');
    is $stat_e[12], 0, "stat[12] (blocks) is 0 for an empty file";
}

{
    note "directory blocks";
    my $mock = Test::MockFile->new_dir('/tmp/test_dir_blocks');
    # Directories have contents = undef, size depends on is_dir path
    # Just verify it doesn't die
    my @stat = stat('/tmp/test_dir_blocks');
    ok defined $stat[12], "stat[12] defined for directory";
}

done_testing();
exit;
