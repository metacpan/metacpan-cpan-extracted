#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 5;
use Test::Builder::Tester;
use Test::utf8;
use Encode;

my $mark = "Mark";
my $leon = "L\x{e9}on";

test_out("ok 1 - valid string test");
is_valid_string($mark);  # passes, not utf-8
test_test("ascii");

test_out("ok 1 - valid string test");
is_valid_string($leon);  # passes, not utf-8
test_test("latin1");

my $iloveny = "I \x{2665} NY";

test_out("ok 1 - valid string test");
is_valid_string($iloveny);      # passes, proper utf-8
test_test("valid utf-8");

my $acme = "L\x{c3}\x{a9}on";
Encode::_utf8_on($acme);      # (please don't do things like this)

test_out("ok 1 - valid string test");
is_valid_string($acme);       # passes, proper utf-8
test_test("valid _utf8_on shenanigans");

Encode::_utf8_on($leon);      # (this is why you don't do things like this)
test_out("not ok 1 - valid string test");
test_fail(+2);
test_diag("malformed byte sequence starting at byte 1");
is_valid_string($leon);       # fails! the byte \x{e9} isn't valid utf-8
test_test("invalid _utf8_on shenanigans");
