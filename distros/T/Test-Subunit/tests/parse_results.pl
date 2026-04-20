#!/usr/bin/perl
# Tests for Test::Subunit parse_results function
use strict;
use warnings;
use Test::More tests => 54;

BEGIN { use_ok('Test::Subunit', qw(parse_results)); }

# Helper package to capture method calls
package MockMsgOps;

sub new {
    my $class = shift;
    return bless {
        control_msgs => [],
        output_msgs => [],
        start_tests => [],
        end_tests => [],
        times => [],
    }, $class;
}

sub control_msg {
    my ($self, $msg) = @_;
    push @{$self->{control_msgs}}, $msg;
}

sub output_msg {
    my ($self, $msg) = @_;
    push @{$self->{output_msgs}}, $msg;
}

sub start_test {
    my ($self, $name) = @_;
    push @{$self->{start_tests}}, $name;
}

sub end_test {
    my ($self, $name, $result, $unexpected, $reason) = @_;
    push @{$self->{end_tests}}, {
        name => $name,
        result => $result,
        unexpected => $unexpected,
        reason => $reason,
    };
}

sub report_time {
    my ($self, $time) = @_;
    push @{$self->{times}}, $time;
}

package main;

# Test 1: Simple successful test
{
    my $input = "test: foo\nsuccess: foo\n";
    open my $fh, '<', \$input or die "Cannot open string for reading: $!";
    my $msg_ops = MockMsgOps->new();
    my $statistics = {
        TESTS_UNEXPECTED_OK => 0,
        TESTS_EXPECTED_OK => 0,
        TESTS_UNEXPECTED_FAIL => 0,
        TESTS_EXPECTED_FAIL => 0,
        TESTS_ERROR => 0,
        TESTS_SKIP => 0,
    };

    my $result = parse_results($msg_ops, $statistics, $fh);

    is($result, 0, "Successful test returns 0");
    is(scalar @{$msg_ops->{start_tests}}, 1, "One test started");
    is($msg_ops->{start_tests}[0], "foo", "Test name is 'foo'");
    is(scalar @{$msg_ops->{end_tests}}, 1, "One test ended");
    is($msg_ops->{end_tests}[0]{name}, "foo", "End test name is 'foo'");
    is($msg_ops->{end_tests}[0]{result}, "success", "Test result is 'success'");
    is($msg_ops->{end_tests}[0]{unexpected}, 0, "Test was not unexpected");
    is($statistics->{TESTS_EXPECTED_OK}, 1, "One expected success");
}

# Test 2: Test with 'successful' variant
{
    my $input = "test: bar\nsuccessful: bar\n";
    open my $fh, '<', \$input or die "Cannot open string for reading: $!";
    my $msg_ops = MockMsgOps->new();
    my $statistics = {
        TESTS_UNEXPECTED_OK => 0,
        TESTS_EXPECTED_OK => 0,
        TESTS_UNEXPECTED_FAIL => 0,
        TESTS_EXPECTED_FAIL => 0,
        TESTS_ERROR => 0,
        TESTS_SKIP => 0,
    };

    my $result = parse_results($msg_ops, $statistics, $fh);

    is($result, 0, "Successful test returns 0");
    is($msg_ops->{end_tests}[0]{result}, "successful", "Test result is 'successful'");
    is($statistics->{TESTS_EXPECTED_OK}, 1, "One expected success");
}

# Test 3: Failed test
{
    my $input = "test: failing_test\nfailure: failing_test\n";
    open my $fh, '<', \$input or die "Cannot open string for reading: $!";
    my $msg_ops = MockMsgOps->new();
    my $statistics = {
        TESTS_UNEXPECTED_OK => 0,
        TESTS_EXPECTED_OK => 0,
        TESTS_UNEXPECTED_FAIL => 0,
        TESTS_EXPECTED_FAIL => 0,
        TESTS_ERROR => 0,
        TESTS_SKIP => 0,
    };

    my $result = parse_results($msg_ops, $statistics, $fh);

    is($result, 1, "Failed test returns 1");
    is($msg_ops->{end_tests}[0]{result}, "failure", "Test result is 'failure'");
    is($msg_ops->{end_tests}[0]{unexpected}, 1, "Test was unexpected");
    is($statistics->{TESTS_UNEXPECTED_FAIL}, 1, "One unexpected failure");
}

# Test 4: Test with 'fail' variant
{
    my $input = "test: failing_test2\nfail: failing_test2\n";
    open my $fh, '<', \$input or die "Cannot open string for reading: $!";
    my $msg_ops = MockMsgOps->new();
    my $statistics = {
        TESTS_UNEXPECTED_OK => 0,
        TESTS_EXPECTED_OK => 0,
        TESTS_UNEXPECTED_FAIL => 0,
        TESTS_EXPECTED_FAIL => 0,
        TESTS_ERROR => 0,
        TESTS_SKIP => 0,
    };

    my $result = parse_results($msg_ops, $statistics, $fh);

    is($result, 1, "Failed test returns 1");
    is($msg_ops->{end_tests}[0]{result}, "fail", "Test result is 'fail'");
    is($statistics->{TESTS_UNEXPECTED_FAIL}, 1, "One unexpected failure");
}

