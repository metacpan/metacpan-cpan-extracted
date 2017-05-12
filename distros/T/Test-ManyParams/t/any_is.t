#!/usr/bin/perl

use strict;
use warnings;

use Test::ManyParams;
use Test::More;
use Test::Exception;
use Test::Builder::Tester tests => 247;
use Data::Dumper;
use t'CommonStuff;

Test::Builder::Tester::color(1);

sub always_true_is_always_true($;$) {
    my ($params, $testname) = @_;
    test_out "ok 1" . ($testname ? " - $testname" : "");
    $testname ? any_is { 1 } 1, $params, $testname : any_is { 1 } 1, $params;
    test_test "Everything should be O.K., if sub always returns 1 ".
              _dump_params({params => $params, testname => $testname});
}

sub only_one_value_is_ok($$;$) {
    my ($params, $ok_params, $testname) = @_;
    test_out "ok 1" . ($testname ? " - $testname" : "");
    any_is { eq_array(\@_, $ok_params) ? 1 : 0 } 1, $params, $testname;
    test_test "any_is should be correct with" .
              _dump_params({params => $params, valid => $ok_params, testname => $testname});
}

sub all_values_arent_ok($;$) {
    my ($params, $testname) = @_;
    test_out "not ok 1" . ($testname ? " - $testname" : "");
    test_fail +3;
    test_diag "Expected: " . _dump_params(42);
    test_diag "but didn't found it with at least one parameter";
    any_is { 0 } 42, $params, $testname;
    test_test "no true values should fail (". 
              _dump_params(params => $params, testname => $testname);
}

foreach (STANDARD_PARAMETERS()) {
    my ($params, $values) = @$_;
    always_true_is_always_true $params;
    always_true_is_always_true $params, "With a testname";
    all_values_arent_ok        $params;
    all_values_arent_ok        $params, "With a testname";
    foreach (@$values) {
        my $ok_params = [split //];
        only_one_value_is_ok $params, $ok_params;
        only_one_value_is_ok $params, $ok_params, "With a testname";
    }
}

dies_ok { any_is { 1 } 1, [ [1 .. 10], 11, 12, 13 ] }
        "Used a an array of arrays and not-arrays, what's not ok and should die";
