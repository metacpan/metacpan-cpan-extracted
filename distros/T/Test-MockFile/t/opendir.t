#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use File::Temp qw/tempfile tempdir/;
use File::Basename;

use Errno qw/ENOENT EBADF ENOTDIR/;

use Test::MockFile qw< nostrict >;    # Everything below this can have its open overridden.

my $temp_dir = tempdir( CLEANUP => 1 );
my ( undef, $filename )    = tempfile( DIR => $temp_dir );
my ( undef, $temp_notdir ) = tempfile();

note "-------------- REAL MODE --------------";
is( -d $temp_dir,                     1, "Temp is created on disk." );
is( opendir( my $dir_fh, $temp_dir ), 1, "$temp_dir can be read" );
my @dir_files;
push @dir_files, scalar readdir($dir_fh);
push @dir_files, scalar readdir($dir_fh);
push @dir_files, scalar readdir($dir_fh);
my $base = basename $filename;
is( [ sort @dir_files ],     [ sort( qw/. .. /, $base ) ], "We read 3 entries in some order. Not predictable, but sort fixes that!" );
is( scalar readdir($dir_fh), undef,                        "undef when nothing left from readdir." );
is( closedir($dir_fh),       1,                            "close the fake dir handle" );

like( warning { readdir($dir_fh) }, qr/^readdir\(\) attempted on invalid dirhandle \S+ /, "warn on readdir when file handle is closed." );

is( opendir( my $bad_fh, "/not/a/valid/path/kdshjfkjd" ), undef,  "opendir on a bad path returns false" );
is( $! + 0,                                               ENOENT, '$! numeric is right.' );

is( opendir( my $notdir_fh, $temp_notdir ), undef,   "opendir on a file returns false" );
is( $! + 0,                                 ENOTDIR, '$! numeric is right.' );

my ( $real_fh, $f3 ) = tempfile( DIR => $temp_dir );
like( warning { readdir($real_fh) }, qr/^readdir\(\) attempted on (?:invalid dir)?handle \$fh/, "We only warn if the file handle or glob is invalid." );

note "-------------- MOCK MODE --------------";
my $abc = Test::MockFile->file( "$temp_dir/abc", 'hello' );
my $def = Test::MockFile->file( "$temp_dir/def", 'hello' );
my $bar = Test::MockFile->dir($temp_dir);
my $baz = Test::MockFile->file( $temp_notdir, '' );

is( opendir( $dir_fh, $temp_dir ), 1,     "Mocked temp dir opens and returns true" );
is( scalar readdir($dir_fh),       ".",   "Read .  from fake readdir" );
is( scalar readdir($dir_fh),       "..",  "Read .. from fake readdir" );
is( telldir($dir_fh),              2,     "tell dir in the middle of fake readdir is right." );
is( scalar readdir($dir_fh),       "abc", "Read abc from fake readdir" );
is( scalar readdir($dir_fh),       "def", "Read def from fake readdir" );
is( telldir($dir_fh),              4,     "tell dir at the end of fake readdir is right." );
is( scalar readdir($dir_fh),       undef, "Read from fake readdir but no more in the list." );
is( scalar readdir($dir_fh),       undef, "Read from fake readdir but no more in the list." );
is( scalar readdir($dir_fh),       undef, "Read from fake readdir but no more in the list." );
is( scalar readdir($dir_fh),       undef, "Read from fake readdir but no more in the list." );

is( rewinddir($dir_fh),    1,                  "rewinddir returns true." );
is( telldir($dir_fh),      0,                  "telldir afer rewinddir is right." );
is( [ readdir($dir_fh) ],  [qw/. .. abc def/], "Read the whole dir from fake readdir after rewinddir" );
is( telldir($dir_fh),      4,                  "tell dir at the end of fake readdir is right." );
is( seekdir( $dir_fh, 1 ), 1,                  "seekdir returns where it sought." );
is( [ readdir($dir_fh) ],  [qw/.. abc def/],   "Read the whole dir from fake readdir after seekdir" );
closedir($dir_fh);

is( opendir( my $still_notdir_fh, $temp_notdir ), undef,   "opendir on a mocked file returns false" );
is( $! + 0,                                       ENOTDIR, '$! numeric is right.' );

# Check symlinks appear in readdir
my $dir_for_symlink = Test::MockFile->dir('/foo');
my $dir_in_dir      = Test::MockFile->new_dir('/foo/infoo');
my $symlink_dest    = Test::MockFile->file( '/foo/dest', '' );
my $symlink         = Test::MockFile->symlink( '/foo/dest', '/foo/source' );

