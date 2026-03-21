#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Fcntl qw( O_RDONLY O_WRONLY O_CREAT O_TRUNC O_RDWR O_APPEND );
use Errno qw( EBADF EINVAL );

use Test::MockFile qw< nostrict >;

# ============================================================
# syswrite edge cases
# ============================================================

{
    note "--- syswrite zero-length write returns 0 and writes nothing ---";

    my $mock = Test::MockFile->file( '/fake/sw_zero', "original" );
    sysopen( my $fh, '/fake/sw_zero', O_WRONLY ) or die;

    my $ret = syswrite( $fh, "abc", 0 );
    is( $ret, 0, "syswrite with len=0 returns 0" );

    close $fh;
    is( $mock->contents, "original", "file contents unchanged after zero-length write" );
}

{
    note "--- syswrite zero-length write on empty file ---";

    my $mock = Test::MockFile->file('/fake/sw_zero_empty');
    sysopen( my $fh, '/fake/sw_zero_empty', O_WRONLY | O_CREAT | O_TRUNC ) or die;

    my $ret = syswrite( $fh, "data", 0 );
    is( $ret, 0, "syswrite len=0 on empty file returns 0" );
    is( tell($fh), 0, "tell unchanged after zero-length write" );

    close $fh;
    is( $mock->contents, '', "file still empty after zero-length write" );
}

{
    note "--- syswrite with O_APPEND always appends regardless of seek ---";

    my $mock = Test::MockFile->file( '/fake/sw_append', "AAAA" );
    sysopen( my $fh, '/fake/sw_append', O_WRONLY | O_APPEND ) or die;

    # Seek to beginning — in append mode, writes should still go to end
    sysseek( $fh, 0, 0 );
    syswrite( $fh, "BB", 2 );

    close $fh;
    is( $mock->contents, "AAAABB", "syswrite with O_APPEND appends even after seek to 0" );
}

{
    note "--- syswrite with O_APPEND via open >> ---";

    my $mock = Test::MockFile->file( '/fake/sw_append2', "start" );
    open( my $fh, '>>', '/fake/sw_append2' ) or die;

    syswrite( $fh, "END", 3 );

    close $fh;
    is( $mock->contents, "startEND", "syswrite via open >> appends to file" );
}

{
    note "--- seek past EOF then syswrite creates null-byte gap ---";

    my $mock = Test::MockFile->file('/fake/sw_gap');
    sysopen( my $fh, '/fake/sw_gap', O_RDWR | O_CREAT | O_TRUNC ) or die;

    syswrite( $fh, "AB", 2 );
    sysseek( $fh, 10, 0 );    # Seek past current end
    syswrite( $fh, "XY", 2 );

    close $fh;

    my $expected = "AB" . ( "\0" x 8 ) . "XY";
    is( $mock->contents, $expected, "syswrite after seek past EOF fills gap with null bytes" );
    is( length( $mock->contents ), 12, "file is 12 bytes (2 + 8 null + 2)" );
}

{
    note "--- seek past EOF then syswrite on file with existing content ---";

    my $mock = Test::MockFile->file( '/fake/sw_gap2', "Hello" );
    sysopen( my $fh, '/fake/sw_gap2', O_RDWR ) or die;

    sysseek( $fh, 8, 0 );     # Seek past 5-byte content
    syswrite( $fh, "!", 1 );

    close $fh;

    my $expected = "Hello" . ( "\0" x 3 ) . "!";
    is( $mock->contents, $expected, "syswrite past existing content fills gap with nulls" );
    is( length( $mock->contents ), 9, "file is 9 bytes (5 + 3 null + 1)" );
}

{
    note "--- syswrite with float len is truncated to int ---";

    my $mock = Test::MockFile->file('/fake/sw_float');
    sysopen( my $fh, '/fake/sw_float', O_WRONLY | O_CREAT | O_TRUNC ) or die;

    my $ret = syswrite( $fh, "ABCDE", 2.9 );
    is( $ret, 2, "syswrite with float len 2.9 writes 2 bytes (truncated)" );

    close $fh;
    is( $mock->contents, "AB", "only 2 bytes written with float len 2.9" );
}

