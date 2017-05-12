package t::TestNoOverrideGrandpa;
use strict;
use warnings;

sub new {
    my $class = shift;

    bless +{}, $class;
}

sub grandpa { __PACKAGE__ }

sub _grandpa { __PACKAGE__ }

1;
