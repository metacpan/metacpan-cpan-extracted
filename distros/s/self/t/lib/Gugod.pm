package Gugod;
use strict;
use warnings;
use self;

sub new {
    return bless { value => 0 }, self;
}

sub inc {
    self->{value}++;
}

1;
