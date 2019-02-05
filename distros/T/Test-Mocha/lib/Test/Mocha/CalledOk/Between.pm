package Test::Mocha::CalledOk::Between;
# ABSTRACT: Concrete subclass of CalledOk for verifying methods called 'between' a min and max number of times
$Test::Mocha::CalledOk::Between::VERSION = '0.66';
use parent 'Test::Mocha::CalledOk';
use strict;
use warnings;

sub is {
    # uncoverable pod
    my ( $class, $got, $exp ) = @_;
    return $exp->[0] <= $got && $got <= $exp->[1];
}

sub stringify {
    # uncoverable pod
    my ( $class, $exp ) = @_;
    return "between $exp->[0] and $exp->[1] time(s)";
}

1;
