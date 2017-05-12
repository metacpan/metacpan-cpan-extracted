package Test::Mocha::CalledOk::AtLeast;
# ABSTRACT: Concrete subclass of CalledOk for verifying methods called 'atleast' number of times
$Test::Mocha::CalledOk::AtLeast::VERSION = '0.64';
use parent 'Test::Mocha::CalledOk';
use strict;
use warnings;

sub is {
    # uncoverable pod
    my ( $class, $got, $exp ) = @_;
    return $got >= $exp;
}

sub stringify {
    # uncoverable pod
    my ( $class, $exp ) = @_;
    return "at least $exp time(s)";
}

1;
