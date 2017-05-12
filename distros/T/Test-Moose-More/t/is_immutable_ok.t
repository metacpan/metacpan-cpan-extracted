use strict;
use warnings;

{ package TestClass;          use Moose; __PACKAGE__->meta->make_immutable; }
{ package TestClass::Mutable; use Moose;                                    }

use Test::Builder::Tester;
use Test::More;
use Test::Moose::More;
use TAP::SimpleOutput 0.009 'counters';

# immutable class, is_immutable_ok
{
    my ($_ok, $_nok, $_skip) = counters();
    test_out $_ok->('TestClass is immutable');
    is_immutable_ok 'TestClass';
    test_test 'is_immutable_ok, immutable class';
}

# mutable class, is_immutable_ok
{
    my ($_ok, $_nok, $_skip) = counters();
    test_out $_nok->('TestClass::Mutable is immutable');
    test_fail 1;
    is_immutable_ok 'TestClass::Mutable';
    test_test 'is_immutable_ok, mutable class';
}

# mutable class, is_not_immutable_ok
{
    my ($_ok, $_nok, $_skip) = counters();
    test_out $_ok->('TestClass::Mutable is not immutable');
    is_not_immutable_ok 'TestClass::Mutable';
    test_test 'is_not_immutable_ok, mutable class';
}

# immutable class, is_not_immutable_ok
{
    my ($_ok, $_nok, $_skip) = counters();
    test_out $_nok->('TestClass is not immutable');
    test_fail 1;
    is_not_immutable_ok 'TestClass';
    test_test 'is_not_immutable_ok, immutable class';
}

done_testing;
