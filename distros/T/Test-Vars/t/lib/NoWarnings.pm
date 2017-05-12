package NoWarnings;
use strict;
use warnings;

sub foo {
    no warnings;

    my $unused_but_ok;
    return;
}

1;
