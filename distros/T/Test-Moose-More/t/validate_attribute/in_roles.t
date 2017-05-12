use strict;
use warnings;

use Test::Builder::Tester;
use Test::More;
use Test::Moose::More;
use TAP::SimpleOutput 0.009 'counters';

{
    package TestRole;
    use Moose::Role;
    use namespace::autoclean;

    has thinger => (is => 'ro', predicate => 'has_thinger');
}

subtest 'a standalone run of validate_attribute (thinger)' => sub {

    validate_attribute TestRole => thinger => (
        reader    => 'thinger',
        predicate => 'has_thinger',
    );
};

{
    note my $test_title = 'validate_attribute() for a valid role attribute';
    my ($_ok, $_nok, $_skip, $_todo, $_other) = counters();
    test_out $_ok->('TestRole has an attribute named thinger');
    test_out $_skip->('cannot yet test role attribute layouts');
    validate_attribute TestRole => thinger => (
        reader    => 'thinger',
        predicate => 'has_thinger',
    );
    test_test $test_title;
}

{
    note my $test_title = 'validate_attribute() for an invalid role attribute';
    my ($_ok, $_nok, $_skip, $_todo, $_other) = counters();
    test_out $_nok->('TestRole has an attribute named dne');
    test_fail 1;
    validate_attribute TestRole => dne => (
        reader    => 'dne',
        predicate => 'has_dne',
    );
    test_test $test_title;
}

done_testing;
