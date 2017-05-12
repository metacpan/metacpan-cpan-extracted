package OurVars;
use strict;
use warnings 'once';

sub foo {
    our $our_var;
    return;
}

1;
