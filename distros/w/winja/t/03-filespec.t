use utf8;
use Test::More;
use winja;
use File::Spec;
use lib 't/lib';
use Util;

while ( $count < 10 ) {
    my @path_elem = entries_cp932();
    my $expect_drive = "C:";
    my $expect_dir  = join( "\\", @path_elem[0..$#path_elem - 1] ) . "\\";
    my $expect_file = $path_elem[-1];
    my $expect_path = join "", $expect_dir, $expect_file;
    my $expect_fullpath = join "\\",$expect_drive,$expect_path;

    # diag "test by '$expect_fullpath'";

    my $path        = File::Spec->catfile(@path_elem);
    is $path, $expect_path, "catfile";
    my $fullpath        = File::Spec->catfile($expect_drive,@path_elem);
    is $fullpath, $expect_fullpath, "catfile";

    my @splitted;

    @splitted = File::Spec->splitpath($path);
    is_deeply \@splitted, [ '', $expect_dir, $expect_file ], "splitpath";
    @splitted = File::Spec->splitdir($path);
    is_deeply \@splitted, \@path_elem, "splitdir";

    @splitted = File::Spec->splitpath($fullpath);
    is_deeply \@splitted, [ $expect_drive, "\\$expect_dir", $expect_file ], "splitpath";
    @splitted = File::Spec->splitdir($fullpath);
    is_deeply \@splitted, [ $expect_drive, @path_elem ], "splitdir";
    my $re_catfile=File::Spec->catfile(@splitted);
    is $re_catfile, $expect_fullpath, "re-catfile";

    $count++;
}

done_testing();
