package t::Obj;
use strict;
use warnings;

sub new {
    bless {}, shift;
}

sub aaa {
    return '111';
}

1;
