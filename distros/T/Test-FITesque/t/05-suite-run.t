#!/usr/bin/perl -T

use strict;
use warnings;

use Test::Builder::Tester tests => 1;
use Test::More;

use Test::FITesque::Suite;
use Test::FITesque::Test;

use lib 't/lib';

my $suite = Test::FITesque::Suite->new();
my $inner_suite = Test::FITesque::Suite->new();

{
  my $test = Test::FITesque::Test->new();
  $test->add('Buddha::SuiteRunTest');
  $test->add('foo');

  my $test2 = Test::FITesque::Test->new();
  $test2->add('Buddha::SuiteRunTest');
  $test2->add('bar');

  $inner_suite->add($test, $test2);
}

my $test3 = Test::FITesque::Test->new();
$test3->add('Buddha::SuiteRunTest');
$test3->add('baz');

$suite->add($inner_suite, $test3);

test_out("not ok 1 - foo fails");
test_out("ok 2 - bar: first");
test_out("ok 3 - bar: second");
test_out("ok 4 - baz: first");
test_out("ok 5 - baz: second");
test_out("ok 6 - baz: third");
test_err(qr{#\s+Failed\ test.*?\n?.*?at\ t/lib/Buddha/SuiteRunTest\.pm\ (?:at\ )?line 9.*\n?});

$suite->run_tests();

test_test(title => q{run_tests worked as expected});
