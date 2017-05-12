package Foreach;
use strict;
use warnings 'once';

sub foo {
    foreach my $a(@_){
        $a++;
    }
    return;
}

1;
