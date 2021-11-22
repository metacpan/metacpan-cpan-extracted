package OpenXXX;
use strict;
use warnings;

use File::Spec();

sub doit {
    my $fh;
    open($fh, '-<ddd.json');
    open($fh, File::Spec->catfile('dir', 'eee'));
    open($fh, File::Spec->catfile('dir', 'eee'));
}

1;
