package t::Test::Mini::Logger::TAP;
use base 'Test::Mini::TestCase';
use strict;
use warnings;

use Test::Mini::Assertions;
use Text::Outdent 'outdent';

use aliased 'IO::Scalar' => 'Buffer';
use aliased 'Test::Mini::Logger::TAP' => 'Logger';

my ($buffer, $logger);

sub setup {
    $logger = Logger->new(buffer => Buffer->new(\($buffer = '')));
}

sub error { Test::Mini::Unit::Error->new(message => "Error Message\n") }

sub tidy {
    my ($str) = @_;
    $str =~ s/^\n| +$//g;
    return outdent($str);
}

sub test_begin_test_case {
    $logger->begin_test_case('MyClass', qw/ method1 method2 method3 /);
    assert_equal $buffer, tidy(q|
        # Test Case: MyClass
    |);
}

sub test_pass {
    $logger->begin_test('MyClass', 'method1');
    $logger->pass('MyClass', 'method1');
    assert_equal $buffer, tidy(q|
        ok 1 - method1
    |);
}

sub test_two_passes {
    $logger->begin_test('MyClass', 'method1');
    $logger->pass('MyClass', 'method1');

    $logger->begin_test('MyClass', 'method2');
    $logger->pass('MyClass', 'method2');

    assert_equal $buffer, tidy(q|
        ok 1 - method1
        ok 2 - method2
    |);
}

sub test_fail {
    $logger->begin_test('MyClass', 'method1');
    $logger->fail('MyClass', 'method1', 'Reason for failure');
    assert_equal $buffer, tidy(q|
        not ok 1 - method1
        # Reason for failure
    |);
}

sub test_two_failures {
    $logger->begin_test('MyClass', 'method1');
    $logger->fail('MyClass', 'method1', 'Daddy never loved me');

    $logger->begin_test('MyClass', 'method2');
    $logger->fail('MyClass', 'method2', 'Not enough hugs');

    assert_equal $buffer, tidy(q|
        not ok 1 - method1
        # Daddy never loved me
        not ok 2 - method2
        # Not enough hugs
    |);
}

sub test_fail_with_multiline_reason {
    $logger->begin_test('MyClass', 'method1');
    $logger->fail('MyClass', 'method1', "My Own Personal Failing:\nCaring too much");
    assert_equal $buffer, tidy(q|
        not ok 1 - method1
        # My Own Personal Failing:
        # Caring too much
    |);
}

sub test_error {
    $logger->begin_test('MyClass', 'method1');
    $logger->error('MyClass', 'method1', 'Reason for error');
    assert_equal $buffer, tidy(q|
        not ok 1 - method1
        # Reason for error
    |);
}

sub test_two_errors {
    $logger->begin_test('MyClass', 'method1');
    $logger->error('MyClass', 'method1', 'Off by one');

    $logger->begin_test('MyClass', 'method2');
    $logger->error('MyClass', 'method2', 'Suicide');

    assert_equal $buffer, tidy(q|
        not ok 1 - method1
        # Off by one
        not ok 2 - method2
        # Suicide
    |);
}

sub test_error_with_multiline_reason {
    $logger->begin_test('MyClass', 'method1');
    $logger->error('MyClass', 'method1', "Death,\nIt's final");
    assert_equal $buffer, tidy(q|
        not ok 1 - method1
        # Death,
        # It's final
    |);
}

sub test_skip {
    $logger->begin_test('MyClass', 'method1');
    $logger->skip('MyClass', 'method1', "School's boring");
    assert_equal $buffer, tidy(q|
        ok 1 - method1 # SKIP: School's boring
    |);
}

sub test_two_skips {
    $logger->begin_test('MyClass', 'method1');
    $logger->skip('MyClass', 'method1', 'One, two...');

    $logger->begin_test('MyClass', 'method2');
    $logger->skip('MyClass', 'method2', '... to my Lou');

    assert_equal $buffer, tidy(q|
        ok 1 - method1 # SKIP: One, two...
        ok 2 - method2 # SKIP: ... to my Lou
    |);
}

sub test_skip_with_multiline_reason {
    $logger->begin_test('MyClass', 'method1');
    $logger->skip('MyClass', 'method1', "School's Cool\nDon't be a fool");
    assert_equal $buffer, tidy(q|
        ok 1 - method1 # SKIP
        # School's Cool
        # Don't be a fool
    |);
}

sub test_finish_test_suite {
    $logger->begin_test('MyClass', 'method1');
    $logger->begin_test('MyClass', 'method2');
    $logger->begin_test('MyClass', 'method3');
    $logger->finish_test_suite();
    assert_equal $buffer, tidy(q|
        1..3
    |);
}

1;
