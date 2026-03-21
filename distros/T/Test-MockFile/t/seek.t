#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Errno qw( EINVAL );
use Fcntl qw( :seek O_RDONLY O_WRONLY O_CREAT O_TRUNC O_RDWR );

use Test::MockFile qw< nostrict >;

# File content used across tests: "ABCDEFGHIJ" (10 bytes)
my $content = "ABCDEFGHIJ";

{
    note "--- SEEK_SET (whence=0) ---";

    my $mock = Test::MockFile->file( '/fake/seek_set', $content );
    sysopen( my $fh, '/fake/seek_set', O_RDONLY ) or die;

    is( sysseek( $fh, 0, SEEK_SET ), "0 but true", "SEEK_SET to 0 returns '0 but true'" );

    is( sysseek( $fh, 5, SEEK_SET ), 5, "SEEK_SET to 5 returns 5" );
    my $buf = "";
    sysread( $fh, $buf, 3, 0 );
    is( $buf, "FGH", "Reading 3 bytes from position 5 gives FGH" );

    is( sysseek( $fh, 10, SEEK_SET ), 10, "SEEK_SET to 10 (EOF) returns 10" );

    is( sysseek( $fh, 11, SEEK_SET ), 11, "SEEK_SET beyond EOF succeeds (POSIX allows seeking past end)" );

    is( sysseek( $fh, -1, SEEK_SET ), 0, "SEEK_SET to negative returns 0 (failure)" );

    close $fh;
}

{
    note "--- SEEK_CUR (whence=1) ---";

    my $mock = Test::MockFile->file( '/fake/seek_cur', $content );
    sysopen( my $fh, '/fake/seek_cur', O_RDONLY ) or die;

    is( sysseek( $fh, 3, SEEK_SET ), 3, "Start at position 3" );
    is( sysseek( $fh, 4, SEEK_CUR ), 7, "SEEK_CUR +4 from 3 gives 7" );

    my $buf = "";
    sysread( $fh, $buf, 2, 0 );
    is( $buf, "HI", "Reading from position 7 gives HI" );

    # After sysread of 2 bytes, tell is at 9
    is( sysseek( $fh, -3, SEEK_CUR ), 6, "SEEK_CUR -3 from 9 gives 6" );

    is( sysseek( $fh, 0, SEEK_CUR ), 6, "SEEK_CUR 0 returns current position (6)" );

    # Try to seek before start of file
    is( sysseek( $fh, -100, SEEK_CUR ), 0, "SEEK_CUR before start of file returns 0" );

    # Try to seek beyond EOF
    is( sysseek( $fh, 100, SEEK_CUR ), 106, "SEEK_CUR beyond EOF succeeds (position 6 + 100 = 106)" );

    close $fh;
}

{
    note "--- SEEK_END (whence=2) ---";

    my $mock = Test::MockFile->file( '/fake/seek_end', $content );
    sysopen( my $fh, '/fake/seek_end', O_RDONLY ) or die;

    is( sysseek( $fh, 0, SEEK_END ), 10, "SEEK_END with offset 0 = EOF position (10)" );

    is( sysseek( $fh, -3, SEEK_END ), 7, "SEEK_END -3 gives position 7" );
    my $buf = "";
    sysread( $fh, $buf, 3, 0 );
    is( $buf, "HIJ", "Reading 3 bytes from position 7 gives HIJ" );

    is( sysseek( $fh, -10, SEEK_END ), "0 but true", "SEEK_END -10 gives position 0 ('0 but true')" );

    is( sysseek( $fh, -11, SEEK_END ), 0, "SEEK_END before start returns 0 (failure)" );

    is( sysseek( $fh, 1, SEEK_END ), 11, "SEEK_END +1 beyond file succeeds (10 + 1 = 11)" );

    close $fh;
}

{
    note "--- Invalid whence ---";

    my $mock = Test::MockFile->file( '/fake/seek_bad', $content );
    sysopen( my $fh, '/fake/seek_bad', O_RDONLY ) or die;

    # Invalid whence values should return failure and set EINVAL, not die.
    $! = 0;
    my $ret = sysseek( $fh, 0, 3 );
    ok( !$ret, "whence=3 returns false" );
    is( $! + 0, EINVAL, "whence=3 sets \$! to EINVAL" );

    $! = 0;
    $ret = sysseek( $fh, 0, -1 );
    ok( !$ret, "whence=-1 returns false" );
    is( $! + 0, EINVAL, "whence=-1 sets \$! to EINVAL" );

    $! = 0;
    $ret = sysseek( $fh, 0, 99 );
    ok( !$ret, "whence=99 returns false" );
    is( $! + 0, EINVAL, "whence=99 sets \$! to EINVAL" );

    close $fh;
}

{
    note "--- seek() via Perl builtin (not sysseek) ---";

    my $mock = Test::MockFile->file( '/fake/seek_builtin', $content );
    sysopen( my $fh, '/fake/seek_builtin', O_RDONLY ) or die;

    ok( seek( $fh, 5, SEEK_SET ), "seek() with SEEK_SET returns true" );
    is( sysseek( $fh, 0, SEEK_CUR ), 5, "tell position is 5 after seek()" );

    ok( seek( $fh, 2, SEEK_CUR ), "seek() with SEEK_CUR returns true" );
    is( sysseek( $fh, 0, SEEK_CUR ), 7, "tell position is 7 after relative seek()" );

    ok( seek( $fh, -2, SEEK_END ), "seek() with SEEK_END returns true" );
    is( sysseek( $fh, 0, SEEK_CUR ), 8, "tell position is 8 after SEEK_END -2" );

    close $fh;
}

