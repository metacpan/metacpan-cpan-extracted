package bogopragma;
use strict;
use warnings;

sub import {
    $^H{bogopragma} = 1;
}

sub unimport {
    $^H{bogopragma} = 0;
}

sub in_effect {
    my $level = shift || 0;
    my $hinthash = ( caller($level) )[10];
    return $hinthash->{bogopragma};
}

1;
