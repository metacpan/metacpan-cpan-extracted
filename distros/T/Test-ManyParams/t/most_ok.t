#!/usr/bin/perl

use strict;
use warnings;

use Test::ManyParams;
use Test::More;
use Test::Exception;
use Test::Builder::Tester tests => 33;
use Data::Dumper;
use t'CommonStuff;

Test::Builder::Tester::color(1);

sub always_true_is_always_true($;$) {
    my ($params, $testname) = @_;
    test_out "ok 1" . ($testname ? " - $testname" : "");
    $testname ? most_ok { 1 } $params => 5, $testname : most_ok { 1 } $params => 5;
    test_test "Everything should be O.K., if sub always returns true ".
              _dump_params({params => $params, testname => $testname});
}

sub fails_at_a_value {
    my $testname = shift;
    my $params = [ ['a', 'a', 'a'], ['b', 'b', 'b'], ['c', 'c', 'c'] ];
    foreach my $fail_nr (0 .. 9) {
        my $nr = 0;
        test_out "not ok 1" . ($testname ? " - $testname" : "");
        test_fail +3;
        test_diag "Tests with most (10) of the parameters: " . _dump_params($params,"with quotes");
        test_diag "Failed using these parameters: " . _dump_params(['a','b','c'],"with quotes");
        most_ok { $nr++ != $fail_nr } $params => 10, $testname;
        test_test "most_ok should fail at the $fail_nr (st/nd/th) run";
    }
}

sub doesn_t_fail_but_would_normally {
    my $testname = shift;
    my $params = [ ['a', 'a', 'a'], ['b', 'b', 'b'], ['c', 'c', 'c'] ];
    test_out "ok 1" . ($testname ? " - $testname" : "");
    my $nr = 0;
    most_ok {$nr++ < 200} [0 .. 1000] => 100, $testname;
    test_test "most_ok fails at the 200th call, but only 100 are allowed";
}

foreach (STANDARD_PARAMETERS()) {
    my ($params) = @$_;
    always_true_is_always_true $params;
    always_true_is_always_true $params, "With any testname";
}

foreach my $testname (undef, "With a testname") {
    fails_at_a_value($testname);
    doesn_t_fail_but_would_normally($testname);
}

dies_ok { most_ok { 1 } [ [1 .. 10], 11, 12, 13 ] => 3 }
        "Used a an array of arrays and not-arrays, what's not ok and should die";
dies_ok { most_ok { 1 } [1 .. 10] => "some" }
        "Used a non-number as parameter argument";
dies_ok { most_ok { 1 } [1 .. 10] => -4 }
        "Used a negative number as parameter argument";
