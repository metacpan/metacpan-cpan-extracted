package Fixture::UI;

use strict;
use warnings;
use Moose;
BEGIN {
    extends 'Fixture';
}
use Test::More;

sub ui_test1 : Test {
    my ($self, $file) = @_;
    pass('UI test works');
}

1;
