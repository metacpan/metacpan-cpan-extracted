#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Fcntl qw( O_RDWR O_CREAT O_TRUNC O_WRONLY );
use Errno qw( EBADF EINVAL );

use Test::MockFile qw< nostrict >;

{
    note "--- tell() advances after print ---";

    my $mock = Test::MockFile->file('/fake/write_tell');
    open( my $fh, '>', '/fake/write_tell' ) or die;

    is( tell($fh), 0, "tell is 0 before any writes" );

    print $fh "Hello";
    is( tell($fh), 5, "tell is 5 after printing 'Hello'" );

    print $fh " World";
    is( tell($fh), 11, "tell is 11 after printing ' World'" );

    close $fh;
    is( $mock->contents, "Hello World", "Contents are correct" );
}

{
    note "--- tell() advances after printf ---";

    my $mock = Test::MockFile->file('/fake/printf_tell');
    open( my $fh, '>', '/fake/printf_tell' ) or die;

    printf $fh "%04d", 42;
    is( tell($fh), 4, "tell is 4 after printf '%04d'" );

    printf $fh "-%s-", "test";
    is( tell($fh), 10, "tell is 10 after second printf" );

    close $fh;
    is( $mock->contents, "0042-test-", "Contents are correct" );
}

{
    note "--- tell() advances after syswrite ---";

    my $mock = Test::MockFile->file('/fake/syswrite_tell');
    sysopen( my $fh, '/fake/syswrite_tell', O_WRONLY | O_CREAT | O_TRUNC ) or die;

    syswrite( $fh, "ABCDE", 5 );
    is( tell($fh), 5, "tell is 5 after syswrite of 5 bytes" );

    syswrite( $fh, "FGH", 3 );
    is( tell($fh), 8, "tell is 8 after syswrite of 3 more bytes" );

    close $fh;
    is( $mock->contents, "ABCDEFGH", "Contents are correct" );
}

{
    note "--- tell() after write then read (read+write mode) ---";

    my $mock = Test::MockFile->file('/fake/rw_tell');
    sysopen( my $fh, '/fake/rw_tell', O_RDWR | O_CREAT | O_TRUNC ) or die;

    syswrite( $fh, "Hello World", 11 );
    is( tell($fh), 11, "tell is 11 after writing 'Hello World'" );

    seek( $fh, 0, 0 );
    is( tell($fh), 0, "tell is 0 after seeking to start" );

    my $buf = "";
    read( $fh, $buf, 5 );
    is( $buf,      "Hello", "Read back 'Hello'" );
    is( tell($fh), 5,       "tell is 5 after reading 5 bytes" );
}

{
    note "--- tell() after append mode ---";

    my $mock = Test::MockFile->file( '/fake/append_tell', "existing" );
    open( my $fh, '>>', '/fake/append_tell' ) or die;

    print $fh " data";
    is( tell($fh), 13, "tell is 13 after appending to 'existing'" );

    close $fh;
    is( $mock->contents, "existing data", "Contents are correct" );
}

{
    note "--- printing undef does not change tell ---";

    my $mock = Test::MockFile->file('/fake/undef_tell');
    open( my $fh, '>', '/fake/undef_tell' ) or die;

    print $fh "ABC";
    is( tell($fh), 3, "tell is 3 after printing 'ABC'" );

    print $fh undef;
    is( tell($fh), 3, "tell unchanged after printing undef" );

    close $fh;
    is( $mock->contents, "ABC", "Contents are correct" );
}

{
    note "--- print with explicit output record separator ---";

    my $mock = Test::MockFile->file('/fake/ors_tell');
    open( my $fh, '>', '/fake/ors_tell' ) or die;

    {
        local $\ = "\n";
        print $fh "Hello";
    }
    is( tell($fh), 6, "tell is 6 after print with ORS (5 chars + newline)" );

    close $fh;
    is( $mock->contents, "Hello\n", "Contents include newline from output record separator" );
}

# Note: say() with tied filehandles does NOT append the newline via $\.
# Perl handles say's newline at the C level (pp_print) after the tied
# PRINT method returns, so it is never passed to PRINT. This is a known
# limitation of tied filehandles in Perl.

{
    note "--- +< mode: seek + print overwrites at tell position ---";

    my $mock = Test::MockFile->file( '/fake/rw_overwrite', "Hello World!" );
    open( my $fh, '+<', '/fake/rw_overwrite' ) or die;

    # Seek to position 6 and overwrite
    seek( $fh, 6, 0 );
    is( tell($fh), 6, "tell is 6 after seek" );

    print $fh "Perl!";
    is( tell($fh), 11, "tell is 11 after printing 5 bytes at position 6" );

    close $fh;
    is( $mock->contents, "Hello Perl!!", "Overwrite at position 6 replaces 'World' with 'Perl!'" );
}

{
    note "--- +< mode: seek + print does not extend past original when write fits ---";

    my $mock = Test::MockFile->file( '/fake/rw_exact', "ABCDEFGH" );
    open( my $fh, '+<', '/fake/rw_exact' ) or die;

    seek( $fh, 3, 0 );
    print $fh "XY";

    close $fh;
    is( $mock->contents, "ABCXYFGH", "Overwrite at position 3 replaces 2 bytes" );
}

