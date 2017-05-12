use strict;
use warnings;

use File::Temp;

sub {
    my $drv = shift;

    my $png = $drv->screenshot;

    is substr( $png, 0, 8 ), "\211PNG\r\n\032\n", 'screenshot looks like a PNG';

    my $file = File::Temp->new;

    $drv->screenshot( $file->filename );

    local ( @ARGV, $/ ) = $file->filename;

    is <>, $png, 'screenshot("file") matches screenshot';
};
