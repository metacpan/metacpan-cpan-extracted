use strict;
use warnings;
use utf8;
use Test::More;

use lib qw( t/lib );
use Util;

use winja;
use Cwd qw(cwd getcwd fastcwd fastgetcwd getdcwd abs_path realpath fast_abs_path chdir);

my $root     = pwd();
my $test_dir = "test_dir";

my $loop_count = 0;
my %done_tree;

while ( $loop_count < 1 ) {
    my @elems = entries_cp932();
    my $tree  = join( '/', map { to_utf8($_) } @elems );
    redo if exists $done_tree{$tree};
    $done_tree{$tree} = 1;
    $loop_count++;

    if ( -e $test_dir ) {
        cleanup_dir($test_dir) or BAIL_OUT("Can't cleanup '$test_dir'");
    }

    if ( !CORE::mkdir($test_dir) ) {
        BAIL_OUT("Can't mkdir '$test_dir'");
    }

    my $curdir = "$test_dir";
    CORE::chdir($test_dir);

    for my $dir (@elems) {
        my $abs_curdir = "$root/$curdir";
        my $abs_windir = $abs_curdir;
        $abs_windir =~ s:/:\\:g;
        is( cwd(), $abs_curdir, "cwd" );
        is( getcwd(), $abs_curdir, "getcwd" );
        is( fastcwd(), $abs_curdir, "fastcwd" );
        is( fastgetcwd(), $abs_curdir, "fastgetcwd" );
        is( getdcwd(), $abs_windir, "getdcwd" );
        is( abs_path("."), "$abs_curdir", "abs_path(dirname)" );
        is( realpath("."), "$abs_curdir", "realpath(dirname)" );
        is( fast_abs_path("."), "$abs_curdir", "fast_abs_path(dirname)" );
        my $file=( grep {$_ ne $dir} entries_cp932() )[0];
        touch $file;
        my $abs_filepath = "$root/$curdir/$file";
        $abs_filepath =~ s:/:\\:g;
        is( abs_path($file), "$abs_filepath", "abs_path(filename)" );
        is( realpath($file), "$abs_filepath", "realpath(filename)" );
        is( fast_abs_path($file), "$abs_filepath", "fast_abs_path(filename)" );
        $curdir = "$curdir/$dir";
        mkdir($dir);
        chdir($dir);
        $abs_windir = "$root/$curdir";
        $abs_windir =~ s:/:\\:g;
        is( $ENV{PWD}, "$abs_windir", "chdir -> PWD" );
    }
}
done_testing();
