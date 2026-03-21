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

use Test::MockFile qw< nostrict >;    # Everything below this can have its open overridden.
my ( undef, $filename ) = tempfile();
unlink $filename;

{
    note "-------------- REAL MODE --------------";
    is( sysopen( my $fh, $filename, O_WRONLY | O_CREAT | O_EXCL | O_TRUNC ), 1, "Sysopen for write" );
    my $str = join( "", "a" .. "z" );
    is( syswrite( $fh, $str ), 26, "2 arg syswrite" );
    my $str_cap = join( "", "A" .. "Y" );
    is( syswrite( $fh, $str_cap, 13 ),         13,              "3 arg syswrite" );
    is( syswrite( $fh, $str_cap, 12, 13 ),     12,              "4 arg syswrite" );
    is( close $fh,                             1,               "sysclose \$fh" );
    is( File::Slurper::read_binary($filename), $str . $str_cap, "file contents match what was written" );
    unlink $filename;
}

{
    my $str     = join( "", "a" .. "z" );
    my $str_cap = join( "", "A" .. "Y" );

    note "-------------- MOCK MODE --------------";
    my $bar = Test::MockFile->file($filename);
    is( sysopen( my $fh, $filename, O_WRONLY | O_CREAT | O_EXCL | O_TRUNC ), 1, "Sysopen for write" );

    is( syswrite( $fh, $str ),             26,              "2 arg syswrite" );
    is( syswrite( $fh, $str_cap, 13 ),     13,              "3 arg syswrite" );
    is( syswrite( $fh, $str_cap, 12, 13 ), 12,              "4 arg syswrite" );
    is( close $fh,                         1,               "sysclose \$fh" );
    is( $bar->contents,                    $str . $str_cap, "Fake file contents match what was written" );
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
    is( sysread( $fh, $buf, 2, 4 ), 2,        "Read 2 into buf at EOL" );
    is( $buf,                       "blahAB", "Confirm 2 line read" );

    is( sysread( $fh, $buf, 2, 0 ), 2,    "Read  into buf at pos 0 truncates the buffer." );
    is( $buf,                       "CD", "Confirm 2 line read" );

    $buf = "a" x 10;
    is( sysread( $fh, $buf, 0, 0 ), 0,  "Read 0 into buf at pos 0 truncates the buffer completely." );
    is( $buf,                       "", "Buffer is clear" );

    $buf = "b" x 10;
    is( sysread( $fh, $buf, 2, 5 ), 2,         "Read 2 into buf at pos 5 truncates after the buffer." );
    is( $buf,                       "bbbbbEF", "Line is as expected." );

    $buf = "c" x 2;
    is( sysread( $fh, $buf, 3, 6 ), 3,               "Read 3 into buf after EOL for the buffer fills in zeroes." );
    is( $buf,                       "cc\0\0\0\0GHI", "Buffer has null bytes in the middle of it." );

    $buf = "d" x 5;
    is( seek( $fh, 49, 0 ),      1,    "Seek to near EOF" );
    is( sysread( $fh, $buf, 4 ), 2,    "Read 2 into buf since we're at EOF" );
    is( $buf,                    "yz", "Buffer is clear" );

    ok( seek( $fh, 0, 0 ), 0, "Seek to start of file returns true" );
    is( sysseek( $fh, 0, 0 ), "0 but true", "sysseek to start of file returns '0 but true' to make it so." );
    ok( sysseek( $fh, 0, 0 ), "sysseek to start of file returns true when checked with ok()" );

    ok( sysseek( $fh, 5,  0 ), "sysseek to position 5 returns true." );
    ok( sysseek( $fh, 10, 1 ), "Seek 10 bytes forward from the current position." );
    is( sysseek( $fh, 0,  1 ), 15, "Current position is 15 bytes from start." );

    $buf = "";
    is( sysread( $fh, $buf, 2, 0 ), 2, "Read 2 bytes from current position (15)." );
    is( $buf, "PQ", "Line is as expected." );

    ok( sysseek( $fh, -5, 2 ),     "Seek 5 bytes back from end of file." );
    is( sysseek( $fh, 0,  1 ), 46, "Current position is 46 bytes from start." );

    $buf = "";
    is( sysread( $fh, $buf, 3, 0 ), 3, "Read 3 bytes from current position (46)." );
    is( $buf, "vwx", "Line is as expected." );
}