{
    note "--- +< mode: print at tell 0 overwrites from start ---";

    my $mock = Test::MockFile->file( '/fake/rw_start', "old content" );
    open( my $fh, '+<', '/fake/rw_start' ) or die;

    # tell starts at 0
    print $fh "NEW";

    close $fh;
    is( $mock->contents, "NEW content", "Print at position 0 overwrites first 3 bytes" );
}

{
    note "--- +< mode: print extending past end grows the file ---";

    my $mock = Test::MockFile->file( '/fake/rw_extend', "short" );
    open( my $fh, '+<', '/fake/rw_extend' ) or die;

    seek( $fh, 3, 0 );
    print $fh "LONGER";

    close $fh;
    is( $mock->contents, "shoLONGER", "Print past end extends the file" );
    is( length( $mock->contents ), 9, "File length is 9" );
}

{
    note "--- >> mode: seek then print still appends ---";

    my $mock = Test::MockFile->file( '/fake/append_seek', "AAAA" );
    open( my $fh, '>>', '/fake/append_seek' ) or die;

    # Even after seeking to 0, append mode writes at end
    seek( $fh, 0, 0 );
    print $fh "BB";

    close $fh;
    is( $mock->contents, "AAAABB", "Append mode ignores seek position" );
}

{
    note "--- +< mode: interleaved read and write ---";

    my $mock = Test::MockFile->file( '/fake/rw_interleave', "Hello World" );
    open( my $fh, '+<', '/fake/rw_interleave' ) or die;

    # Read first 5 bytes
    my $buf;
    read( $fh, $buf, 5 );
    is( $buf,      "Hello", "Read 'Hello'" );
    is( tell($fh), 5,       "tell is 5 after read" );

    # Write at current position (overwrite ' World' with ' Perl!')
    print $fh " Perl!";
    is( tell($fh), 11, "tell is 11 after write" );

    close $fh;
    is( $mock->contents, "Hello Perl!", "Interleaved read+write produces correct output" );
}

{
    note "--- > mode: print writes at tell position (not append) ---";

    my $mock = Test::MockFile->file('/fake/write_overwrite');
    open( my $fh, '>', '/fake/write_overwrite' ) or die;

    # Write initial content
    print $fh "ABCDEFGH";
    is( tell($fh), 8, "tell is 8 after initial write" );

    # Seek back and overwrite
    seek( $fh, 2, 0 );
    print $fh "XY";
    is( tell($fh), 4, "tell is 4 after overwrite" );

    close $fh;
    is( $mock->contents, "ABXYEFGH", "Overwrite in > mode at seek position" );
}

{
    note "--- syswrite must NOT inherit output record separator (\$\\) ---";

    my $mock = Test::MockFile->file('/fake/syswrite_no_ors');
    sysopen( my $fh, '/fake/syswrite_no_ors', O_WRONLY | O_CREAT | O_TRUNC ) or die;

    {
        local $\ = "\n";
        syswrite( $fh, "Hello", 5 );
    }
    is( tell($fh), 5, "tell is 5 after syswrite (no ORS added)" );

    close $fh;
    is( $mock->contents, "Hello", "syswrite ignores \$\\ — no newline appended" );
}

{
    note "--- syswrite must NOT inherit output field separator (\$,) ---";

    my $mock = Test::MockFile->file('/fake/syswrite_no_ofs');
    sysopen( my $fh, '/fake/syswrite_no_ofs', O_WRONLY | O_CREAT | O_TRUNC ) or die;

    {
        local $, = ",";
        syswrite( $fh, "Hello", 5 );
    }
    is( tell($fh), 5, "tell is 5 after syswrite with \$, set" );

    close $fh;
    is( $mock->contents, "Hello", "syswrite ignores \$, — no separator" );
}

{
    note "--- syswrite returns byte count, not boolean ---";

    my $mock = Test::MockFile->file('/fake/syswrite_return');
    sysopen( my $fh, '/fake/syswrite_return', O_WRONLY | O_CREAT | O_TRUNC ) or die;

    my $ret = syswrite( $fh, "ABCDE", 5 );
    is( $ret, 5, "syswrite returns 5 for 5 bytes written" );

    $ret = syswrite( $fh, "XY", 2 );
    is( $ret, 2, "syswrite returns 2 for 2 bytes written" );

    # syswrite with $\ set should NOT include $\ in return value
    {
        local $\ = "\n";
        $ret = syswrite( $fh, "end", 3 );
    }
    is( $ret, 3, "syswrite returns 3 even with \$\\ set (not 4)" );

    close $fh;
    is( $mock->contents, "ABCDEXYend", "All syswrite data correct, no ORS" );
}

