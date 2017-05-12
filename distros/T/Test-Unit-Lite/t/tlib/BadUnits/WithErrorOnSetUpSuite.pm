package BadUnits::WithErrorOnSetUpSuite;

use strict;
use warnings;

use base qw(Test::Unit::TestSuite);

sub suite {
    my $suite = Test::Unit::TestSuite->empty_new('WithErrorOnSetUp');
    $suite->add_test('BadUnits::WithErrorOnSetUp');
    return $suite;
}

1;
