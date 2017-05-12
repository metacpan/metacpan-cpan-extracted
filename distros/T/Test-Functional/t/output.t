#!/usr/bin/perl
use warnings FATAL => 'all';
use strict;
#use Test::Builder::Tester tests => 1;
#use Test::Functional;
use Test::More skip_all => 'testing output is hard';

#my $nl = "\n";
#if($^O eq 'MSWin32') {
#    $nl = "\r\n";
#}
#
#sub mytest_fail {
#    my ($offset, $msg, $name) = @_;
#    $name ||= 'test';
#    my ($pkg, $file, $line) = caller();
#    $line += $offset || 0;
#    $msg ||= '';
#    my $err = <<ERR;
##   Failed test '$name'
##   at $file line $line.
#$msg
#ERR
#    $err =~ s#\n+$##;
#    @_ = ($err);
#    goto &test_err;
#}
#
#test_out("not ok 1 - test");
#mytest_fail(1, "#     died: Died at t/output.t line 31.");
#test { die } "test";
#test_test("die");
#
#test_out("not ok 1 - test");
#mytest_fail(1, "#          got: '33'$nl" . "#     expected: '34'");
#test { 33 } 34, "test";
#test_test("eqv");
#
#test_out("not ok 1 - test");
#mytest_fail(1, "#     died: Died at t/output.t line 41.");
#test { die } 34, "test";
#test_test("eqv-die");
#
#test_out("not ok 1 - test");
#mytest_fail(1, "#     objects were the same");
#test { 33 } ineqv(33), "test";
#test_test("ineqv");
#
#test_out("not ok 1 - test");
#mytest_fail(1, "#     died: Died at t/output.t line 51.");
#test { die } ineqv(33), "test";
#test_test("ineqv-die");
#
#test_out("not ok 1 - test");
#mytest_fail(1, "#     result was not of type ARRAY");
#test { sub{} } typeqv('ARRAY'), "test";
#test_test("typeqv");
#
#test_out("not ok 1 - test");
#mytest_fail(1, "#     result was undef");
#test { undef } typeqv('ARRAY'), "test";
#test_test("typeqv-undef");
#
#test_out("not ok 1 - test");
#mytest_fail(1, "#     result was not a ref");
#test { 33 } typeqv('ARRAY'), "test";
#test_test("typeqv-noref");
#
#test_out("not ok 1 - test");
#mytest_fail(1, "#     died: Died at t/output.t line 71.");
#test { die } typeqv('ARRAY'), "test";
#test_test("typeqv-die");
#
#test_out("not ok 1 - test");
#mytest_fail(1, "#     failed to die");
#test { 33 } dies, "test";
#test_test("dies");
#
#test_out("not ok 1 - test");
#mytest_fail(1, "#     died: Died at t/output.t line 81.");
#test { die } noop, "test";
#test_test("noop-die");
#
#test_out("not ok 1 - test");
#mytest_fail(1);
#test { 0 } true, "test";
#test_test("true");
#
#test_out("not ok 1 - test");
#mytest_fail(1, "#     died: Died at t/output.t line 91.");
#test { die } true, "test";
#test_test("true-die");
#
#test_out("not ok 1 - test");
#mytest_fail(1);
#test { 1 } false, "test";
#test_test("false");
#
#test_out("not ok 1 - test");
#mytest_fail(1, "#     died: Died at t/output.t line 101.");
#test { die } false, "test";
#test_test("false-die");
#
#test_out("not ok 1 - test");
#mytest_fail(1);
#test { undef } isdef, "test";
#test_test("isdef");
#
#test_out("not ok 1 - test");
#mytest_fail(1, "#     died: Died at t/output.t line 111.");
#test { die } isdef, "test";
#test_test("isdef-die");
#
#test_out("not ok 1 - test");
#mytest_fail(1);
#test { 1 } isundef, "test";
#test_test("isundef");
#
#test_out("not ok 1 - test");
#mytest_fail(1, "#     died: Died at t/output.t line 121.");
#test { die } isundef, "test";
#test_test("isundef-die");
#
#test_out("not ok 1 - test");
#mytest_fail(1, "#                   'bar'$nl#     doesn't match '(?-xism:foo)'");
#test { 'bar' } sub { like($_[0], qr/foo/, $_[1]) }, "test";
#test_test("custom");
#
#test_out("not ok 1 - test");
#mytest_fail(1, "#     died: Died at t/output.t line 131.");
#test { die } sub { like($_[0], qr/foo/, $_[1]) }, "test";
#test_test("custom-die");
#
#test_out("not ok 1 - grp.test");
#mytest_fail(2, "#          got: '8'$nl#     expected: '34'", 'grp.test');
#group {
#    pretest { 8 } 34, "test";
#    test { 19 } 19, "test2";
#} "grp";
#test_test("pretest");
#
#test_out("not ok 1 - grp.test");
#mytest_fail(2, "#     died: Died at t/output.t line 145.", 'grp.test');
#group {
#    pretest { die } 34, "test";
#    test { 19 } 19, "test2"
#} "grp";
#test_test("pretest");
#
#test_out("ok 1 # skip test");
#notest { 19 } 88, "test";
#test_test("notest-stable");
#
#Test::Functional::configure(unstable => 1, fastout => 0);
#
#test_out("not ok 1 - test");
#mytest_fail(1, "#          got: '19'$nl#     expected: '88'");
#notest { 19 } 88, "test";
#test_test("notest-unstable");
#
## there is a bug with Test::Builder::Tester that means that when
## Test::Functional calls $t->BAIL_OUT() it causes THIS test to exit. ugh.
#
#Test::Functional::configure(unstable => 0, fastout => 1);
#
#test_out("not ok 1 - grp.test");
#mytest_fail(2, "#          got: '8'$nl#     expected: '34'", 'grp.test');
#group {
#    test { 8 } 34, "test";
#    test { 19 } 19, "test2";
#} "grp";
#test_test("fastout");
