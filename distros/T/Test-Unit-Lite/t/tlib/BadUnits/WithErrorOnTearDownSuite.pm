package BadUnits::WithErrorOnTearDownSuite;

use strict;
use warnings;

use base qw(Test::Unit::TestSuite);

sub suite {
    my $suite = Test::Unit::TestSuite->empty_new('WithErrorOnTearDown');
    $suite->add_test('BadUnits::WithErrorOnTearDown');
    return $suite;
}

1;
