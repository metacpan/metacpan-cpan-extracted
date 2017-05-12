#!/usr/bin/perl

use strict;
use warnings;

use Test::ManyParams;
use Test::More;
use Test::Exception;
use Test::Builder::Tester tests => 239;
use Data::Dumper;
use t'CommonStuff;

Test::Builder::Tester::color(1);

sub always_true_is_always_true($;$) {
    my ($params, $testname) = @_;
    test_out "ok 1" . ($testname ? " - $testname" : "");
    $testname ? all_are { 42 } 42, $params, $testname : all_are { 42 } 42, $params;
    test_test "Everything should be O.K., if sub always returns true ".
              _dump_params({params => $params, testname => $testname});
}

sub fails_at_a_value($$;$) {
    my ($params, $fail_params, $testname) = @_;
    test_out "not ok 1" . ($testname ? " - $testname" : "");
    test_fail +5;
    test_diag "Tests with the parameters: " . _dump_params($params);
    test_diag "Failed first using these parameters: " . _dump_params($fail_params);
    test_diag "Expected: " . _dump_params(42);
    test_diag "but found: " . _dump_params("42.0",'with_quotes');
    all_are { eq_array(\@_, $fail_params) ? "42.0" : 42 } 42, $params, $testname;
    test_test "all_are should fail" .
              _dump_params({params => $params, fail => $fail_params, testname => $testname});
}

foreach (STANDARD_PARAMETERS()) {
    my ($params, $values) = @$_;
    always_true_is_always_true $params;
    always_true_is_always_true $params, "With any testname";
    foreach (@$values) {
        my $fail_params = [split //];
        fails_at_a_value $params, $fail_params;
        fails_at_a_value $params, $fail_params, "With a testname";
    }
}

dies_ok { all_are { 1 } 1, [ [1 .. 10], 11, 12, 13 ] }
        "Used a an array of arrays and not-arrays, what's not ok and should die";