# Test 5: Error test
{
    my $input = "test: error_test\nerror: error_test\n";
    open my $fh, '<', \$input or die "Cannot open string for reading: $!";
    my $msg_ops = MockMsgOps->new();
    my $statistics = {
        TESTS_UNEXPECTED_OK => 0,
        TESTS_EXPECTED_OK => 0,
        TESTS_UNEXPECTED_FAIL => 0,
        TESTS_EXPECTED_FAIL => 0,
        TESTS_ERROR => 0,
        TESTS_SKIP => 0,
    };

    my $result = parse_results($msg_ops, $statistics, $fh);

    is($result, 1, "Error test returns 1");
    is($msg_ops->{end_tests}[0]{result}, "error", "Test result is 'error'");
    is($msg_ops->{end_tests}[0]{unexpected}, 1, "Test was unexpected");
    is($statistics->{TESTS_ERROR}, 1, "One error");
}

# Test 6: Skipped test
{
    my $input = "test: skip_test\nskip: skip_test\n";
    open my $fh, '<', \$input or die "Cannot open string for reading: $!";
    my $msg_ops = MockMsgOps->new();
    my $statistics = {
        TESTS_UNEXPECTED_OK => 0,
        TESTS_EXPECTED_OK => 0,
        TESTS_UNEXPECTED_FAIL => 0,
        TESTS_EXPECTED_FAIL => 0,
        TESTS_ERROR => 0,
        TESTS_SKIP => 0,
    };

    my $result = parse_results($msg_ops, $statistics, $fh);

    is($result, 0, "Skipped test returns 0");
    is($msg_ops->{end_tests}[0]{result}, "skip", "Test result is 'skip'");
    is($msg_ops->{end_tests}[0]{unexpected}, 0, "Test was not unexpected");
    is($statistics->{TESTS_SKIP}, 1, "One skipped test");
}

# Test 7: Known failure (xfail)
{
    my $input = "test: xfail_test\nxfail: xfail_test\n";
    open my $fh, '<', \$input or die "Cannot open string for reading: $!";
    my $msg_ops = MockMsgOps->new();
    my $statistics = {
        TESTS_UNEXPECTED_OK => 0,
        TESTS_EXPECTED_OK => 0,
        TESTS_UNEXPECTED_FAIL => 0,
        TESTS_EXPECTED_FAIL => 0,
        TESTS_ERROR => 0,
        TESTS_SKIP => 0,
    };

    my $result = parse_results($msg_ops, $statistics, $fh);

    is($result, 0, "Expected failure returns 0");
    is($msg_ops->{end_tests}[0]{result}, "xfail", "Test result is 'xfail'");
    is($msg_ops->{end_tests}[0]{unexpected}, 0, "Test was not unexpected");
    is($statistics->{TESTS_EXPECTED_FAIL}, 1, "One expected failure");
}

# Test 8: Known failure (knownfail variant)
{
    my $input = "test: knownfail_test\nknownfail: knownfail_test\n";
    open my $fh, '<', \$input or die "Cannot open string for reading: $!";
    my $msg_ops = MockMsgOps->new();
    my $statistics = {
        TESTS_UNEXPECTED_OK => 0,
        TESTS_EXPECTED_OK => 0,
        TESTS_UNEXPECTED_FAIL => 0,
        TESTS_EXPECTED_FAIL => 0,
        TESTS_ERROR => 0,
        TESTS_SKIP => 0,
    };

    my $result = parse_results($msg_ops, $statistics, $fh);

    is($result, 0, "Expected failure returns 0");
    is($msg_ops->{end_tests}[0]{result}, "knownfail", "Test result is 'knownfail'");
    is($statistics->{TESTS_EXPECTED_FAIL}, 1, "One expected failure");
}

# Test 9: Test with single-line reason
{
    my $input = "test: reason_test\nfailure: reason_test [\nSomething went wrong\n]\n";
    open my $fh, '<', \$input or die "Cannot open string for reading: $!";
    my $msg_ops = MockMsgOps->new();
    my $statistics = {
        TESTS_UNEXPECTED_OK => 0,
        TESTS_EXPECTED_OK => 0,
        TESTS_UNEXPECTED_FAIL => 0,
        TESTS_EXPECTED_FAIL => 0,
        TESTS_ERROR => 0,
        TESTS_SKIP => 0,
    };

    my $result = parse_results($msg_ops, $statistics, $fh);

    is($msg_ops->{end_tests}[0]{reason}, "Something went wrong\n", "Reason captured correctly");
}

# Test 10: Test with multi-line reason
{
    my $input = "test: multiline_reason\nfailure: multiline_reason [\nLine 1\nLine 2\nLine 3\n]\n";
    open my $fh, '<', \$input or die "Cannot open string for reading: $!";
    my $msg_ops = MockMsgOps->new();
    my $statistics = {
        TESTS_UNEXPECTED_OK => 0,
        TESTS_EXPECTED_OK => 0,
        TESTS_UNEXPECTED_FAIL => 0,
        TESTS_EXPECTED_FAIL => 0,
        TESTS_ERROR => 0,
        TESTS_SKIP => 0,
    };

    my $result = parse_results($msg_ops, $statistics, $fh);

    is($msg_ops->{end_tests}[0]{reason}, "Line 1\nLine 2\nLine 3\n", "Multi-line reason captured correctly");
}

