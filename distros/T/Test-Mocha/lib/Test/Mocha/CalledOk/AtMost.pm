package Test::Mocha::CalledOk::AtMost;
# ABSTRACT: Concrete subclass of CalledOk for verifying methods called 'atmost' number of times
$Test::Mocha::CalledOk::AtMost::VERSION = '0.67';
use parent 'Test::Mocha::CalledOk';
use strict;
use warnings;

sub is {
    # uncoverable pod
    my ( $class, $got, $exp ) = @_;
    return $got <= $exp;
}

sub stringify {
    # uncoverable pod
    my ( $class, $exp ) = @_;
    return "at most $exp time(s)";
}

1;
