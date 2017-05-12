package X11::Xpm;

# Copyright 1997, 1998 by Ken Fox

use DynaLoader;

use strict;
use vars qw($VERSION @ISA);

BEGIN {
    $VERSION = 1.0;
    @ISA = qw(DynaLoader);

    bootstrap X11::Xpm;
}

sub beta_version { 2 };

package X::Xpm;

sub CreatePixmapFromData {
    my($display, $d, $data) = @_;

    my @data = split(/\n/, $data);
    return CreatePixmapFromData_array($display, $d, \@data);
}

1;
