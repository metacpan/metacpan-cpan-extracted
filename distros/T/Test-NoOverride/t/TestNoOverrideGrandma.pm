package t::TestNoOverrideGrandma;
use strict;
use warnings;

sub new {
    my $class = shift;

    bless +{}, $class;
}

sub grandma { __PACKAGE__ }

1;
