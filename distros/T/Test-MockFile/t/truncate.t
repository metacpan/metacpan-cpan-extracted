use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Fcntl qw( O_RDWR O_CREAT );
use File::Temp ();
use Errno qw( ENOENT EISDIR EINVAL );

# Create a real tempfile before loading Test::MockFile
my $real_tempfile;
BEGIN {
    $real_tempfile = File::Temp->new( UNLINK => 1 );
    print {$real_tempfile} "hello world, this is a test";
    $real_tempfile->flush;
}

use Test::MockFile qw< nostrict >;

# GitHub issue #221: truncate() on mocked files should work.

subtest 'truncate by path — shorten contents' => sub {
    my $mock = Test::MockFile->file( '/fake/truncme', 'hello world' );
    ok( truncate( '/fake/truncme', 5 ), 'truncate returns true' );
    is( $mock->contents(), 'hello', 'contents shortened to 5 bytes' );
};

subtest 'truncate by path — extend with null bytes' => sub {
    my $mock = Test::MockFile->file( '/fake/extend', 'abc' );
    ok( truncate( '/fake/extend', 6 ), 'truncate returns true' );
    is( length( $mock->contents() ), 6, 'contents extended to 6 bytes' );
    is( $mock->contents(), "abc\0\0\0", 'padded with null bytes' );
};

subtest 'truncate by path — same length is no-op' => sub {
    my $mock = Test::MockFile->file( '/fake/noop', 'test' );
    ok( truncate( '/fake/noop', 4 ), 'truncate returns true' );
    is( $mock->contents(), 'test', 'contents unchanged' );
};

subtest 'truncate to zero' => sub {
    my $mock = Test::MockFile->file( '/fake/zero', 'some data here' );
    ok( truncate( '/fake/zero', 0 ), 'truncate to 0 returns true' );
    is( $mock->contents(), '', 'contents now empty' );
};

subtest 'truncate via filehandle' => sub {
    my $mock = Test::MockFile->file( '/fake/fhtrunc', 'abcdefgh' );
    open( my $fh, '+<', '/fake/fhtrunc' ) or die "open: $!";

    ok( truncate( $fh, 3 ), 'truncate via fh returns true' );
    is( $mock->contents(), 'abc', 'contents shortened via fh' );

    close $fh;
};

subtest 'truncate via sysopen filehandle' => sub {
    my $mock = Test::MockFile->file( '/fake/systrunc', 'data1234' );
    sysopen( my $fh, '/fake/systrunc', O_RDWR ) or die "sysopen: $!";

    ok( truncate( $fh, 4 ), 'truncate via sysopen fh returns true' );
    is( $mock->contents(), 'data', 'contents shortened via sysopen fh' );

    close $fh;
};

subtest 'truncate on non-existent mock file fails with ENOENT' => sub {
    my $mock = Test::MockFile->file( '/fake/noexist' );
    ok( !truncate( '/fake/noexist', 0 ), 'truncate returns false' );
    is( $! + 0, ENOENT, '$! is ENOENT' );
};

subtest 'truncate on directory fails with EISDIR' => sub {
    my $mock = Test::MockFile->new_dir('/fake/adir');
    ok( !truncate( '/fake/adir', 0 ), 'truncate returns false' );
    is( $! + 0, EISDIR, '$! is EISDIR' );
};

subtest 'truncate with negative length fails with EINVAL' => sub {
    my $mock = Test::MockFile->file( '/fake/neglen', 'data' );
    ok( !truncate( '/fake/neglen', -1 ), 'truncate returns false' );
    is( $! + 0, EINVAL, '$! is EINVAL' );
};

subtest 'truncate on real file falls through to CORE::truncate' => sub {
    my $path = $real_tempfile->filename;
    ok( truncate( $path, 5 ), 'truncate real file returns true' );
    open( my $fh, '<', $path ) or die "open: $!";
    my $data = do { local $/; <$fh> };
    close $fh;
    is( length($data), 5, 'real file truncated to 5 bytes' );
};

subtest 'truncate on file with undef contents (created by open)' => sub {
    my $mock = Test::MockFile->file('/fake/newfile');

    # File doesn't exist yet — can't truncate
    ok( !truncate( '/fake/newfile', 0 ), 'truncate returns false for non-existent' );
    is( $! + 0, ENOENT, '$! is ENOENT' );

    # Create it via open, then truncate
    open( my $fh, '>', '/fake/newfile' ) or die "open: $!";
    print {$fh} "created";
    close $fh;

    ok( truncate( '/fake/newfile', 3 ), 'truncate after open returns true' );
    is( $mock->contents(), 'cre', 'contents shortened' );
};

subtest 'truncate via read-only filehandle fails with EINVAL' => sub {
    my $mock = Test::MockFile->file( '/fake/readonly', 'abcdefgh' );
    open( my $fh, '<', '/fake/readonly' ) or die "open: $!";

    $! = 0;
    my $ret = truncate( $fh, 3 );
    ok( !$ret, 'truncate on read-only fh returns false' );
    is( $! + 0, EINVAL, '$! is EINVAL for read-only fh' );
    is( $mock->contents(), 'abcdefgh', 'contents unchanged' );

    close $fh;
};

subtest 'truncate via write-only filehandle succeeds' => sub {
    my $mock = Test::MockFile->file( '/fake/writeonly', 'original' );
    open( my $fh, '>', '/fake/writeonly' ) or die "open: $!";

    # > mode truncates on open, so contents are now empty
    ok( truncate( $fh, 0 ), 'truncate on write-only fh succeeds' );
    is( $mock->contents(), '', 'contents truncated' );

    close $fh;
};

subtest 'truncate via append filehandle succeeds' => sub {
    my $mock = Test::MockFile->file( '/fake/appendfh', 'some data' );
    open( my $fh, '>>', '/fake/appendfh' ) or die "open: $!";

    ok( truncate( $fh, 4 ), 'truncate on append fh succeeds' );
    is( $mock->contents(), 'some', 'contents shortened via append fh' );

    close $fh;
};

done_testing();
