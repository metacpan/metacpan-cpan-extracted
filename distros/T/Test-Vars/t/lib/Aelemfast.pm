package Aelemfast;
use strict;
use warnings 'once';

sub foo {
    my @used_var;
    $used_var[0]++;
    return;
}

1;
