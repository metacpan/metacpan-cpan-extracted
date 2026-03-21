#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Fcntl qw( S_IFREG S_IFDIR S_IFLNK );
use constant S_IFPERMS => 07777;
use Errno qw( ENOENT );

use Test::MockFile qw< nostrict >;

# ===================================================================
# Tests for the file() constructor and mock object API.
# ===================================================================

subtest 'file() constructor — basic creation' => sub {
    my $mock = Test::MockFile->file('/fake/basic.txt', 'hello');

    ok( $mock, 'file() returns a truthy object' );
    is( ref $mock, 'Test::MockFile', 'object is a Test::MockFile instance' );
    is( $mock->path(), '/fake/basic.txt', 'path() returns the mocked path' );
};

subtest 'file() with contents — existing file' => sub {
    my $mock = Test::MockFile->file('/fake/existing.txt', "line1\nline2\n");

    is( $mock->contents(), "line1\nline2\n", 'contents() returns the file body' );
    ok( $mock->exists(), 'exists() is true for file with contents' );
    is( $mock->is_file(), 1, 'is_file() returns 1' );
    is( $mock->is_dir(), 0, 'is_dir() returns 0' );
    is( $mock->is_link(), 0, 'is_link() returns 0' );
};

subtest 'file() without contents — non-existent placeholder' => sub {
    my $mock = Test::MockFile->file('/fake/absent.txt');

    is( $mock->contents(), undef, 'contents() is undef for non-existent file' );
    ok( !$mock->exists(), 'exists() is false for non-existent file' );
    is( $mock->size(), undef, 'size() is undef for non-existent file' );
};

subtest 'file() with empty string — exists but empty' => sub {
    my $mock = Test::MockFile->file('/fake/empty.txt', '');

    is( $mock->contents(), '', 'contents() is empty string' );
    ok( $mock->exists(), 'exists() is true — empty file still exists' );
    is( $mock->size(), 0, 'size() is 0 for empty file' );
};

subtest 'size() and blocks()' => sub {
    my $mock = Test::MockFile->file('/fake/sized.txt', 'x' x 5000);

    is( $mock->size(), 5000, 'size() matches content length' );

    # blocks() = ceil(size / blksize) — no 512-byte conversion
    my $expected_blocks = int( ( 5000 + 4096 - 1 ) / 4096 );
    is( $mock->blocks(), $expected_blocks, 'blocks() computes correctly from size and blksize' );
};

subtest 'stat() returns 13-element list' => sub {
    my $mock = Test::MockFile->file('/fake/stated.txt', 'abc');
    my @stat = $mock->stat();

    is( scalar @stat, 13, 'stat() returns 13 elements' );

    # Index 2 is mode — should have S_IFREG bit set
    ok( $stat[2] & S_IFREG, 'mode has S_IFREG set' );

    # Index 7 is size
    is( $stat[7], 3, 'stat[7] (size) is 3' );

    # Timestamps should be reasonable (not zero)
    ok( $stat[8] > 0, 'atime is non-zero' );
    ok( $stat[9] > 0, 'mtime is non-zero' );
    ok( $stat[10] > 0, 'ctime is non-zero' );
};

subtest 'permissions() and chmod()' => sub {
    my $mock = Test::MockFile->file('/fake/perms.txt', 'data');

    my $orig_perms = $mock->permissions();
    ok( defined $orig_perms, 'permissions() returns a value' );

    # Set specific permissions
    $mock->chmod(0644);
    is( $mock->permissions(), 0644, 'chmod(0644) sets permissions correctly' );

    $mock->chmod(0755);
    is( $mock->permissions(), 0755, 'chmod(0755) updates permissions' );

    # Verify mode preserves file type
    my @stat = $mock->stat();
    ok( $stat[2] & S_IFREG, 'mode still has S_IFREG after chmod' );
    is( $stat[2] & S_IFPERMS, 0755, 'permission bits match after chmod' );
};

subtest 'mtime(), ctime(), atime() — read and write' => sub {
    my $mock = Test::MockFile->file('/fake/timed.txt', 'content');

    my $base_time = time();

    # Reading
    ok( $mock->mtime() > 0, 'mtime() returns a positive epoch' );
    ok( $mock->atime() > 0, 'atime() returns a positive epoch' );
    ok( $mock->ctime() > 0, 'ctime() returns a positive epoch' );

    # Writing
    $mock->mtime(1000000);
    is( $mock->mtime(), 1000000, 'mtime(epoch) sets the value' );

    $mock->atime(2000000);
    is( $mock->atime(), 2000000, 'atime(epoch) sets the value' );

    $mock->ctime(3000000);
    is( $mock->ctime(), 3000000, 'ctime(epoch) sets the value' );
};

subtest 'touch() — creates and updates times' => sub {
    my $mock = Test::MockFile->file('/fake/touched.txt');

    ok( !$mock->exists(), 'file does not exist before touch' );

    $mock->touch();
    ok( $mock->exists(), 'file exists after touch()' );
    is( $mock->contents(), '', 'touch() creates empty file' );

    # Touch with a specific time
    $mock->touch(9999999);
    is( $mock->mtime(), 9999999, 'touch(epoch) sets mtime' );
    is( $mock->atime(), 9999999, 'touch(epoch) sets atime' );
};

subtest 'write() — replaces contents' => sub {
    my $mock = Test::MockFile->file('/fake/writable.txt', 'old data');

    my $ret = $mock->write('new data');
    is( $mock->contents(), 'new data', 'write() replaces contents' );
    is( ref $ret, 'Test::MockFile', 'write() returns $self for chaining' );
};

