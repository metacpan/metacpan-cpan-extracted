use utf8;
use Test::More;
use winja;
use File::Spec::Functions qw(catfile splitpath splitdir);
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

    my $path        = catfile(@path_elem);
    is $path, $expect_path, "catfile";
    my $fullpath        = catfile($expect_drive,@path_elem);
    is $fullpath, $expect_fullpath, "catfile";

    my @splitted;

    @splitted = splitpath($path);
    is_deeply \@splitted, [ '', $expect_dir, $expect_file ], "splitpath";
    @splitted = splitdir($path);
    is_deeply \@splitted, \@path_elem, "splitdir";

    @splitted = splitpath($fullpath);
    is_deeply \@splitted, [ $expect_drive, "\\$expect_dir", $expect_file ], "splitpath";
    @splitted = splitdir($fullpath);
    is_deeply \@splitted, [ $expect_drive, @path_elem ], "splitdir";
    my $re_catfile=catfile(@splitted);
    is $re_catfile, $expect_fullpath, "re-catfile";

    $count++;
}

done_testing();
