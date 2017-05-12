package Warned;
use strict;
use warnings 'once';

sub foo {
    my $var;

    return sub { $var }; # closure
}

1;
