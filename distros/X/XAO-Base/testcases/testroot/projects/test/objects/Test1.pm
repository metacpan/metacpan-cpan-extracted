package XAO::DO::Test1;
use strict;
use base qw(XAO::SimpleHash);

sub method ($) {
    "XX" . (shift) . "XX";
}

1;
