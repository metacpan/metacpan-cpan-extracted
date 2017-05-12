use strict;
use warnings;

use Test::More 0.88;

use Path::Class;
use File::Temp qw(tempdir);
use File::Path 2.04;    # for reliable keep_root

my $tmp;

BEGIN {
    use File::Spec;

    plan skip_all => "No writable temp dir" unless grep { -d && -w } File::Spec->tmpdir;
    $tmp = dir( tempdir( CLEANUP => 1 ) );
    plan skip_all => "couldn't create temp dir" unless -d $tmp && -w $tmp;
}

use ok 'Test::TempDir::Handle';

isa_ok( my $h = Test::TempDir::Handle->new( dir => $tmp ), "Test::TempDir::Handle" );

is( $h->dir, $tmp, "dir set" );

is( $h->cleanup_policy, "success", "default cleanup policy" );

my $file = $h->dir->file("foo");
my $subdir = $h->dir->subdir("bar");

$file->touch;
$subdir->mkpath;

ok( -f $file, "file created" );
ok( -d $subdir, "subdir created" );

$h->empty;

ok( not(-f $file), "file removed by empty" );
ok( not(-d $subdir), "subdir removed by empty" );

is_deeply( [ $h->dir->children ], [], "no children" );

ok( -d $tmp, "dir exists" );

$file->touch;

ok( -f $file, "file exists" );

$h->cleanup_policy("never");

$h->cleanup;

ok( -f $file, "file exists" );

$h->cleanup_policy("always");

$h->cleanup;

ok( not(-d $tmp), "dir removed by delete" );

done_testing;
