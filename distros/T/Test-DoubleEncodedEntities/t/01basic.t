#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;
use Test::Builder::Tester;
use Test::DoubleEncodedEntities;

test_out("ok 1 - foo");
ok_dee('<html><body>&eacute; fish</body></html>', "foo");
test_test("normal");

test_out("ok 1 - foo");
ok_dee('<html><body><a href="&amp;eacute;">foo</a></body></html>', "foo");
test_test("attr");

test_out("not ok 1 - foo");
test_fail(+2);
test_diag(qq{Found 1 "&amp;eacute;"});
ok_dee('<html><body>&amp;eacute; fish</body></html>', "foo");
test_test("1 ent");

test_out("not ok 1 - foo");
test_fail(+3);
test_diag(qq{Found 2 "&amp;Eacute;"});
test_diag(qq{Found 1 "&amp;eacute;"});
ok_dee('<html><body>fish &amp;Eacute;
&amp;Eacute;&amp;eacute;</body></html>', "foo");
test_test("many ent");

test_out("not ok 1 - foo");
test_fail(+2);
test_diag(qq{Found 1 "&amp;#233;"});
ok_dee('<html><body>&amp;#233;</body></html>', "foo");
test_test("numerical");

test_out("not ok 1 - foo");
test_fail(+2);
test_diag(qq{Found 1 "&#38;#233;"});
ok_dee('<html><body>&#38;#233;</body></html>', "foo");
test_test("double numerical");

test_out("not ok 1 - foo");
test_fail(+2);
test_diag(qq{Found 1 "&#038;#233;"});
ok_dee('<html><body>&#038;#233;</body></html>', "foo");
test_test("double numerical with extra zero");

test_out("not ok 1 - foo");
test_fail(+2);
test_diag(qq{Found 1 "&#0000038;#233;"});
ok_dee('<html><body>&#0000038;#233;</body></html>', "foo");
test_test("double numerical with many extra zeroes");
