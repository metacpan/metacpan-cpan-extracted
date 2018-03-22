package Foo;

use Test2::Tools::xUnit;
use Test2::V0;
use Scalar::Util qw(blessed reftype);

sub first_argument_should_be_foo_object : Test {
    my $self = shift;
    is blessed($self), 'Foo';
}

sub first_argument_should_be_reference_to_blessed_hash : Test {
    my $self = shift;
    is reftype($self), 'HASH';
}

done_testing;
