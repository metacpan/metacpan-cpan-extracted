package CONO::Real;

use strict;
use warnings;

sub new {
    return bless{};
}

sub test {
    return 42;
}

sub proxy {
    my ($self, $param) = @_;

    return $param;
}
 
42;