# Test 11: Interrupted reason (EOF before closing bracket)
{
    my $input = "test: interrupted\nfailure: interrupted [\nIncomplete reason";
    open my $fh, '<', \$input or die "Cannot open string for reading: $!";
    my $msg_ops = MockMsgOps->new();
    my $statistics = {
        TESTS_UNEXPECTED_OK => 0,
        TESTS_EXPECTED_OK => 0,
        TESTS_UNEXPECTED_FAIL => 0,
        TESTS_EXPECTED_FAIL => 0,
        TESTS_ERROR => 0,
        TESTS_SKIP => 0,
    };

    my $result = parse_results($msg_ops, $statistics, $fh);

    is($result, 1, "Interrupted reason returns error");
    is($statistics->{TESTS_ERROR}, 1, "Interrupted reason counted as error");
}

# Test 12: Unclosed test
{
    my $input = "test: unclosed_test\n";
    open my $fh, '<', \$input or die "Cannot open string for reading: $!";
    my $msg_ops = MockMsgOps->new();
    my $statistics = {
        TESTS_UNEXPECTED_OK => 0,
        TESTS_EXPECTED_OK => 0,
        TESTS_UNEXPECTED_FAIL => 0,
        TESTS_EXPECTED_FAIL => 0,
        TESTS_ERROR => 0,
        TESTS_SKIP => 0,
    };

    my $result = parse_results($msg_ops, $statistics, $fh);

    is($result, 1, "Unclosed test returns error");
    is(scalar @{$msg_ops->{end_tests}}, 1, "Test was closed automatically");
    is($msg_ops->{end_tests}[0]{result}, "error", "Unclosed test marked as error");
    is($msg_ops->{end_tests}[0]{reason}, "was started but never finished!", "Correct error reason");
    is($statistics->{TESTS_ERROR}, 1, "Unclosed test counted as error");
}

# Test 13: Multiple tests
{
    my $input = "test: test1\nsuccess: test1\ntest: test2\nsuccess: test2\n";
    open my $fh, '<', \$input or die "Cannot open string for reading: $!";
    my $msg_ops = MockMsgOps->new();
    my $statistics = {
        TESTS_UNEXPECTED_OK => 0,
        TESTS_EXPECTED_OK => 0,
        TESTS_UNEXPECTED_FAIL => 0,
        TESTS_EXPECTED_FAIL => 0,
        TESTS_ERROR => 0,
        TESTS_SKIP => 0,
    };

    my $result = parse_results($msg_ops, $statistics, $fh);

    is($result, 0, "Multiple successful tests return 0");
    is(scalar @{$msg_ops->{start_tests}}, 2, "Two tests started");
    is(scalar @{$msg_ops->{end_tests}}, 2, "Two tests ended");
    is($statistics->{TESTS_EXPECTED_OK}, 2, "Two expected successes");
}

# Test 14: Mixed results
{
    my $input = "test: test1\nsuccess: test1\ntest: test2\nfailure: test2\n";
    open my $fh, '<', \$input or die "Cannot open string for reading: $!";
    my $msg_ops = MockMsgOps->new();
    my $statistics = {
        TESTS_UNEXPECTED_OK => 0,
        TESTS_EXPECTED_OK => 0,
        TESTS_UNEXPECTED_FAIL => 0,
        TESTS_EXPECTED_FAIL => 0,
        TESTS_ERROR => 0,
        TESTS_SKIP => 0,
    };

    my $result = parse_results($msg_ops, $statistics, $fh);

    is($result, 1, "Mixed results with failure returns 1");
    is($statistics->{TESTS_EXPECTED_OK}, 1, "One expected success");
    is($statistics->{TESTS_UNEXPECTED_FAIL}, 1, "One unexpected failure");
}

# Test 15: Output messages
{
    my $input = "Some output\ntest: test1\nMore output\nsuccess: test1\nFinal output\n";
    open my $fh, '<', \$input or die "Cannot open string for reading: $!";
    my $msg_ops = MockMsgOps->new();
    my $statistics = {
        TESTS_UNEXPECTED_OK => 0,
        TESTS_EXPECTED_OK => 0,
        TESTS_UNEXPECTED_FAIL => 0,
        TESTS_EXPECTED_FAIL => 0,
        TESTS_ERROR => 0,
        TESTS_SKIP => 0,
    };

    my $result = parse_results($msg_ops, $statistics, $fh);

    is(scalar @{$msg_ops->{output_msgs}}, 3, "Three output messages captured");
    is($msg_ops->{output_msgs}[0], "Some output\n", "First output message correct");
    is($msg_ops->{output_msgs}[1], "More output\n", "Second output message correct");
    is($msg_ops->{output_msgs}[2], "Final output\n", "Third output message correct");
}
