# Output Logger Base Class.
#
# Whether you're using a tool that expects output in a certain format, or you
# just long for the familiar look and feel of another testing framework, this
# is what you're looking for.
package Test::Mini::Logger;
use strict;
use warnings;

use Time::HiRes;

# Constructor.
#
# @param [Hash] %args Initial state for the new instance.
# @option %args verbose (0) Logger verbosity.
# @option %args buffer [IO] (STDOUT) Output buffer.
sub new {
    my ($class, %args) = @_;
    return bless {
        verbose => 0,
        buffer  => *STDOUT{IO},
        %args,
        count   => {},
        times   => {},
    }, $class;
}

# @group Attribute Accessors

# @return Logger verbosity.
sub verbose {
    my ($self) = @_;
    return $self->{verbose};
}

# @return [IO] Output buffer.
sub buffer {
    my ($self) = @_;
    return $self->{buffer};
}

# @group Output Functions

# Write output to the {#buffer}.
# Lines will be output without added newlines.
#
# @param @msg The message(s) to be printed; will be handled as per +print+.
sub print {
    my ($self, @msg) = @_;
    print { $self->buffer() } @msg;
}

# Write output to the {#buffer}.
# Lines will be output with appended newlines.
#
# @param @msg The message(s) to be printed; newlines will be appended to each
#   message, before being passed to {#print}.
sub say {
    my ($self, @msg) = @_;
    $self->print(join("\n", @msg), "\n");
}

# @group Callbacks

# Called before the test suite is run.
#
# @param [Hash] %args Options the test suite was run with.
# @option %args [String] filter Test name filter.
# @option %args [String] seed Randomness seed.
sub begin_test_suite {
    my ($self, %args) = @_;
    $self->{times}->{$self} = -Time::HiRes::time();
}

# Called before each test case is run.
#
# @param [Class] $tc The test case being run.
# @param [Array<String>] @tests A list of tests to be run.
sub begin_test_case {
    my ($self, $tc, @tests) = @_;
    $self->{times}->{$tc} = -Time::HiRes::time();
}

# Called before each test is run.
#
# @param [Class] $tc The test case owning the test method.
# @param [String] $test The name of the test method being run.
sub begin_test {
    my ($self, $tc, $test) = @_;
    $self->{times}->{"$tc#$test"} = -Time::HiRes::time();
}

# Called after each test is run.
# Increments the test and assertion counts, and finalizes the test's timing.
#
# @param [Class] $tc The test case owning the test method.
# @param [String] $test The name of the test method just run.
# @param [Integer] $assertions The number of assertions called.
sub finish_test {
    my ($self, $tc, $test, $assertions) = @_;
    $self->{count}->{test}++;
    $self->{count}->{assert} += $assertions;
    $self->{times}->{"$tc#$test"} += Time::HiRes::time();
}

# Called after each test case is run.
# Increments the test case count, and finalizes the test case's timing.
#
# @param [Class] $tc The test case just run.
# @param [Array<String>] @tests A list of tests run.
sub finish_test_case {
    my ($self, $tc, @tests) = @_;
    $self->{count}->{test_case}++;
    $self->{times}->{$tc} += Time::HiRes::time();
}

# Called after each test suite is run.
# Finalizes the test suite timing.
#
# @param [Integer] $exit_code Status the tests finished with.
sub finish_test_suite {
    my ($self, $exit_code) = @_;
    $self->{times}->{$self} += Time::HiRes::time();
}

# Called when a test passes.
# Increments the pass count.
#
# @param [Class] $tc The test case owning the test method.
# @param [String] $test The name of the passing test.
sub pass {
    my ($self, $tc, $test) = @_;
    $self->{count}->{pass}++;
}

# Called when a test is skipped.
# Increments the skip count.
#
# @param [Class] $tc The test case owning the test method.
# @param [String] $test The name of the skipped test.
# @param [Test::Mini::Exception::Skip] $e The exception object.
sub skip {
    my ($self, $tc, $test, $e) = @_;
    $self->{count}->{skip}++;
}

# Called when a test fails.
# Increments the failure count.
#
# @param [Class] $tc The test case owning the test method.
# @param [String] $test The name of the failed test.
# @param [Test::Mini::Exception::Assert] $e The exception object.
sub fail {
    my ($self, $tc, $test, $e) = @_;
    $self->{count}->{fail}++;
}

# Called when a test dies with an error.
# Increments the error count.
#
# @param [Class] $tc The test case owning the test method.
# @param [String] $test The name of the test with an error.
# @param [Test::Mini::Exception] $e The exception object.
sub error {
    my ($self, $tc, $test, $e) = @_;
    $self->{count}->{error}++;
}

# @group Statistics

# Accessor for counters.
#
# @overload count()
#   @return [Hash] The count hash.
#
# @overload count($key)
#   @param $key A key in the count hash.
#   @return [Number] The value for the given key.
sub count {
    my ($self, $key) = @_;
    return ($key ? $self->{count}->{$key} : $self->{count}) || 0;
}

# Accessor for the timing data.
#
# @param $key The key to look up timings for.  Typical values are:
#   +$self+ :: Time for test suite
#   "TestCase" :: Time for the test case
#   "TestCase#test" :: Time for the given test
#   Times for units that have not finished should not be relied upon.
# @return [Number] The time taken by the given argument, in seconds.
sub time {
    my ($self, $key) = @_;
    return $self->{times}->{$key};
}

1;