{
    note "--- syswrite with non-numeric len warns and returns 0 ---";

    my $mock = Test::MockFile->file('/fake/sw_nonnumeric');
    sysopen( my $fh, '/fake/sw_nonnumeric', O_WRONLY | O_CREAT | O_TRUNC ) or die;

    my @warns;
    local $SIG{__WARN__} = sub { push @warns, $_[0] };

    $! = 0;
    my $ret = syswrite( $fh, "data", "abc" );
    is( $ret, 0, "syswrite with non-numeric len returns 0" );
    is( $! + 0, EINVAL, "errno is EINVAL for non-numeric len" );
    ok( @warns >= 1, "warning emitted for non-numeric len" );
    like( $warns[0], qr/isn't numeric/, "warning mentions non-numeric argument" );

    close $fh;
    is( $mock->contents, '', "no data written with non-numeric len" );
}

{
    note "--- syswrite with negative len warns and returns 0 ---";

    my $mock = Test::MockFile->file('/fake/sw_neglen');
    sysopen( my $fh, '/fake/sw_neglen', O_WRONLY | O_CREAT | O_TRUNC ) or die;

    my @warns;
    local $SIG{__WARN__} = sub { push @warns, $_[0] };

    $! = 0;
    my $ret = syswrite( $fh, "data", -5 );
    is( $ret, 0, "syswrite with negative len returns 0" );
    is( $! + 0, EINVAL, "errno is EINVAL for negative len" );
    ok( @warns >= 1, "warning emitted for negative len" );
    like( $warns[0], qr/Negative length/, "warning mentions negative length" );

    close $fh;
    is( $mock->contents, '', "no data written with negative len" );
}

{
    note "--- syswrite offset 0 on empty buffer writes nothing ---";

    my $mock = Test::MockFile->file('/fake/sw_empty_buf');
    sysopen( my $fh, '/fake/sw_empty_buf', O_WRONLY | O_CREAT | O_TRUNC ) or die;

    my $ret = syswrite( $fh, "", 0 );
    is( $ret, 0, "syswrite with empty buffer and len=0 returns 0" );
    is( tell($fh), 0, "tell unchanged" );

    close $fh;
    is( $mock->contents, '', "file still empty" );
}

# ============================================================
# sysread edge cases
# ============================================================

{
    note "--- sysread with non-numeric len warns and returns undef ---";

    my $mock = Test::MockFile->file( '/fake/sr_nonnumeric', "test data" );
    sysopen( my $fh, '/fake/sr_nonnumeric', O_RDONLY ) or die;

    my @warns;
    local $SIG{__WARN__} = sub { push @warns, $_[0] };

    my $buf = "";
    $! = 0;
    my $ret = sysread( $fh, $buf, "abc" );
    ok( !defined $ret, "sysread with non-numeric len returns undef" );
    is( $! + 0, EINVAL, "errno is EINVAL for non-numeric len" );
    ok( @warns >= 1, "warning emitted for non-numeric len" );
    like( $warns[0], qr/isn't numeric/, "warning mentions non-numeric argument" );

    close $fh;
}

{
    note "--- sysread with negative len warns and returns undef ---";

    my $mock = Test::MockFile->file( '/fake/sr_neglen', "test data" );
    sysopen( my $fh, '/fake/sr_neglen', O_RDONLY ) or die;

    my @warns;
    local $SIG{__WARN__} = sub { push @warns, $_[0] };

    my $buf = "";
    $! = 0;
    my $ret = sysread( $fh, $buf, -3 );
    ok( !defined $ret, "sysread with negative len returns undef" );
    is( $! + 0, EINVAL, "errno is EINVAL for negative len" );
    ok( @warns >= 1, "warning emitted for negative len" );
    like( $warns[0], qr/Negative length/, "warning mentions negative length" );

    close $fh;
}

{
    note "--- sysread with float len truncates to int ---";

    my $mock = Test::MockFile->file( '/fake/sr_float', "ABCDEFGH" );
    sysopen( my $fh, '/fake/sr_float', O_RDONLY ) or die;

    my $buf = "";
    my $ret = sysread( $fh, $buf, 3.7 );
    is( $ret, 3, "sysread with float len 3.7 reads 3 bytes" );
    is( $buf, "ABC", "correct 3 bytes read with float len" );

    close $fh;
}

{
    note "--- sysread zero-length returns 0 and does not modify buffer ---";

    my $mock = Test::MockFile->file( '/fake/sr_zero', "content" );
    sysopen( my $fh, '/fake/sr_zero', O_RDONLY ) or die;

    my $buf = "existing";
    my $ret = sysread( $fh, $buf, 0 );
    is( $ret, 0, "sysread with len=0 returns 0" );
    # Per real Perl: sysread with len=0 truncates buffer at offset
    # With offset defaulting to 0, buffer becomes ""
    is( $buf, "", "buffer truncated to empty by zero-length read at offset 0" );
    is( tell($fh), 0, "tell unchanged after zero-length read" );

    close $fh;
}

{
    note "--- sysread with undef buffer initializes it to empty string ---";

    my $mock = Test::MockFile->file( '/fake/sr_undef_buf', "Hello" );
    sysopen( my $fh, '/fake/sr_undef_buf', O_RDONLY ) or die;

    my $buf;    # undef
    my $ret = sysread( $fh, $buf, 3 );
    is( $ret, 3, "sysread with undef buffer reads 3 bytes" );
    is( $buf, "Hel", "buffer correctly filled from undef" );

    close $fh;
}

{
    note "--- sysread with undef buffer and offset pads with null bytes ---";

    my $mock = Test::MockFile->file( '/fake/sr_undef_offset', "Hello" );
    sysopen( my $fh, '/fake/sr_undef_offset', O_RDONLY ) or die;

    my $buf;    # undef
    my $ret = sysread( $fh, $buf, 2, 3 );
    is( $ret, 2, "sysread with undef buffer and offset reads 2 bytes" );
    is( $buf, "\0\0\0He", "buffer is null-padded then data at offset" );

    close $fh;
}

{
    note "--- sysread on write-only handle returns undef with EBADF ---";

    my $mock = Test::MockFile->file('/fake/sr_ebadf');
    sysopen( my $fh, '/fake/sr_ebadf', O_WRONLY | O_CREAT | O_TRUNC ) or die;

    my $buf = "";
    $! = 0;
    my $ret = sysread( $fh, $buf, 5 );
    ok( !defined $ret, "sysread on write-only handle returns undef" );
    is( $! + 0, EBADF, "errno is EBADF for sysread on write-only handle" );

    close $fh;
}

{
    note "--- sysread at EOF returns 0 ---";

    my $mock = Test::MockFile->file( '/fake/sr_eof', "AB" );
    sysopen( my $fh, '/fake/sr_eof', O_RDONLY ) or die;

    my $buf = "";
    sysread( $fh, $buf, 2 );    # Read all content
    is( $buf, "AB", "first read gets all content" );

    my $ret = sysread( $fh, $buf, 5 );
    is( $ret, 0, "sysread at EOF returns 0" );

    close $fh;
}

{
    note "--- syswrite then sysread in O_RDWR mode ---";

    my $mock = Test::MockFile->file('/fake/sw_then_sr');
    sysopen( my $fh, '/fake/sw_then_sr', O_RDWR | O_CREAT | O_TRUNC ) or die;

    syswrite( $fh, "Hello World", 11 );
    is( tell($fh), 11, "tell is 11 after syswrite" );

    sysseek( $fh, 0, 0 );
    my $buf = "";
    my $ret = sysread( $fh, $buf, 5 );
    is( $ret, 5,       "sysread returns 5" );
    is( $buf, "Hello", "read back what was written" );

    # Continue reading from current position
    $ret = sysread( $fh, $buf, 6 );
    is( $ret, 6,        "sysread returns 6" );
    is( $buf, " World", "second read continues from tell position" );

    close $fh;
}

{
    note "--- syswrite multiple times accumulates content ---";

    my $mock = Test::MockFile->file('/fake/sw_multi');
    sysopen( my $fh, '/fake/sw_multi', O_WRONLY | O_CREAT | O_TRUNC ) or die;

    syswrite( $fh, "A", 1 );
    syswrite( $fh, "BC", 2 );
    syswrite( $fh, "DEF", 3 );

    close $fh;
    is( $mock->contents, "ABCDEF", "multiple syswrite calls accumulate correctly" );
    is( length( $mock->contents ), 6, "total length is 6" );
}

is( \%Test::MockFile::files_being_mocked, {}, "No mock files are in cache" );

done_testing();
exit;