opendir my $sdh, '/foo' or die $!;
my @contents = readdir $sdh;
closedir $sdh or die $!;
is(
    [ sort @contents ],
    [qw< . .. dest infoo source >],
    'Symlink and directories appears in directory content'
);

{
    my $d1 = Test::MockFile->dir('/foo2/bar');
    my $d2 = Test::MockFile->dir('/foo2');
    mkdir $d1->path();
    mkdir $d2->path();

    my $f = Test::MockFile->file( '/foo2/bar/baz', '' );

    opendir my $dh, '/foo2' or die $!;
    my @content = readdir $dh;
    closedir $dh or die $!;
    is( \@content, [qw< . .. bar >], 'Did not get confused by internal files' );
}

# Regression: dir() must use "keys" when grepping %files_being_mocked.
# Without "keys", grep iterates over both keys (paths) and values (weakrefs
# to blessed hashrefs). The stringified mock objects could accidentally match
# the path regex, inflating has_content or causing uninitialized-value warnings
# when weakrefs are cleared during global destruction.
{
    my $mock_file = Test::MockFile->file( '/regdir/somefile', 'data' );
    my $mock_dir  = Test::MockFile->dir('/regdir');

    is( $mock_dir->contents(), [qw< . .. somefile >], 'dir() detects mocked child file via keys %files_being_mocked' );

    opendir my $dh, '/regdir' or die "opendir /regdir: $!";
    is( [ readdir($dh) ], [qw< . .. somefile >], 'readdir returns correct entries for dir with mocked children' );
    closedir $dh;
}

# Regression: readdir in list context at EOF must return empty list, not (undef).
# "return undef" in Perl returns (undef) in list context — a one-element list
# that is truthy — so while(@e = readdir $dh) would never terminate.
{
    my $ldir  = Test::MockFile->dir('/listctx');
    my $lfile = Test::MockFile->file( '/listctx/a', 'x' );

    opendir my $dh, '/listctx' or die "opendir: $!";

    # Consume all entries in scalar context first
    while ( defined( my $e = readdir($dh) ) ) { }

    # Now at EOF: list context must return empty list, not (undef)
    my @eof_entries = readdir($dh);
    is( \@eof_entries, [], 'readdir in list context at EOF returns empty list, not (undef)' );

    # Verify the loop pattern works: while(@entries = readdir $dh) must terminate
    rewinddir($dh);
    my @collected;
    my $iterations = 0;
    while ( my @batch = readdir($dh) ) {
        push @collected, @batch;
        last if ++$iterations > 100;    # safety: prevent infinite loop in case of bug
    }
    is( [ sort @collected ], [qw< . .. a >], 'while(@e = readdir $dh) collects all entries and terminates' );
    ok( $iterations <= 4, 'loop terminated without hitting safety limit' );

    closedir($dh);
}

note "-------------- BAREWORD GUARD REGRESSION --------------";
# Regression: the bareword upgrade guard was checking $_[9] (always undef
# for 1-2 arg dir functions) instead of $_[0]. This meant _upgrade_barewords
# ran unconditionally, even for reference filehandles.
# Also: seekdir must return 1 (like CORE::seekdir), not the seek position.
{
    my $mock_dir  = Test::MockFile->dir('/guardtest');
    my $mock_file = Test::MockFile->file( '/guardtest/aaa', 'data' );

    is( opendir( my $dh, '/guardtest' ), 1, "opendir with ref filehandle works" );

    is( scalar readdir($dh), ".",   "readdir with ref fh reads ." );
    is( scalar readdir($dh), "..",  "readdir with ref fh reads .." );
    is( telldir($dh),        2,     "telldir with ref fh returns correct position" );
    is( scalar readdir($dh), "aaa", "readdir with ref fh reads aaa" );

    is( rewinddir($dh), 1, "rewinddir with ref fh returns 1" );
    is( telldir($dh),   0, "telldir after rewinddir is 0" );

    # seekdir's return value is not reliably testable across Perl versions
    # with CORE::GLOBAL overrides — test the effect instead.
    seekdir( $dh, 2 );
    is( telldir($dh),      2,       "telldir is 2 after seekdir(2)" );
    is( [ readdir($dh) ],  ["aaa"], "readdir after seekdir(2) returns remaining entries" );

    is( closedir($dh), 1, "closedir with ref fh returns 1" );
}

