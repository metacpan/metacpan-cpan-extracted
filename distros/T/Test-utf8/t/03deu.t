#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::Builder::Tester;
use Test::utf8;
use Encode;


test_out("ok 1 - sane utf8");
is_dodgy_utf8("foo");
test_test("basic latin1 test");




test_out("ok 1 - name here");
is_dodgy_utf8("foo", "name here");
test_test("basic latin1 test with name");




test_out("ok 1 - sane utf8");
is_dodgy_utf8("\x{2318}-w closes the window");
test_test("utf8 correctly encoded");




my $invalid = "E = mc\x{c2}\x{b2} is a nice formula";

test_out("not ok 1 - sane utf8");
test_fail(+4);
test_diag(qq{Found dodgy chars "<c2><b2>" at char 6});
test_diag("String not flagged as utf8...was it meant to be?");
test_diag("Probably originally a SUPERSCRIPT TWO char - codepoint 178 (dec), b2 (hex)");
is_dodgy_utf8($invalid);
test_test("utf8 not flagged");




my $invalid2 = "E = mc\x{c3}\x{82}\x{c2}\x{b2} is a nice formula";
Encode::_utf8_on($invalid2);

test_out("not ok 1 - sane utf8");
test_fail(+4);
test_diag(qq{Found dodgy chars "<c2><b2>" at char 6});
test_diag("Chars in utf8 string look like utf8 byte sequence.");
test_diag("Probably originally a SUPERSCRIPT TWO char - codepoint 178 (dec), b2 (hex)");
is_dodgy_utf8($invalid2);
test_test("utf8 truely double encoded");




test_out("ok 1 - sane utf8");
is_sane_utf8("foo");
test_test("with new name");
