#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Errno qw/EBADF/;

use Test::MockFile qw<nostrict>;

# ============================================================
# Test: CLOSE/DESTROY safety when handle outlives mock object
# ============================================================

note "--- Handle outlives its mock (reversed scope exit) ---";

{
    my $fh;
    {
        my $mock = Test::MockFile->file( '/tmp/outlive_test', 'hello world' );
        ok( open( $fh, '<', '/tmp/outlive_test' ), "open mocked file" );
        my $line = <$fh>;
        is( $line, 'hello world', "read from mocked file" );
    }

    # $mock is now out of scope — weak ref in FileHandle is undef.
    # close() should not crash.
    my $closed;
    my $lived = eval {
        $closed = close($fh);
        1;
    };
    ok( $lived, "close() on orphaned handle does not crash" )
        or diag("Error: $@");
}

note "--- DESTROY on orphaned handle (scope exit without close) ---";

{
    my $fh;
    {
        my $mock = Test::MockFile->file( '/tmp/destroy_test', 'data' );
        ok( open( $fh, '<', '/tmp/destroy_test' ), "open mocked file" );
    }

    # Let $fh go out of scope without explicit close.
    # DESTROY should not crash even though mock is gone.
    my $lived = eval {
        undef $fh;
        1;
    };
    ok( $lived, "DESTROY on orphaned handle does not crash" )
        or diag("Error: $@");
}

# ============================================================
# Test: READ returns EBADF on write-only handles
# ============================================================

note "--- sysread on write-only handle returns EBADF ---";

{
    my $mock = Test::MockFile->file( '/tmp/ebadf_read_test', 'some data' );
    ok( open( my $fh, '>', '/tmp/ebadf_read_test' ), "open for write-only" );

    my $buf;
    my $result = sysread( $fh, $buf, 10 );
    ok( !defined $result, "sysread on write-only handle returns undef" );
    is( $! + 0, EBADF, "errno is EBADF" );

    close($fh);
}

# ============================================================
# Test: syswrite with negative offset
# ============================================================

note "--- syswrite with negative offset ---";

{
    my $mock = Test::MockFile->file( '/tmp/syswrite_neg_offset', '' );
    ok( open( my $fh, '>', '/tmp/syswrite_neg_offset' ), "open for write" );

    # syswrite with negative offset counts from end of buffer
    my $buf = "hello world";
    my $written = syswrite( $fh, $buf, 5, -5 );
    is( $written, 5, "syswrite with negative offset writes correct bytes" );
    close($fh);

    is( $mock->contents, "world", "negative offset selected from end of string" );
}

{
    my $mock = Test::MockFile->file( '/tmp/syswrite_neg_oob', '' );
    ok( open( my $fh, '>', '/tmp/syswrite_neg_oob' ), "open for write" );

    # Negative offset that goes before start of string — expect warning + EINVAL
    my $buf = "hi";
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    my $result = syswrite( $fh, $buf, 2, -10 );
    is( $result, 0, "syswrite with out-of-bounds negative offset returns 0" );
    ok( scalar @warnings, "warning emitted for out-of-bounds offset" );
    like( $warnings[0], qr/Offset outside string/, "warning mentions offset" );
    close($fh);
}

# ============================================================
# Test: syswrite with positive offset
# ============================================================

note "--- syswrite with positive offset ---";

{
    my $mock = Test::MockFile->file( '/tmp/syswrite_pos_offset', '' );
    ok( open( my $fh, '>', '/tmp/syswrite_pos_offset' ), "open for write" );

    my $buf = "hello world";
    my $written = syswrite( $fh, $buf, 5, 6 );
    is( $written, 5, "syswrite with positive offset writes correct bytes" );
    close($fh);

    is( $mock->contents, "world", "positive offset skipped beginning of buffer" );
}

{
    my $mock = Test::MockFile->file( '/tmp/syswrite_oob_offset', '' );
    ok( open( my $fh, '>', '/tmp/syswrite_oob_offset' ), "open for write" );

    # Per perlapi: len exceeding available data is NOT an error — syswrite
    # truncates silently and writes what's available.
    my $buf = "hi";
    my $result = syswrite( $fh, $buf, 5, 0 );
    is( $result, 2, "syswrite with len > strlen writes available bytes" );
    close($fh);

    is( $mock->contents, "hi", "file contains truncated write" );
}

done_testing();