note "opendir failure returns undef in list context (single-element list)";
{
    my $mock_dir = Test::MockFile->dir('/list_ctx_dir');

    my @ret = opendir( my $dh, '/list_ctx_dir' );
    is( scalar @ret, 1,   'opendir failure returns one element in list context' );
    ok( !$ret[0],         'opendir failure element is false' );
    ok( !defined $ret[0], 'opendir failure element is undef' );
}

note "-------------- closedir double-close returns EBADF --------------";
{
    my $mock = Test::MockFile->new_dir('/dblclose');

    opendir my $dh, '/dblclose' or die "opendir: $!";
    is( closedir($dh), 1, 'first closedir succeeds' );

    my $ret;
    my $errno;
    like(
        warning {
            $ret = closedir($dh);
            $errno = $! + 0;
        },
        qr/closedir\(\) attempted on invalid dirhandle/,
        'second closedir warns about invalid dirhandle'
    );
    ok( !defined $ret, 'second closedir returns undef' );
    is( $errno, EBADF, 'second closedir sets EBADF' );
}

note "-------------- seekdir with negative position clamps to 0 --------------";
{
    my $f1   = Test::MockFile->file( '/seekneg/alpha', '' );
    my $f2   = Test::MockFile->file( '/seekneg/beta',  '' );
    my $mock = Test::MockFile->new_dir('/seekneg');

    opendir my $dh, '/seekneg' or die "opendir: $!";

    # Consume one entry, then seek to -1
    my $first = readdir($dh);
    is( $first, '.', 'readdir returns first entry before seekdir' );

    seekdir( $dh, -1 );
    is( telldir($dh), 0, 'seekdir(-1) clamps tell to 0' );

    # readdir after seekdir(-1) should return the first entry again
    my $after = readdir($dh);
    is( $after, '.', 'readdir after seekdir(-1) returns first entry' );

    # List context: seekdir(-99) then readdir returns all entries
    seekdir( $dh, -99 );
    my @all = readdir($dh);
    is( \@all, [qw/. .. alpha beta/], 'readdir list after seekdir(-99) returns all entries' );

    closedir($dh);
}

note "-------------- readdir on closed mock dirhandle warns --------------";
{
    my $mock = Test::MockFile->new_dir('/rd_closed');

    opendir my $dh, '/rd_closed' or die "opendir: $!";
    is( closedir($dh), 1, 'closedir succeeds' );

    # Scalar context
    my $entry;
    like(
        warning { $entry = readdir($dh) },
        qr/readdir\(\) attempted on invalid dirhandle/,
        'readdir on closed mock dh warns'
    );
    ok( !defined $entry, 'readdir on closed mock dh returns undef in scalar context' );

    # List context
    my @entries;
    like(
        warning { @entries = readdir($dh) },
        qr/readdir\(\) attempted on invalid dirhandle/,
        'readdir on closed mock dh warns in list context'
    );
    is( \@entries, [], 'readdir on closed mock dh returns empty list in list context' );
}

note "-------------- telldir on closed mock dirhandle warns --------------";
{
    my $mock = Test::MockFile->new_dir('/td_closed');

    opendir my $dh, '/td_closed' or die "opendir: $!";
    is( closedir($dh), 1, 'closedir succeeds' );

    my $pos;
    like(
        warning { $pos = telldir($dh) },
        qr/telldir\(\) attempted on invalid dirhandle/,
        'telldir on closed mock dh warns'
    );
    ok( !defined $pos, 'telldir on closed mock dh returns undef' );
}

note "-------------- seekdir on closed mock dirhandle warns --------------";
{
    my $mock = Test::MockFile->new_dir('/sd_closed');

    opendir my $dh, '/sd_closed' or die "opendir: $!";
    is( closedir($dh), 1, 'closedir succeeds' );

    like(
        warning { seekdir( $dh, 0 ) },
        qr/seekdir\(\) attempted on invalid dirhandle/,
        'seekdir on closed mock dh warns'
    );
}

note "-------------- rewinddir on closed mock dirhandle warns --------------";
{
    my $mock = Test::MockFile->new_dir('/rw_closed');

    opendir my $dh, '/rw_closed' or die "opendir: $!";
    is( closedir($dh), 1, 'closedir succeeds' );

    like(
        warning { rewinddir($dh) },
        qr/rewinddir\(\) attempted on invalid dirhandle/,
        'rewinddir on closed mock dh warns'
    );
}

done_testing();
exit;
