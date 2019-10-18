#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use File::Temp qw/tempfile tempdir/;
use File::Slurper ();

use Fcntl;

#use Errno qw/ENOENT EBADF/;

use Test::MockFile;    # Everything below this can have its open overridden.
my ( undef, $filename ) = tempfile();
unlink $filename;

{
    note "-------------- REAL MODE --------------";
    is( sysopen( my $fh, $filename, O_WRONLY | O_CREAT | O_EXCL | O_TRUNC ), 1, "Sysopen for write" );
    my $str = join( "", "a" .. "z" );
    is( syswrite( $fh, $str ), 26, "2 arg syswrite" );
    my $str_cap = join( "", "A" .. "Y" );
    is( syswrite( $fh, $str_cap, 13 ), 13, "3 arg syswrite" );
    is( syswrite( $fh, $str_cap, 12, 13 ), 12, "4 arg syswrite" );
    is( close $fh, 1, "sysclose \$fh" );
    is( File::Slurper::read_binary($filename), $str . $str_cap, "file contents match what was written" );
    unlink $filename;
}

{
    my $str     = join( "", "a" .. "z" );
    my $str_cap = join( "", "A" .. "Y" );

    note "-------------- MOCK MODE --------------";
    my $bar = Test::MockFile->file($filename);
    is( sysopen( my $fh, $filename, O_WRONLY | O_CREAT | O_EXCL | O_TRUNC ), 1, "Sysopen for write" );

    is( syswrite( $fh, $str ), 26, "2 arg syswrite" );
    is( syswrite( $fh, $str_cap, 13 ), 13, "3 arg syswrite" );
    is( syswrite( $fh, $str_cap, 12, 13 ), 12, "4 arg syswrite" );
    is( close $fh, 1, "sysclose \$fh" );
    is( $bar->contents, $str . $str_cap, "Fake file contents match what was written" );
    undef $bar;
    ok( !-e $filename, "mocked $filename is not present after mock file goes offline" );
}
is( \%Test::MockFile::files_being_mocked, {}, "No mock files are in cache" ) or die;

{
    my $str     = join( "", "a" .. "z" );
    my $str_cap = join( "", "A" .. "Y" );

    note "-------------- REAL MODE --------------";
    File::Slurper::write_binary( $filename, $str_cap . $str );
    is( sysopen( my $fh, $filename, O_RDONLY | O_NOFOLLOW ), 1, "Sysopen for read" );
    my $buf = "blah";
    is( sysread( $fh, $buf, 2, 4 ), 2, "Read 2 into buf at EOL" );
    is( $buf, "blahAB", "Confirm 2 line read" );

    is( sysread( $fh, $buf, 2, 0 ), 2, "Read  into buf at pos 0 truncates the buffer." );
    is( $buf, "CD", "Confirm 2 line read" );

    $buf = "a" x 10;
    is( sysread( $fh, $buf, 0, 0 ), 0, "Read 0 into buf at pos 0 truncates the buffer completely." );
    is( $buf, "", "Buffer is clear" );

    $buf = "b" x 10;
    is( sysread( $fh, $buf, 2, 5 ), 2, "Read 2 into buf at pos 5 truncates after the buffer." );
    is( $buf, "bbbbbEF", "Line is as expected." );

    $buf = "c" x 2;
    is( sysread( $fh, $buf, 3, 6 ), 3, "Read 3 into buf after EOL for the buffer fills in zeroes." );
    is( $buf, "cc\0\0\0\0GHI", "Buffer has null bytes in the middle of it." );

    $buf = "d" x 5;
    is( seek( $fh, 49, 0 ), 1, "Seek to near EOF" );
    is( sysread( $fh, $buf, 4 ), 2, "Read 2 into buf since we're at EOF" );
    is( $buf, "yz", "Buffer is clear" );

    ok( seek( $fh, 0, 0 ), 0, "Seek to start of file returns true" );
    is( sysseek( $fh, 0, 0 ), "0 but true", "sysseek to start of file returns '0 but true' to make it so." );
    ok( sysseek( $fh, 0, 0 ), "sysseek to start of file returns true when checked with ok()" );
}

{
    my $str     = join( "", "a" .. "z" );
    my $str_cap = join( "", "A" .. "Y" );

    note "-------------- MOCK MODE --------------";
    my $bar = Test::MockFile->file( $filename, $str_cap . $str );
    is( sysopen( my $fh, $filename, O_RDONLY | O_NOFOLLOW ), 1, "Sysopen for read" );
    like( "$fh", qr/^IO::File=GLOB\(0x[0-9a-f]+\)$/, '$fh stringifies to a IO::File GLOB' );

    my $buf = "blah";
    is( sysread( $fh, $buf, 2, 4 ), 2, "Read 2 into buf at EOL" );
    is( $buf, "blahAB", "Confirm 2 line read" );

    is( sysread( $fh, $buf, 2, 0 ), 2, "Read  into buf at pos 0 truncates the buffer." );
    is( $buf, "CD", "Confirm 2 line read" );

    $buf = "a" x 10;
    is( sysread( $fh, $buf, 0, 0 ), 0, "Read 0 into buf at pos 0 truncates the buffer completely." );
    is( $buf, "", "Buffer is clear" );

    $buf = "b" x 10;
    is( sysread( $fh, $buf, 2, 5 ), 2, "Read 2 into buf at pos 5 truncates after the buffer." );
    is( $buf, "bbbbbEF", "Line is as expected." );

    $buf = "c" x 2;
    is( sysread( $fh, $buf, 3, 6 ), 3, "Read 3 into buf after EOL for the buffer fills in zeroes." );
    is( $buf, "cc\0\0\0\0GHI", "Buffer has null bytes in the middle of it." );

    $buf = "d" x 5;
    is( seek( $fh, 49, 0 ), 49, "Seek to near EOF" );
    is( sysread( $fh, $buf, 4 ), 2, "Read 2 into buf since we're at EOF" );
    is( $buf, "yz", "Buffer is clear" );

    ok( seek( $fh, 0, 0 ), 0, "Seek to start of file returns true" );
    is( sysseek( $fh, 0, 0 ), "0 but true", "sysseek to start of file returns '0 but true' to make it so." );
    ok( sysseek( $fh, 0, 0 ), "sysseek to start of file returns true when checked with ok()" );

    close $fh;
    undef $bar;
}

{
    my $str     = join( "", "a" .. "z" );
    my $str_cap = join( "", "A" .. "Y" );

    note "-------------- REAL MODE --------------";
    File::Slurper::write_binary( $filename, $str_cap . $str );
    is( sysopen( my $fh, $filename, O_RDONLY | O_NOFOLLOW ), 1, "Sysopen for read" );
    my $buf;
    is( sysread( $fh, $buf, 2 ), 2, "Read 2 into buf when buf is undef." );
    is( $buf, "AB", "Confirm 2 char is read" );
    unlink $filename;
}

{
    my $str     = join( "", "a" .. "z" );
    my $str_cap = join( "", "A" .. "Y" );

    note "-------------- MOCK MODE --------------";
    my $bar = Test::MockFile->file( $filename, $str_cap . $str );
    is( sysopen( my $fh, $filename, O_RDONLY | O_NOFOLLOW ), 1, "Sysopen for read" );
    my $buf;
    is( sysread( $fh, $buf, 2 ), 2, "Read 2 into buf when buf is undef." );
    is( $buf, "AB", "Confirm 2 char is read" );
}

is( \%Test::MockFile::files_being_mocked, {}, "No mock files are in cache" );

done_testing();
exit;
