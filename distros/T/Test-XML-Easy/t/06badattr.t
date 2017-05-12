#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;
use Test::Builder::Tester;
use Test::XML::Easy;

test_out("not ok 1 - xml test");
test_fail(+2);
test_diag(q{expected attribute '/foo[1]/bar[2]/@answer' not found});
is_xml(<<'ENDOFXML',<<'ENDOFXML2',);#{verbose=>1});
<foo><bar/><bar /></foo>
ENDOFXML
<foo><bar/><bar answer="42"/></foo>
ENDOFXML2
test_test("missing attribute");


test_out("not ok 1 - xml test");
test_fail(+3);
test_diag(q{found extra unexpected attribute:});
test_diag(q{  '/foo[1]/bar[2]/@answer'});
is_xml(<<'ENDOFXML',<<'ENDOFXML2',);#{verbose=>1});
<foo><bar/><bar answer="42"/></foo>
ENDOFXML
<foo><bar/><bar /></foo>
ENDOFXML2
test_test("unexpected attribute");


test_out("not ok 1 - xml test");
test_fail(+4);
test_diag(q{found extra unexpected attributes:});
test_diag(q{  '/foo[1]/bar[2]/@answer'});
test_diag(q{  '/foo[1]/bar[2]/@zingle'});
is_xml(<<'ENDOFXML',<<'ENDOFXML2',);#{verbose=>1});
<foo><bar/><bar zingle="zoop" answer="42"/></foo>
ENDOFXML
<foo><bar/><bar /></foo>
ENDOFXML2
test_test("unexpected attributes");


test_out("not ok 1 - xml test");
test_fail(+6);
test_diag(q{attribute value for '/foo[1]/bar[2]/@answer' didn't match});
test_diag("found value:");
test_diag("  'got'");
test_diag("expected value:");
test_diag("  'expected'");
is_xml(<<'ENDOFXML',<<'ENDOFXML2',);#{verbose=>1});
<foo><bar/><bar answer="got"/></foo>
ENDOFXML
<foo><bar/><bar answer="expected"/></foo>
ENDOFXML2
test_test("wrong attribute");
