#!/usr/bin/perl
use strict;
use warnings;

use Throw;
use Test::More tests => 11;

my $input = "This is a test.";
eval{throw $input};
my $e = $@;
my $output = "$e";
cmp_ok(ref $e, 'eq', "Throw", 'Basic Throw is Object.');
cmp_ok($output, 'eq', $input."\n", 'Basic Test String Passes Compare.');

$input = "This is a test2.";
eval{throw($input)};
$e = $@;
$output = "$e";
cmp_ok($output, 'eq', $input."\n", 'Parens Test String Passes Compare.');

$input = "This is a test3.";
my $info = "A test.";
eval{throw $input, {info => $info} };
$e = $@;
$output = $e->{'error'};
cmp_ok($output, 'eq', $input, 'Info Test Passed Error String Correctly.');
$output = $e->{'info'};
cmp_ok($output, 'eq', $info, 'Info Test Passed Input String Correctly.');

$input = "This is a test4.";
eval{throw $input, {trace => 1} };
$e = $@;
$output = $e->{'error'};
cmp_ok($output, 'eq', $input, 'Trace 1 Passed Error String Correctly.');
$output = $e->{'trace'};
like($output, qr/^Called\sfrom/, "Trace 1 Test Has 'Called from' ");

$input = "This is a test5.";
eval{throw $input, {trace => 2} };
$e = $@;
$output = $e->{'error'};
cmp_ok($output, 'eq', $input, 'Trace 2 Passed Error String Correctly.');
$output = $e->{'trace'};
like($output, qr/at\st\/throw\.t\sline/, "Trace 2 Test Has 'at line' ");

$input = "This is a test6.";
eval{throw $input, {trace => 3} };
$e = $@;
$output = $e->{'error'};
cmp_ok($output, 'eq', $input, 'Trace 3 Passed Error String Correctly.');
$output = $e->{'trace'};
like($output, qr/at\st\/throw\.t\sline/, "Trace 3 Test Has 'at line' ");

1;
