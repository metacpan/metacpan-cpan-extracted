package BadUnits::WithFailure;

use strict;
use warnings;

use base qw(Test::Unit::TestCase);

sub test_unit_with_failure {
    my $self = shift;
    $self->assert_equals("String", "%s pattern shouldn't provoke failure on tainted mode");
}

1;
