package Contemporary::Perl;

use strict;
use warnings;
use true ();

sub import {
    strict->import();
    warnings->import();
    true->import();
}

sub unimport {
    true->unimport();
}

1;
