package Warned;
use strict;
use warnings 'once';

my $outside = 0;

sub foo {
    $outside++;
    return \my $temp;
}

sub bar; # unimplemented, ignored

1;
