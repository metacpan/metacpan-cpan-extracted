package XAO::DO::Test1;
use strict;
use base qw(XAO::SimpleHash);

sub method ($) {
    my $self=shift;
    return "XX" . (shift//'<no-arg>') . "XX";
}

1;
