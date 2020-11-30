package WWW::WTF::Helpers::Filesystem;
use common::sense;

use File::Basename;
use File::Path qw(remove_tree);
use Export::Attrs;

sub remove_directory :Export {
    my ($path) = @_;

    $path = dirname($path);

    die "no directory $path" unless -d $path;

    remove_tree($path) or die "remove of $path failed: $!";

    return;
}

1;
