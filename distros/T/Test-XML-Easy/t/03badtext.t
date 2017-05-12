#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 9;
use Test::Builder::Tester;
use Test::XML::Easy;

test_out("not ok 1 - xml test");
test_fail(+6);
test_diag("text inside '/flintstones[1]/fred[1]' didn't match");
test_diag("found:");
test_diag("  'betty'");
test_diag("expected:");
test_diag("  'wilma'");
is_xml(<<'ENDOFXML',<<'ENDOFXML2',{ignore_leading_whitespace=>0});
<flintstones><fred>betty</fred><barney>wilma</barney></flintstones>
ENDOFXML
<flintstones><fred>wilma</fred><barney>betty</barney></flintstones>
ENDOFXML2
test_test("text doesn't match inside");

test_out("not ok 1 - xml test");
test_fail(+6);
test_diag("text immediately inside opening tag of '/flintstones[1]/fred[1]' didn't match");
test_diag("found:");
test_diag("  'betty'");
test_diag("expected:");
test_diag("  'wilma'");
is_xml(<<'ENDOFXML',<<'ENDOFXML2',{ignore_leading_whitespace=>0});
<flintstones><fred>betty</fred><barney>wilma</barney></flintstones>
ENDOFXML
<flintstones><fred>wilma<zingle/></fred><barney>betty</barney></flintstones>
ENDOFXML2
test_test("text doesn't match inside, but different 1");

test_out("not ok 1 - xml test");
test_fail(+6);
test_diag("text immediately inside opening tag of '/flintstones[1]/fred[1]' didn't match");
test_diag("found:");
test_diag("  'betty'");
test_diag("expected:");
test_diag("  'wilma'");
is_xml(<<'ENDOFXML',<<'ENDOFXML2',{ignore_leading_whitespace=>0});
<flintstones><fred>betty<zingle/></fred><barney>wilma</barney></flintstones>
ENDOFXML
<flintstones><fred>wilma</fred><barney>betty</barney></flintstones>
ENDOFXML2
test_test("text doesn't match inside, but different 2");

test_out("not ok 1 - xml test");
test_fail(+6);
test_diag("text immediately inside opening tag of '/flintstones[1]' didn't match");
test_diag("found:");
test_diag("  'womble'");
test_diag("expected:");
test_diag("  'wibble'");
is_xml(<<'ENDOFXML',<<'ENDOFXML2',{ignore_leading_whitespace=>0});
<flintstones>womble<fred>wilma</fred><barney>betty</barney></flintstones>
ENDOFXML
<flintstones>wibble<fred>wilma</fred><barney>betty</barney></flintstones>
ENDOFXML2
test_test("text doesn't match start");

test_out("not ok 1 - xml test");
test_fail(+6);
test_diag("text immediately after '/flintstones[1]/fred[1]' didn't match");
test_diag("found:");
test_diag("  'womble'");
test_diag("expected:");
test_diag("  'wibble'");
is_xml(<<'ENDOFXML',<<'ENDOFXML2',{ignore_leading_whitespace=>0});
<flintstones><fred>wilma</fred>womble<barney>betty</barney></flintstones>
ENDOFXML
<flintstones><fred>wilma</fred>wibble<barney>betty</barney></flintstones>
ENDOFXML2
test_test("text doesn't match middle");


test_out("not ok 1 - xml test");
test_fail(+6);
test_diag("text immediately after '/flintstones[1]/fred[2]' didn't match");
test_diag("found:");
test_diag("  'womble'");
test_diag("expected:");
test_diag("  'wibble'");
is_xml(<<'ENDOFXML',<<'ENDOFXML2',{ignore_leading_whitespace=>0});
<flintstones><fred>wilma</fred><fred>pebbles</fred>womble<barney>betty</barney></flintstones>
ENDOFXML
<flintstones><fred>wilma</fred><fred>pebbles</fred>wibble<barney>betty</barney></flintstones>
ENDOFXML2
test_test("text doesn't match middle, double check numbers");

test_out("not ok 1 - xml test");
test_fail(+6);
test_diag("text immediately before closing tag of '/flintstones[1]' didn't match");
test_diag("found:");
test_diag("  'womble'");
test_diag("expected:");
test_diag("  'wibble'");
is_xml(<<'ENDOFXML',<<'ENDOFXML2',{ignore_leading_whitespace=>0});
<flintstones><fred>wilma</fred><fred>pebbles</fred>womble</flintstones>
ENDOFXML
<flintstones><fred>wilma</fred><fred>pebbles</fred>wibble</flintstones>
ENDOFXML2
test_test("text doesn't match end");

test_out("not ok 1 - xml test");
test_fail(+6);
test_diag("text immediately after '/flintstones[1]/fred[2]' didn't match");
test_diag("found:");
test_diag("  'womble'");
test_diag("expected:");
test_diag("  'wibble'");
is_xml(<<'ENDOFXML',<<'ENDOFXML2',{ignore_leading_whitespace=>0});
<flintstones><fred>wilma</fred><fred>pebbles</fred>womble<zingle/></flintstones>
ENDOFXML
<flintstones><fred>wilma</fred><fred>pebbles</fred>wibble</flintstones>
ENDOFXML2
test_test("text doesn't match end, but different 1");


test_out("not ok 1 - xml test");
test_fail(+6);
test_diag("text immediately after '/flintstones[1]/fred[2]' didn't match");
test_diag("found:");
test_diag("  'womble'");
test_diag("expected:");
test_diag("  'wibble'");
is_xml(<<'ENDOFXML',<<'ENDOFXML2',{ignore_leading_whitespace=>0});
<flintstones><fred>wilma</fred><fred>pebbles</fred>womble</flintstones>
ENDOFXML
<flintstones><fred>wilma</fred><fred>pebbles</fred>wibble<zingle/></flintstones>
ENDOFXML2
test_test("text doesn't match end, but different 2");
