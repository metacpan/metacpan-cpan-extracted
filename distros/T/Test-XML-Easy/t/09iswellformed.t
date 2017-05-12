#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;
use Test::Builder::Tester;
use Test::XML::Easy;

########################################################################
# well formed

test_out("ok 1 - xml well formed test");
is_well_formed_xml(<<'ENDOFXML',);
<foo/>
ENDOFXML
test_test("well formed as expected");

test_out("not ok 1 - xml well formed test");
test_fail(+2);
test_err("/.*?/");
is_well_formed_xml(<<'ENDOFXML');
This isn't XML'
ENDOFXML
test_test("not well formed, but expected it to be");

########################################################################
# not well formed

test_out("ok 1 - xml not well formed test");
isnt_well_formed_xml(<<'ENDOFXML');
This isn't XML'
ENDOFXML
test_test("not well formed as expected");

test_out("not ok 1 - xml not well formed test");
test_fail(+2);
test_diag("Unexpectedly well formed XML");
isnt_well_formed_xml(<<'ENDOFXML');
<foo/>
ENDOFXML
test_test("well formed, but expected it not to be");

########################################################################
# description test

test_out("ok 1 - womble");
is_well_formed_xml(<<'ENDOFXML', "womble");
<foo/>
ENDOFXML
test_test("well formed desc ''");

test_out("ok 1 - womble");
is_well_formed_xml(<<'ENDOFXML', { description => "womble" });
<foo/>
ENDOFXML
test_test("well formed desc {}");

test_out("ok 1 - womble");
isnt_well_formed_xml(<<'ENDOFXML', "womble");
This isn't XML'
ENDOFXML
test_test("not well formed desc ''");

test_out("ok 1 - womble");
isnt_well_formed_xml(<<'ENDOFXML', { description => "womble" });
This isn't XML'
ENDOFXML
test_test("not well formed desc {}");