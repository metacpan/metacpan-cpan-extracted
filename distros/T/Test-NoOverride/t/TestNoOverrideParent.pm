package t::TestNoOverrideParent;
use strict;
use warnings;

use parent 't::TestNoOverrideGrandpa', 't::TestNoOverrideGrandma';

sub new {
    my $class = shift;

    bless +{}, $class;
}

sub parent { __PACKAGE__ }

1;
