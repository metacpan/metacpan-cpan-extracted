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

    method_from_pkg_ok C => 'a', 'A';
    method_from_pkg_ok C => 'b', 'B';
    method_from_pkg_ok C => 'c', 'C';
};

note 'pass (TBT)';
{
    my ($_ok, $_nok) = counters;
    test_out $_ok->(q{C's method a is from A});
    method_from_pkg_ok C => 'a', 'A';
    test_test;
}

note 'fails - DNE method (TBT)';
{
    my ($_ok, $_nok) = counters;
    test_out $_nok->('C has no method dne');
    test_fail 1;
    method_from_pkg_ok C => 'dne', 'A';
    test_test;
}

note 'fails (TBT)';
{
    my ($_ok, $_nok) = counters;
    test_out $_nok->(q{C's method b is from A});
    test_fail 1;
    method_from_pkg_ok C => 'b', 'A';
    test_test;
}

done_testing;