{
    note "--- contrast: print DOES use \$\\ while syswrite does NOT ---";

    my $mock = Test::MockFile->file('/fake/print_vs_syswrite');
    sysopen( my $fh, '/fake/print_vs_syswrite', O_RDWR | O_CREAT | O_TRUNC ) or die;

    {
        local $\ = "!";

        # print should append $\
        print $fh "Hello";

        # syswrite should NOT append $\
        syswrite( $fh, "World", 5 );
    }

    close $fh;
    is( $mock->contents, "Hello!World", "print appends ORS, syswrite does not" );
}

{
    note "--- syswrite on read-only handle returns EBADF ---";

    my $mock = Test::MockFile->file( '/fake/syswrite_ebadf', "read only data" );
    open( my $fh, '<', '/fake/syswrite_ebadf' ) or die;

    local $!;
    my $ret = syswrite( $fh, "nope", 4 );
    is( $ret, 0, "syswrite on read-only handle returns 0" );
    is( $! + 0, EBADF, "errno is EBADF for syswrite on read-only handle" );

    close $fh;
}

{
    note "--- syswrite with negative offset (counts from end of buffer) ---";

    my $mock = Test::MockFile->file('/fake/syswrite_neg_offset');
    sysopen( my $fh, '/fake/syswrite_neg_offset', O_WRONLY | O_CREAT | O_TRUNC ) or die;

    # syswrite with offset -2 on "ABCDE" → starts at position 3, writes "DE"
    my $ret = syswrite( $fh, "ABCDE", 2, -2 );
    is( $ret, 2, "syswrite with negative offset returns bytes written" );

    close $fh;
    is( $mock->contents, "DE", "syswrite with offset -2 writes last 2 bytes of buffer" );
}

{
    note "--- syswrite with negative offset past buffer start → error ---";

    my $mock = Test::MockFile->file('/fake/syswrite_neg_oob');
    sysopen( my $fh, '/fake/syswrite_neg_oob', O_WRONLY | O_CREAT | O_TRUNC ) or die;

    # offset -10 on a 3-char string: abs(-10) > 3 → error
    local $!;
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, $_[0] };
    my $ret = syswrite( $fh, "abc", 3, -10 );
    is( $ret, 0, "syswrite with offset past buffer start returns 0" );
    is( $! + 0, EINVAL, "errno is EINVAL for out-of-bounds negative offset" );
    ok( grep( /Offset outside string/, @warns ), "warning emitted for out-of-bounds negative offset" );

    close $fh;
    is( $mock->contents, '', "no data written on out-of-bounds negative offset" );
}

{
    note "--- syswrite with positive offset past buffer end → error ---";

    my $mock = Test::MockFile->file('/fake/syswrite_pos_oob');
    sysopen( my $fh, '/fake/syswrite_pos_oob', O_WRONLY | O_CREAT | O_TRUNC ) or die;

    # offset 10 on a 3-char string → error
    local $!;
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, $_[0] };
    my $ret = syswrite( $fh, "abc", 3, 10 );
    is( $ret, 0, "syswrite with offset past buffer end returns 0" );
    is( $! + 0, EINVAL, "errno is EINVAL for out-of-bounds positive offset" );
    ok( grep( /Offset outside string/, @warns ), "warning emitted for out-of-bounds positive offset" );

    close $fh;
    is( $mock->contents, '', "no data written on out-of-bounds positive offset" );
}

{
    note "--- syswrite with len exceeding available data (truncates silently) ---";

    my $mock = Test::MockFile->file('/fake/syswrite_truncate');
    sysopen( my $fh, '/fake/syswrite_truncate', O_WRONLY | O_CREAT | O_TRUNC ) or die;

    # Ask for 100 bytes from offset 2 of "ABCDE" — only 3 available
    my $ret = syswrite( $fh, "ABCDE", 100, 2 );
    is( $ret, 3, "syswrite returns actual bytes written when len exceeds buffer" );

    close $fh;
    is( $mock->contents, "CDE", "syswrite truncates to available data" );
}

{
    note "--- printf must NOT inherit output record separator (\$\\) ---";

    my $mock = Test::MockFile->file('/fake/printf_no_ors');
    open( my $fh, '>', '/fake/printf_no_ors' ) or die;

    {
        local $\ = "\n";
        printf $fh "%s=%d", "count", 42;
    }
    is( tell($fh), 8, "tell is 8 after printf (no ORS added)" );

    close $fh;
    is( $mock->contents, "count=42", "printf ignores \$\\ — no newline appended" );
}

{
    note "--- contrast: print uses \$\\, printf and syswrite do not ---";

    my $mock = Test::MockFile->file('/fake/print_printf_syswrite');
    sysopen( my $fh, '/fake/print_printf_syswrite', O_RDWR | O_CREAT | O_TRUNC ) or die;

    {
        local $\ = "!";

        # print appends $\
        print $fh "A";

        # printf does NOT append $\
        printf $fh "%s", "B";

        # syswrite does NOT append $\
        syswrite( $fh, "C", 1 );
    }

    close $fh;
    is( $mock->contents, "A!BC", "print appends ORS; printf and syswrite do not" );
}

is( \%Test::MockFile::files_being_mocked, {}, "No mock files are in cache" );

done_testing();
exit;
