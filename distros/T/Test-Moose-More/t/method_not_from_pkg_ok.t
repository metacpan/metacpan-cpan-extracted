use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use Test::Builder::Tester;
use TAP::SimpleOutput;

{ package A; use Moose::Role; sub a {} }
{ package B; use Moose;       sub b {} }
{ package C; use Moose; extends 'B'; with 'A'; sub c {} }


subtest standalone => sub {

    method_not_from_pkg_ok C => 'a', 'B';
    method_not_from_pkg_ok C => 'b', 'C';
    method_not_from_pkg_ok C => 'c', 'A';
};

note 'pass (TBT)';
{
    my ($_ok, $_nok) = counters;
    test_out $_ok->(q{C's method b is not from A});
    method_not_from_pkg_ok C => 'b', 'A';
    test_test;
}

note 'fails - DNE method (TBT)';
{
    my ($_ok, $_nok) = counters;
    test_out $_nok->('C has no method dne');
    test_fail 1;
    method_not_from_pkg_ok C => 'dne', 'A';
    test_test;
}

note 'fails (TBT)';
{
    my ($_ok, $_nok) = counters;
    test_out $_nok->(q{C's method a is not from A});
    test_fail 1;
    method_not_from_pkg_ok C => 'a', 'A';
    test_test;
}

done_testing;
