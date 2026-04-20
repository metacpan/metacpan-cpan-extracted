#!/usr/bin/perl
# Tests for Test::Subunit output functions
use strict;
use warnings;
use Test::More tests => 23;
use POSIX;

BEGIN {
    use_ok('Test::Subunit', qw(
        start_test end_test skip_test fail_test success_test xfail_test
        report_time progress progress_push progress_pop
    ));
}

# Helper to capture STDOUT
sub capture_output(&) {
    my $code = shift;
    my $output = '';
    open my $fh, '>', \$output or die "Cannot open string for writing: $!";
    my $old_fh = select $fh;
    $code->();
    select $old_fh;
    close $fh;
    return $output;
}

# Test start_test
{
    my $output = capture_output { Test::Subunit::start_test("test_name"); };
    is($output, "test: test_name\n", "start_test outputs correct format");
}

{
    my $output = capture_output { Test::Subunit::start_test("test with spaces"); };
    is($output, "test: test with spaces\n", "start_test handles spaces in name");
}

# Test end_test - success without reason
{
    my $output = capture_output { Test::Subunit::end_test("test1", "success"); };
    is($output, "success: test1\n", "end_test success without reason");
}

# Test end_test - success with reason
{
    my $output = capture_output { Test::Subunit::end_test("test2", "success", "all good"); };
    is($output, "success: test2 [\nall good]\n", "end_test success with reason");
}

# Test end_test - failure without reason
{
    my $output = capture_output { Test::Subunit::end_test("test3", "failure"); };
    is($output, "failure: test3\n", "end_test failure without reason");
}

# Test end_test - failure with reason
{
    my $output = capture_output { Test::Subunit::end_test("test4", "failure", "assertion failed"); };
    is($output, "failure: test4 [\nassertion failed]\n", "end_test failure with reason");
}

# Test end_test - error with reason
{
    my $output = capture_output { Test::Subunit::end_test("test5", "error", "exception thrown"); };
    is($output, "error: test5 [\nexception thrown]\n", "end_test error with reason");
}

# Test skip_test without reason
{
    my $output = capture_output { Test::Subunit::skip_test("skip1"); };
    is($output, "skip: skip1\n", "skip_test without reason");
}

# Test skip_test with reason
{
    my $output = capture_output { Test::Subunit::skip_test("skip2", "not applicable"); };
    is($output, "skip: skip2 [\nnot applicable]\n", "skip_test with reason");
}

# Test fail_test without reason
{
    my $output = capture_output { Test::Subunit::fail_test("fail1"); };
    is($output, "failure: fail1\n", "fail_test without reason");
}

# Test fail_test with reason
{
    my $output = capture_output { Test::Subunit::fail_test("fail2", "check failed"); };
    is($output, "failure: fail2 [\ncheck failed]\n", "fail_test with reason");
}

# Test success_test without reason
{
    my $output = capture_output { Test::Subunit::success_test("success1"); };
    is($output, "success: success1\n", "success_test without reason");
}

# Test success_test with reason
{
    my $output = capture_output { Test::Subunit::success_test("success2", "passed"); };
    is($output, "success: success2 [\npassed]\n", "success_test with reason");
}

# Test xfail_test without reason
{
    my $output = capture_output { Test::Subunit::xfail_test("xfail1"); };
    is($output, "xfail: xfail1\n", "xfail_test without reason");
}

# Test xfail_test with reason
{
    my $output = capture_output { Test::Subunit::xfail_test("xfail2", "known bug #123"); };
    is($output, "xfail: xfail2 [\nknown bug #123]\n", "xfail_test with reason");
}

# Test report_time
{
    # Test with a known timestamp: 2024-03-15 14:30:45 UTC
    # mktime expects local time, so we need to use a timestamp
    my $test_time = mktime(45, 30, 14, 15, 2, 124); # 2024-03-15 14:30:45
    my $output = capture_output { Test::Subunit::report_time($test_time); };

    # The output format is: time: YYYY-MM-DD HH:MM:SSZ
    # We just check it matches the expected pattern and contains the year
    like($output, qr/^time: \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}Z\n$/,
         "report_time outputs correct format");
    like($output, qr/2024/, "report_time includes correct year");
}

# Test progress without whence
{
    my $output = capture_output { Test::Subunit::progress(5); };
    is($output, "progress: 5\n", "progress without whence");
}

# Test progress with + whence
{
    my $output = capture_output { Test::Subunit::progress(3, "+"); };
    is($output, "progress: +3\n", "progress with + whence");
}

# Test progress with - whence
{
    my $output = capture_output { Test::Subunit::progress(2, "-"); };
    is($output, "progress: -2\n", "progress with - whence");
}

# Test progress_push
{
    my $output = capture_output { Test::Subunit::progress_push(); };
    is($output, "progress: push\n", "progress_push outputs correct format");
}

# Test progress_pop
{
    my $output = capture_output { Test::Subunit::progress_pop(); };
    is($output, "progress: pop\n", "progress_pop outputs correct format");
}
