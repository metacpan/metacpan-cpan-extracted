package Warned4;
use strict;
use warnings 'once';

sub foo {
    for my $an_unused_var(@_){
    }
    return;
}

1;
