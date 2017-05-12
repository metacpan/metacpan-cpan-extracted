#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;
use Test::Builder::Tester;
use Test::utf8;

test_out("ok 1 - within latin-1");
is_within_latin1("foo");
test_test("within latin1");

test_out("ok 1 - within latin-1");
is_within_latin1("foo\x{e9}");
test_test("within latin1");

test_out("ok 1 - bar");
is_within_latin1("foo","bar");
test_test("within latin1 name");

test_out("not ok 1 - within latin-1");
test_fail(+2);
test_diag("Char 4 not Latin-1 (it's 3737 dec / e99 hex)");
is_within_latin_1("foo\x{e99} foo");
test_test("within latin1 failure");