{
    note "--- Empty file ---";

    my $mock = Test::MockFile->file( '/fake/seek_empty', "" );
    sysopen( my $fh, '/fake/seek_empty', O_RDONLY ) or die;

    is( sysseek( $fh, 0, SEEK_SET ), "0 but true", "SEEK_SET 0 on empty file returns '0 but true'" );
    is( sysseek( $fh, 0, SEEK_END ), "0 but true", "SEEK_END 0 on empty file returns '0 but true'" );
    is( sysseek( $fh, 0, SEEK_CUR ), "0 but true", "SEEK_CUR 0 on empty file returns '0 but true'" );
    is( sysseek( $fh, 1, SEEK_SET ), 1, "SEEK_SET 1 on empty file succeeds (past EOF allowed)" );

    close $fh;
}

{
    note "--- Seek after write ---";

    my $mock = Test::MockFile->file('/fake/seek_rw');
    sysopen( my $fh, '/fake/seek_rw', O_RDWR | O_CREAT | O_TRUNC ) or die;

    syswrite( $fh, "Hello World" );    # 11 bytes
    is( sysseek( $fh, 0, SEEK_SET ), "0 but true", "Seek back to start after write" );

    my $buf = "";
    sysread( $fh, $buf, 5, 0 );
    is( $buf, "Hello", "Read back what was written after seek" );

    is( sysseek( $fh, -5, SEEK_END ), 6, "SEEK_END -5 on written data gives position 6" );
    $buf = "";
    sysread( $fh, $buf, 5, 0 );
    is( $buf, "World", "Read 'World' from position 6" );

    close $fh;
}

{
    note "--- Seek past EOF then read (should get EOF) ---";

    my $mock = Test::MockFile->file( '/fake/seek_past_read', $content );
    sysopen( my $fh, '/fake/seek_past_read', O_RDONLY ) or die;

    is( sysseek( $fh, 50, SEEK_SET ), 50, "SEEK_SET to 50 (past 10-byte file) succeeds" );

    my $buf = "";
    my $nread = sysread( $fh, $buf, 10 );
    is( $nread, 0,  "sysread after seek past EOF returns 0 bytes" );
    is( $buf,   "", "buffer is empty after seek-past-EOF read" );

    ok( eof($fh), "eof() is true after seek past EOF" );

    close $fh;
}

{
    note "--- Seek past EOF then seek back and read ---";

    my $mock = Test::MockFile->file( '/fake/seek_past_back', $content );
    sysopen( my $fh, '/fake/seek_past_back', O_RDONLY ) or die;

    is( sysseek( $fh, 100, SEEK_SET ), 100, "Seek to position 100 (past EOF)" );
    ok( eof($fh), "eof() is true at position 100" );

    is( sysseek( $fh, 5, SEEK_SET ), 5, "Seek back to position 5" );
    ok( !eof($fh), "eof() is false at position 5" );

    my $buf = "";
    sysread( $fh, $buf, 5 );
    is( $buf, "FGHIJ", "Can read normally after seeking back from past-EOF position" );

    ok( eof($fh), "eof() is true after reading to end" );

    close $fh;
}

{
    note "--- Seek past EOF with SEEK_CUR and SEEK_END ---";

    my $mock = Test::MockFile->file( '/fake/seek_past_modes', $content );
    sysopen( my $fh, '/fake/seek_past_modes', O_RDONLY ) or die;

    # SEEK_END past EOF
    is( sysseek( $fh, 5, SEEK_END ), 15, "SEEK_END +5 = 10 + 5 = 15" );
    ok( eof($fh), "eof() is true at position 15" );

    # SEEK_CUR from past EOF
    is( sysseek( $fh, 10, SEEK_CUR ), 25, "SEEK_CUR +10 from 15 = 25" );
    ok( eof($fh), "eof() is true at position 25" );

    # Can still seek back to valid range
    is( sysseek( $fh, 0, SEEK_SET ), "0 but true", "Seek back to 0" );
    ok( !eof($fh), "eof() is false at position 0" );

    close $fh;
}

{
    note "--- tell() on regular file handles ---";

    my $mock = Test::MockFile->file( '/fake/tell_test', $content );
    open( my $fh, '<', '/fake/tell_test' ) or die;

    is( tell($fh), 0, "tell() returns 0 at start of file" );

    my $line = <$fh>;
    is( tell($fh), 10, "tell() returns 10 after reading all content" );

    seek( $fh, 3, SEEK_SET );
    is( tell($fh), 3, "tell() returns 3 after seek to position 3" );

    seek( $fh, 50, SEEK_SET );
    is( tell($fh), 50, "tell() returns 50 after seek past EOF" );

    close $fh;
}

{
    note "--- EOF warning mentions file path (not STDOUT) ---";

    my $mock = Test::MockFile->file( '/fake/eof_warn', $content );
    sysopen( my $fh, '/fake/eof_warn', O_WRONLY | O_CREAT ) or die;

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my $is_eof = eof($fh);

    is( scalar @warnings, 1, "eof() on write-only handle emits one warning" );
    like( $warnings[0], qr{/fake/eof_warn}, "warning mentions the file path, not STDOUT" );
    unlike( $warnings[0], qr{STDOUT}, "warning does not mention STDOUT" );

    close $fh;
}

is( \%Test::MockFile::files_being_mocked, {}, "No mock files are in cache" );

done_testing();
exit;
