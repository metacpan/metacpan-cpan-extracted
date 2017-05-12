#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 9;
use Test::Builder::Tester;
use Test::utf8;

test_out("ok 1 - flagged as utf8");
is_flagged_utf8("\x{300}");
test_test("is flagged pass");

test_out("ok 1 - foo");
is_flagged_utf8("\x{300}","foo");
test_test("is flagged pass with name");

test_out("not ok 1 - flagged as utf8");
test_fail(+1);
is_flagged_utf8("\x{e9}");
test_test("is flagged fail");

#################

test_out("ok 1 - not flagged as utf8");
isnt_flagged_utf8("fred");
test_test("isnt flagged pass");

test_out("ok 1 - foo");
isnt_flagged_utf8("fred","foo");
test_test("isnt flagged pass with name");

test_out("not ok 1 - not flagged as utf8");
test_fail(+1);
isnt_flagged_utf8("\x{400}");
test_test("isnt flagged fail");

######################

test_out("ok 1 - not flagged as utf8");
isn't_flagged_utf8("fred");
test_test("isn't flagged pass");

test_out("ok 1 - foo");
isn't_flagged_utf8("fred","foo");
test_test("isn't flagged pass with name");

test_out("not ok 1 - not flagged as utf8");
test_fail(+1);
isn't_flagged_utf8("\x{400}");
test_test("isn't flagged fail");
