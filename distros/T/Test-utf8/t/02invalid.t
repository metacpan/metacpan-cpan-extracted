#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;
use Test::Builder::Tester;
use Test::utf8;
use Encode;

####
# basic passing tests



test_out("ok 1 - valid string test");
is_valid_string("foo");
test_test("valid string");



test_out("ok 1 - fish");
is_valid_string("foo","fish");
test_test("valid string with name");



test_out("ok 1 - valid string test");
is_valid_string("\x{e9} is called e-acute");
test_test("string with latin-1");



test_out("ok 1 - valid string test");
is_valid_string("close the window with \x{2318}-w");
test_test("string with unicode only char");



test_out("ok 1 - valid string test");
my $empty_string = "";
Encode::_utf8_on($empty_string);
is_valid_string($empty_string);
test_test("empty string is valid string");



# create an invalid string
my $invalid = "this is an invalid char '\x{e9}' here";
Encode::_utf8_on($invalid);

test_out("not ok 1 - valid string test");
test_fail(+2);
test_diag("malformed byte sequence starting at byte 25");
is_valid_string($invalid);
test_test("invalid string test");



$invalid = "\x{e9}";
Encode::_utf8_on($invalid);

test_out("not ok 1 - valid string test");
test_fail(+2);
test_diag("malformed byte sequence starting at byte 0");
is_valid_string($invalid);
test_test("invalid string test starting with bad char");