{
    my $str     = join( "", "a" .. "z" );
    my $str_cap = join( "", "A" .. "Y" );

    note "-------------- MOCK MODE --------------";
    my $bar = Test::MockFile->file( $filename, $str_cap . $str );
    is( sysopen( my $fh, $filename, O_RDONLY | O_NOFOLLOW ), 1, "Sysopen for read" );
    like( "$fh", qr/^IO::File=GLOB\(0x[0-9a-f]+\)$/, '$fh stringifies to a IO::File GLOB' );

    my $buf = "blah";
    is( sysread( $fh, $buf, 2, 4 ), 2,        "Read 2 into buf at EOL" );
    is( $buf,                       "blahAB", "Confirm 2 line read" );

    is( sysread( $fh, $buf, 2, 0 ), 2,    "Read  into buf at pos 0 truncates the buffer." );
    is( $buf,                       "CD", "Confirm 2 line read" );

    $buf = "a" x 10;
    is( sysread( $fh, $buf, 0, 0 ), 0,  "Read 0 into buf at pos 0 truncates the buffer completely." );
    is( $buf,                       "", "Buffer is clear" );

    $buf = "b" x 10;
    is( sysread( $fh, $buf, 2, 5 ), 2,         "Read 2 into buf at pos 5 truncates after the buffer." );
    is( $buf,                       "bbbbbEF", "Line is as expected." );

    $buf = "c" x 2;
    is( sysread( $fh, $buf, 3, 6 ), 3,               "Read 3 into buf after EOL for the buffer fills in zeroes." );
    is( $buf,                       "cc\0\0\0\0GHI", "Buffer has null bytes in the middle of it." );

    $buf = "d" x 5;
    is( seek( $fh, 49, 0 ),      49,   "Seek to near EOF" );
    is( sysread( $fh, $buf, 4 ), 2,    "Read 2 into buf since we're at EOF" );
    is( $buf,                    "yz", "Buffer is clear" );

    ok( seek( $fh, 0, 0 ), 0, "Seek to start of file returns true" );
    is( sysseek( $fh, 0, 0 ), "0 but true", "sysseek to start of file returns '0 but true' to make it so." );
    ok( sysseek( $fh, 0, 0 ), "sysseek to start of file returns true when checked with ok()" );

    ok( sysseek( $fh, 5,  0 ), "sysseek to position 5 returns true." );
    ok( sysseek( $fh, 10, 1 ), "Seek 10 bytes forward from the current position." );
    is( sysseek( $fh, 0,  1 ), 15, "Current position is 15 bytes from start." );

    $buf = "";
    is( sysread( $fh, $buf, 2, 0 ), 2, "Read 2 bytes from current position (15)." );
    is( $buf, "PQ", "Line is as expected." );

    ok( sysseek( $fh, -5, 2 ),     "Seek 5 bytes back from end of file." );
    is( sysseek( $fh, 0,  1 ), 46, "Current position is 46 bytes from start." );

    $buf = "";
    is( sysread( $fh, $buf, 3, 0 ), 3, "Read 3 bytes from current position (46)." );
    is( $buf, "vwx", "Line is as expected." );

    {
        use Errno qw/EINVAL/;
        $! = 0;
        my $ret = sysseek( $fh, 10, 3 );
        ok( !$ret, "sysseek with invalid whence returns false" );
        is( $! + 0, EINVAL, "sysseek with invalid whence sets EINVAL" );
    }

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
    is( sysread( $fh, $buf, 2 ), 2,    "Read 2 into buf when buf is undef." );
    is( $buf,                    "AB", "Confirm 2 char is read" );
    unlink $filename;
}

{
    my $str     = join( "", "a" .. "z" );
    my $str_cap = join( "", "A" .. "Y" );

    note "-------------- MOCK MODE --------------";
    my $bar = Test::MockFile->file( $filename, $str_cap . $str );
    is( sysopen( my $fh, $filename, O_RDONLY | O_NOFOLLOW ), 1, "Sysopen for read" );
    my $buf;
    is( sysread( $fh, $buf, 2 ), 2,    "Read 2 into buf when buf is undef." );
    is( $buf,                    "AB", "Confirm 2 char is read" );
}

is( \%Test::MockFile::files_being_mocked, {}, "No mock files are in cache" );

{
    note "-------------- sysopen O_CREAT applies permissions from 4th arg --------------";

    my $mock = Test::MockFile->file($filename);
    ok( !-e $filename, "Mock file does not exist before sysopen" );

    is( sysopen( my $fh, $filename, O_CREAT | O_WRONLY, 0600 ), 1, "sysopen with O_CREAT and explicit perms" );
    ok( -e $filename, "Mock file exists after sysopen O_CREAT" );

    my @stat = stat($filename);
    my $got_perms = $stat[2] & 07777;
    my $expected  = 0600 & ~umask;
    is( $got_perms, $expected, sprintf( "File permissions set from sysopen arg: got %04o, expected %04o", $got_perms, $expected ) );

    close $fh;
    undef $mock;
}
is( \%Test::MockFile::files_being_mocked, {}, "No mock files are in cache after perms test" );