subtest 'write() — creates non-existent file' => sub {
    my $mock = Test::MockFile->file('/fake/created_by_write.txt');

    ok( !$mock->exists(), 'file does not exist before write()' );
    $mock->write('created');
    ok( $mock->exists(), 'file exists after write()' );
    is( $mock->contents(), 'created', 'contents are correct' );
};

subtest 'append() — adds to contents' => sub {
    my $mock = Test::MockFile->file('/fake/appendable.txt', 'start');

    my $ret = $mock->append(' + end');
    is( $mock->contents(), 'start + end', 'append() adds to contents' );
    is( ref $ret, 'Test::MockFile', 'append() returns $self for chaining' );
};

subtest 'append() — creates non-existent file' => sub {
    my $mock = Test::MockFile->file('/fake/created_by_append.txt');

    ok( !$mock->exists(), 'file does not exist before append()' );
    $mock->append('appended');
    ok( $mock->exists(), 'file exists after append()' );
    is( $mock->contents(), 'appended', 'contents are correct' );
};

subtest 'read() — scalar context returns entire contents' => sub {
    my $mock = Test::MockFile->file('/fake/readable.txt', "line1\nline2\nline3\n");

    my $all = $mock->read();
    is( $all, "line1\nline2\nline3\n", 'read() in scalar returns all contents' );
};

subtest 'read() — list context returns lines' => sub {
    my $mock = Test::MockFile->file('/fake/readable2.txt', "aaa\nbbb\nccc\n");

    my @lines = $mock->read();
    is( \@lines, ["aaa\n", "bbb\n", "ccc\n"], 'read() in list context splits on $/' );
};

subtest 'unlink() — removes the file' => sub {
    my $mock = Test::MockFile->file('/fake/to_delete.txt', 'disposable');

    ok( $mock->exists(), 'file exists before unlink' );
    my $ret = $mock->unlink();
    is( $ret, 1, 'unlink() returns 1 on success' );
    ok( !$mock->exists(), 'file does not exist after unlink()' );
    is( $mock->contents(), undef, 'contents() is undef after unlink()' );
};

subtest 'unlink() on non-existent file fails with ENOENT' => sub {
    my $mock = Test::MockFile->file('/fake/already_gone.txt');

    ok( !$mock->exists(), 'file does not exist' );
    my $ret = $mock->unlink();
    is( $ret, 0, 'unlink() returns 0 for non-existent file' );
    is( $! + 0, ENOENT, 'errno is ENOENT' );
};

subtest 'chained write and append' => sub {
    my $mock = Test::MockFile->file('/fake/chained.txt');

    $mock->write('hello')->append(' world');
    is( $mock->contents(), 'hello world', 'write/append chaining works' );
};

subtest 'file() with custom stat attributes' => sub {
    my $mock = Test::MockFile->file(
        '/fake/custom_stat.txt', 'content',
        {
            uid   => 1000,
            gid   => 2000,
            mtime => 1234567890,
        }
    );

    my @stat = $mock->stat();
    is( $stat[4], 1000, 'uid from constructor' );
    is( $stat[5], 2000, 'gid from constructor' );
    is( $stat[9], 1234567890, 'mtime from constructor' );
};

subtest 'file() — filesystem ops work on mocked file' => sub {
    my $mock = Test::MockFile->file('/fake/fs_ops.txt', 'content here');

    # stat should work via CORE::stat override
    my @stat = stat('/fake/fs_ops.txt');
    is( scalar @stat, 13, 'stat() on mocked path returns 13 elements' );
    is( $stat[7], 12, 'stat[7] (size) is 12' );

    # -e, -f file tests
    ok( -e '/fake/fs_ops.txt', '-e returns true for mocked file' );
    ok( -f '/fake/fs_ops.txt', '-f returns true for mocked file' );
    ok( !-d '/fake/fs_ops.txt', '-d returns false for file' );

    # -s must be captured in a variable first — passing directly to is()
    # causes argument-shifting on Perl < 5.16 due to list-context interaction.
    my $file_size = -s '/fake/fs_ops.txt';
    is( $file_size, 12, '-s returns file size' );

    # open and read
    ok( open( my $fh, '<', '/fake/fs_ops.txt' ), 'open succeeds on mocked file' );
    my $data = <$fh>;
    is( $data, 'content here', 'reading from mocked file handle works' );
    close($fh);
};

subtest 'file() — open for write creates content' => sub {
    my $mock = Test::MockFile->file('/fake/writable_via_open.txt', '');

    ok( open( my $fh, '>', '/fake/writable_via_open.txt' ), 'open > succeeds' );
    print $fh "written via handle";
    close($fh);

    is( $mock->contents(), 'written via handle', 'content written through handle appears in mock' );
};

subtest 'file() — multiple mock objects are independent' => sub {
    my $mock_a = Test::MockFile->file('/fake/independent_a.txt', 'aaa');
    my $mock_b = Test::MockFile->file('/fake/independent_b.txt', 'bbb');

    is( $mock_a->contents(), 'aaa', 'mock_a has correct contents' );
    is( $mock_b->contents(), 'bbb', 'mock_b has correct contents' );

    $mock_a->write('AAA');
    is( $mock_a->contents(), 'AAA', 'mock_a updated' );
    is( $mock_b->contents(), 'bbb', 'mock_b unchanged' );
};

done_testing();
