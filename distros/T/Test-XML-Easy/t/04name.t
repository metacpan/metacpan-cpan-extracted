#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;
use Test::Builder::Tester;
use Test::XML::Easy;

test_out("ok 1 - xml test");
is_xml("<foo/>","<foo/>");
test_test("default description is there");

test_out("ok 1 - xml test");
is_xml("<foo/>","<foo/>",{});
test_test("default description is there {}");

test_out("ok 1 - womble");
is_xml("<foo/>","<foo/>","womble");
test_test("manual description is there");

test_out("ok 1 - turnip");
is_xml("<foo/>","<foo/>",{description=>"turnip"});
test_test("manual description is there {}");

