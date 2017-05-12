package testcases::requires;
use strict;

use base qw(testcases::base);

sub test_requires ($$) {
    my $self=shift;

    require './requires.pl';
}

1;
