package BadUnits::WithErrorOnSetUp;

use strict;
use warnings;

use base qw(Test::Unit::TestCase);

sub set_up {
    die "Problem with set_up";
}

sub test_unit_with_error {
    my $self = shift;
    $self->assert(0);
}

1;
