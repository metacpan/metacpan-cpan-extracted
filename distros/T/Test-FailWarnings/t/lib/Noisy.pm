use 5.008001;
use strict;
use warnings;

package Noisy;

sub do_it {
    warn "I am noisy";
}

sub with_newline {
    warn "No line number\n";
}

1;

