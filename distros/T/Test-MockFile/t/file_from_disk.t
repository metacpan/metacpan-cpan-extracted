#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;

use File::Temp qw/tempfile/;
use File::Slurper ();

use Test::MockFile;    # Everything below this can have its open overridden.

my $fake_file_contents = "abc\n" . ( "x" x 20 ) . "\n";

my ( $fh_real, $file_on_disk ) = tempfile();
print $fh_real $fake_file_contents;
close $fh_real;

my ( undef, $fake_file_name ) = tempfile();
unlink $fake_file_name;

my $mock = Test::MockFile->file_from_disk( $fake_file_name, $file_on_disk );
is( open( my $fh, "<", $fake_file_name ), 1, "open fake file for read" );
is( <$fh>, "abc\n", "Read line 1." );
is( <$fh>, ( "x" x 20 ) . "\n", "Read line 2." );
close $fh;
undef $fh;

is( open( $fh, ">", $fake_file_name ), 1, "open fake file for write" );
print $fh "def";
close $fh;
undef $fh;
is( $mock->contents, "def", "file is written to" );
undef $mock;

is( File::Slurper::read_binary($file_on_disk), $fake_file_contents, "The original file was unmodified" );

done_testing();

