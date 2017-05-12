package Fixture::UI::Config;

use strict;
use warnings;
use Moose;
BEGIN {
    extends 'Fixture';
}
use Test::More;

sub config_test1 : Test {
    my ($self, $file) = @_;
    pass('Config test works');
}

1;
