package Warned7;
use strict;
use warnings 'once';

sub foo {
    foreach my $unused_var(@_){

    }
    return;
}

sub bar {
    foreach my $unused_var(@_){

    }
    return;
}
1;
