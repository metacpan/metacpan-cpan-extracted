package BadUnits::WithFailureSuite;

use strict;
use warnings;

use base qw(Test::Unit::TestSuite);

sub suite {
    my $suite = Test::Unit::TestSuite->empty_new('WithFailure');
    $suite->add_test('BadUnits::WithFailure');
    return $suite;
}

1;
