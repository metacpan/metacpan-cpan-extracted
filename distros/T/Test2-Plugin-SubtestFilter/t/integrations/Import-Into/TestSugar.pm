package TestSugar;
use strict;
use warnings;

use Import::Into;

sub import {
    my $caller = caller;
    Test2::V0->import::into($caller);
    Test2::Plugin::SubtestFilter->import::into($caller);
}

1;
