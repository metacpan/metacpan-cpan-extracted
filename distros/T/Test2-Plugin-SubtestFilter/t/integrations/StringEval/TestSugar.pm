package TestSugar;
use strict;
use warnings;

sub import {
    my $caller = caller;

    # Import Test2::V0 and SubtestFilter via string eval
    eval qq{
        package $caller;
        use Test2::V0;
        use Test2::Plugin::SubtestFilter;
    };
    die $@ if $@;
}

1;
