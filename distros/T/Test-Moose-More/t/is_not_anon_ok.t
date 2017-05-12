use strict;
use warnings;

use Test::Builder::Tester;
use Moose::Util 'with_traits';
use Test::More;
use Test::Moose::More;
use TAP::SimpleOutput 'counters';

{ package TestRole; use Moose::Role; use namespace::autoclean; }
{ package TestClass; use Moose; }

# initial tests, covering the most straight-forward cases (IMHO)

my $anon_class = with_traits('TestClass' => 'TestRole');
my $anon_role  = Moose::Meta::Role
    ->create_anon_role(weaken => 0)
    ->name
    ;

note 'simple anon class';
{
    my ($_ok, $_nok, $_skip) = counters();
    test_out $_nok->("$anon_class is not anonymous");
    test_fail 1;
    is_not_anon_ok $anon_class;
    test_test 'is_not_anon_ok works correctly on anon class';
}

note 'simple anon role';
{
    my ($_ok, $_nok, $_skip) = counters();
    test_out $_nok->("$anon_role is not anonymous");
    test_fail 1;
    is_not_anon_ok $anon_role;
    test_test 'is_not_anon_ok works correctly on anon role';
}

note 'simple !anon class';
{
    my ($_ok, $_nok, $_skip) = counters();
    test_out $_ok->('TestClass is not anonymous');
    is_not_anon_ok 'TestClass';
    test_test 'is_not_anon_ok works correctly on !anon class';
}

note 'simple !anon role';
{
    my ($_ok, $_nok, $_skip) = counters();
    test_out $_ok->('TestRole is not anonymous');
    is_not_anon_ok 'TestRole';
    test_test 'is_not_anon_ok works correctly on !anon role';
}

done_testing;
