package InheritedSuite::BaseTest;

use strict;
use warnings;

use Test::Unit::Lite;
use base 'Test::Unit::TestCase';

sub test_isa {
    my $self = shift;
    $self->assert($self->isa(__PACKAGE__));
}

sub test_list_tests {
    my $self = shift;
    my $list = $self->list_tests;
    $self->assert_deep_equals( [ qw{ test_base test_isa test_list_tests } ], $list);
}

sub test_base {
    my $self = shift;
    $self->assert(1);
}

1;
