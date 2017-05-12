use strict;
use warnings;

use Test::Builder::Tester;
use Moose::Util 'with_traits';
use Test::More;
use Test::Moose::More;
use TAP::SimpleOutput 'counters';

{
    package TestRole;
    use Moose::Role;
    around hiya   => sub {  };
    before there  => sub {  };
    after  sailor => sub {  };
}

subtest 'sanity checks of the tests themselves' => sub {
    role_wraps_around_method_ok 'TestRole' => 'hiya';
    role_wraps_before_method_ok 'TestRole' => 'there';
    role_wraps_after_method_ok  'TestRole' => 'sailor';
};


{
    note 'role_wraps_around_method_ok';
    my ($_ok, $_nok, $_skip) = counters();
    test_out $_ok->('TestRole wraps around method hiya');
    test_out $_nok->('TestRole wraps around method sailor');
    test_fail(2);
    role_wraps_around_method_ok 'TestRole' => 'hiya';
    role_wraps_around_method_ok 'TestRole' => 'sailor';
    test_test 'role_wraps_around_method_ok OK';
}

{
    note 'role_wraps_before_method_ok';
    my ($_ok, $_nok, $_skip) = counters();
    test_out $_ok->('TestRole wraps before method there');
    test_out $_nok->('TestRole wraps before method sailor');
    test_fail(2);
    role_wraps_before_method_ok 'TestRole' => 'there';
    role_wraps_before_method_ok 'TestRole' => 'sailor';
    test_test 'role_wraps_before_method_ok OK';
}

{
    note 'role_wraps_after_method_ok';
    my ($_ok, $_nok, $_skip) = counters();
    test_out $_ok->('TestRole wraps after method sailor');
    test_out $_nok->('TestRole wraps after method hiya');
    test_fail(2);
    role_wraps_after_method_ok 'TestRole' => 'sailor';
    role_wraps_after_method_ok 'TestRole' => 'hiya';
    test_test 'role_wraps_after_method_ok OK';
}

done_testing;
