package XAO::DO::Test2;
use strict;
use base qw(XAO::SimpleHash);

sub method ($$) {
    my $self=shift;
    "XX" . (shift) . "--" . ref($self);
}

1;
