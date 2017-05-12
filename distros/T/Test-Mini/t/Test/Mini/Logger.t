package t::Test::Mini::Logger;
use base 'Test::Mini::TestCase';
use strict;
use warnings;

use Test::Mini::Assertions;
use Time::HiRes ('sleep');

use aliased 'IO::Scalar'         => 'Buffer';
use aliased 'Test::Mini::Logger' => 'Logger';

my ($buffer, $logger);

sub setup {
    $logger = Logger->new(buffer => Buffer->new(\($buffer = '')));
}

sub test_full_test_run_should_remain_silent {
    $logger->begin_test_suite();
    $logger->begin_test_case('MyClass');
    $logger->begin_test('MyClass', 'm1');
    $logger->pass('MyClass', 'm1');
    $logger->finish_test('MyClass', 'm1', 1);
    $logger->begin_test('MyClass', 'm2');
    $logger->fail('MyClass', 'm2', 'failure message');
    $logger->finish_test('MyClass', 'm2', 2);
    $logger->begin_test('MyClass', 'm3');
    $logger->error('MyClass', 'm3', 'error message');
    $logger->finish_test('MyClass', 'm3', 3);
    $logger->begin_test('MyClass', 'm4');
    $logger->skip('MyClass', 'm4', 'reason');
    $logger->finish_test('MyClass', 'm4', 0);
    $logger->finish_test_case('MyClass', qw/ m1 m2 m3 m4 /);
    $logger->finish_test_suite(1);

    assert_equal $buffer, '';
}

sub test_print {
    $logger->print(qw/foo bar baz/);
    assert_equal($buffer, 'foobarbaz');
}

sub test_say {
    $logger->say(qw/foo bar baz/);
    assert_equal($buffer, "foo\nbar\nbaz\n");
}

sub test_timings {
    $logger->begin_test_suite();
    $logger->begin_test_case('TestCaseOne');
    $logger->begin_test(TestCaseOne => 'test_one');
    sleep(0.1);
    $logger->finish_test(TestCaseOne => 'test_one', 1);
    $logger->begin_test(TestCaseOne => 'test_two');
    sleep(0.2);
    $logger->finish_test(TestCaseOne => 'test_two', 1);
    $logger->finish_test_case(TestCaseOne => qw/ test_one test_two /);
    $logger->begin_test_case('TestCaseTwo');
    $logger->begin_test(TestCaseTwo => 'test_one');
    sleep(0.4);
    $logger->finish_test(TestCaseTwo => 'test_one', 1);
    $logger->finish_test_case(TestCaseTwo => qw/ test_one /);
    $logger->finish_test_suite();

    assert_in_epsilon($logger->time('TestCaseOne#test_one'), 0.1, 0.3);
    assert_in_epsilon($logger->time('TestCaseOne#test_two'), 0.2, 0.3);
    assert_in_epsilon($logger->time('TestCaseOne'),          0.3, 0.3);
    assert_in_epsilon($logger->time('TestCaseTwo#test_one'), 0.4, 0.3);
    assert_in_epsilon($logger->time('TestCaseTwo'),          0.4, 0.3);
    assert_in_epsilon($logger->time($logger),                0.7, 0.3);
}

sub test_count {
    $logger->pass('MyClass', 'm1');
    $logger->finish_test('MyClass', 'm1', 1);
    $logger->error('MyClass', 'm2');
    $logger->finish_test('MyClass', 'm2', 2);
    $logger->pass('MyClass', 'm3');
    $logger->finish_test('MyClass', 'm3', 4);

    assert_equal($logger->count, {test => 3, pass => 2, error => 1, assert => 7});
    assert_equal($logger->count('fail'), 0);
    assert_equal($logger->count('error'), 1);
    assert_equal($logger->count('pass'), 2);
    assert_equal($logger->count('test'), 3);
    assert_equal($logger->count('assert'), 7);

    assert_equal($logger->count('daily build of rome'), 0);
}

1;
