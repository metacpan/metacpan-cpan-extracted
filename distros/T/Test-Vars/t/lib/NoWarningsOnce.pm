package NoWarningsOnce;
use strict;
use warnings;

sub foo {
    no warnings 'once';

    my $unused_but_ok;
    return;
}

1;
