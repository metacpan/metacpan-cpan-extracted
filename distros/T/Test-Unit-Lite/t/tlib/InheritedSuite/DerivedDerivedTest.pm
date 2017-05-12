package InheritedSuite::DerivedDerivedTest;

use strict;
use warnings;

use Test::Unit::Lite;
use base 'InheritedSuite::DerivedTest';

sub test_isa {
    my $self = shift;
    $self->assert($self->isa(__PACKAGE__));
    $self->assert($self->isa('InheritedSuite::BaseTest'));
    $self->assert($self->isa('InheritedSuite::DerivedDerivedTest'));
}

sub test_list_tests {
    my $self = shift;
    my $list = $self->list_tests;
    $self->assert_deep_equals( [ qw{ test_base test_derived test_derived_derived test_isa test_list_tests } ], $list);
}

sub test_derived_derived {
    my $self = shift;
    $self->assert(1);
}

1;
