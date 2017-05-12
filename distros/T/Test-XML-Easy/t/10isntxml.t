#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;
use Test::Builder::Tester;
use Test::XML::Easy;

########################################################################
# isn't obviously

test_out("ok 1 - not xml test");
isnt_xml("Not XML", "<foo/>");
test_test("not xml");

test_out("ok 1 - not xml test");
isnt_xml(undef, "<foo/>");
test_test("undef xml");

test_out("ok 1 - not xml test");
isnt_xml("<bar/>", "<foo/>");
test_test("different xml");

########################################################################
# failure

test_out("not ok 1 - not xml test");
test_fail(+2);
test_diag("Unexpectedly matched the XML we didn't expect");
isnt_xml("<foo/>", "<foo/>");
test_test("same xml");

########################################################################
# invalid input

eval {
  isnt_xml("<foo/>","Not XML");
};
ok($@, "threw exception with invalid input 1");

eval {
  isnt_xml("<foo/>",undef);
};
ok($@, "threw exception with invalid input 2");

########################################################################
# names

test_out("ok 1 - womble");
isnt_xml("Not XML", "<foo/>","womble");
test_test("name ''");

test_out("ok 1 - womble");
isnt_xml("Not XML", "<foo/>", {description=>"womble"});
test_test("name {}");