use utf8;
use Test::More;
use winja;
use File::Basename;
use lib 't/lib';
use Util;

while ( $count < 10 ) {
    my @elems = entries_cp932();
    my $path = join "/",@elems;
    my $basename = pop @elems;
    my $dirname = join("/",@elems);

    # diag "test by '$path'";
    is basename($path), $basename, "basename";
    is dirname($path), $dirname, "dirname";
    is_deeply [fileparse($path)], [$basename, "$dirname/",''],"fileparse";
    is_deeply [fileparse("$path.txt",qr/\.[^.]+/)],[$basename,"$dirname/",".txt"], "fileparse with suffix";

    $path =~ s:/:\\:g;
    $dirname =~ s:/:\\:g;

    # diag "test by '$path'";
    is basename($path), $basename, "basename";
    is dirname($path), $dirname, "dirname";
    is_deeply [fileparse($path)], [$basename, "$dirname\\",''],"fileparse";
    is_deeply [fileparse("$path.txt",qr/\.[^.]+/)],[$basename, "$dirname\\",".txt"], "fileparse with suffix";

    $count++;
}

done_testing();
