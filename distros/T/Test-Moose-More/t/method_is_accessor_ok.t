use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use Test::Builder::Tester;
use TAP::SimpleOutput;

{ package A; use Moose::Role; has a => (is => 'rw'); sub a1 {} }
{ package B; use Moose;       has b => (is => 'rw'); sub b1 {} }
{ package C; use Moose; extends 'B'; with 'A'; sub c1 {} }


subtest standalone => sub {

    # method_is_accessor_ok A => 'a';
    method_is_accessor_ok B => 'b';
    method_is_accessor_ok C => 'a';
    method_is_accessor_ok C => 'b';
};

note 'pass (TBT)';
{
    my ($_ok, $_nok) = counters;
    test_out $_ok->(q{B's method b is an accessor method});
    method_is_accessor_ok B => 'b';
    test_test;
}

note 'fails - DNE method (TBT)';
{
    my ($_ok, $_nok) = counters;
    test_out $_nok->('C has no method dne');
    test_fail 1;
    method_is_accessor_ok C => 'dne';
    test_test;
}

note 'fails (TBT)';
{
    my ($_ok, $_nok) = counters;
    test_out $_nok->(q{C's method b1 is an accessor method});
    test_fail 1;
    method_is_accessor_ok C => 'b1';
    test_test;
}

done_testing;
