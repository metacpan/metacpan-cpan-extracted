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

    method_is_not_accessor_ok A => 'a1';
    method_is_not_accessor_ok B => 'b1';
    method_is_not_accessor_ok C => 'a1';
    method_is_not_accessor_ok C => 'b1';
};


note 'pass (TBT)';
{
    my ($_ok, $_nok) = counters;
    test_out $_ok->(q{B's method b1 is not an accessor method});
    method_is_not_accessor_ok B => 'b1';
    test_test;
}

note 'fails - DNE method (TBT)';
{
    my ($_ok, $_nok) = counters;
    test_out $_nok->('C has no method dne');
    test_fail 1;
    method_is_not_accessor_ok C => 'dne';
    test_test;
}

note 'fails (TBT)';
{
    my ($_ok, $_nok) = counters;
    test_out $_nok->(q{C's method b is not an accessor method});
    test_fail 1;
    method_is_not_accessor_ok C => 'b';
    test_test;
}

done_testing;