{
    note "-------------- sysopen O_CREAT without perms arg keeps default --------------";

    my $mock = Test::MockFile->file($filename);
    is( sysopen( my $fh, $filename, O_CREAT | O_WRONLY ), 1, "sysopen O_CREAT without 4th arg" );

    my @stat = stat($filename);
    my $got_perms = $stat[2] & 07777;
    my $default   = 0666 & ~umask;    # constructor default after umask
    is( $got_perms, $default, sprintf( "File permissions remain default: got %04o, expected %04o", $got_perms, $default ) );

    close $fh;
    undef $mock;
}
is( \%Test::MockFile::files_being_mocked, {}, "No mock files are in cache after default perms test" );

{
    note "-------------- sysopen O_CREAT on existing file does not change perms --------------";

    my $mock = Test::MockFile->file( $filename, "existing content" );
    my @stat_before = stat($filename);

    is( sysopen( my $fh, $filename, O_CREAT | O_WRONLY, 0600 ), 1, "sysopen O_CREAT on existing file" );

    my @stat_after = stat($filename);
    is( $stat_after[2], $stat_before[2], "Permissions unchanged when O_CREAT on existing file" );

    close $fh;
    undef $mock;
}
is( \%Test::MockFile::files_being_mocked, {}, "No mock files are in cache after existing file test" );

note "O_NOFOLLOW on a symlink returns ELOOP";
{
    use Errno qw/ELOOP/;

    my $target = Test::MockFile->file( '/nofollow_target', "data" );
    my $link   = Test::MockFile->symlink( '/nofollow_target', '/nofollow_link' );

    $! = 0;
    my $ret = sysopen( my $fh, '/nofollow_link', O_RDONLY | O_NOFOLLOW );
    ok( !$ret,          'sysopen with O_NOFOLLOW on symlink returns false' );
    is( $! + 0, ELOOP, 'sysopen with O_NOFOLLOW on symlink sets $! to ELOOP' );
}

note "sysopen on non-existent file without O_CREAT returns ENOENT for all modes";
{
    use Errno qw/ENOENT/;

    my $mock = Test::MockFile->file('/enoent_test');
    ok( !-e '/enoent_test', 'mock file does not exist' );

    # O_RDONLY without O_CREAT on non-existent file
    $! = 0;
    my $ret_ro = sysopen( my $fh_ro, '/enoent_test', O_RDONLY );
    ok( !$ret_ro,            'sysopen O_RDONLY on non-existent file returns false' );
    is( $! + 0, ENOENT,     'sysopen O_RDONLY on non-existent file sets ENOENT' );

    # O_WRONLY without O_CREAT on non-existent file
    $! = 0;
    my $ret_wo = sysopen( my $fh_wo, '/enoent_test', O_WRONLY );
    ok( !$ret_wo,            'sysopen O_WRONLY on non-existent file returns false' );
    is( $! + 0, ENOENT,     'sysopen O_WRONLY on non-existent file sets ENOENT' );

    # O_RDWR without O_CREAT on non-existent file
    $! = 0;
    my $ret_rw = sysopen( my $fh_rw, '/enoent_test', O_RDWR );
    ok( !$ret_rw,            'sysopen O_RDWR on non-existent file returns false' );
    is( $! + 0, ENOENT,     'sysopen O_RDWR on non-existent file sets ENOENT' );
}

note "sysopen O_WRONLY|O_CREAT on non-existent file succeeds (O_CREAT creates the file)";
{
    my $mock = Test::MockFile->file('/creat_test');
    ok( !-e '/creat_test', 'mock file does not exist before O_CREAT' );

    is( sysopen( my $fh, '/creat_test', O_WRONLY | O_CREAT ), 1, 'sysopen O_WRONLY|O_CREAT succeeds' );
    ok( -e '/creat_test', 'file exists after O_CREAT' );
    close $fh;
}

note "sysopen failure returns undef in list context (single-element list)";
{
    use Errno qw/ENOENT/;

    my $mock = Test::MockFile->file('/list_ctx_test');

    my @ret = sysopen( my $fh, '/list_ctx_test', O_RDONLY );
    is( scalar @ret, 1,          'sysopen failure returns one element in list context' );
    ok( !$ret[0],                'sysopen failure element is false' );
    ok( !defined $ret[0],        'sysopen failure element is undef (not "undef" string)' );
}

done_testing();
exit;
