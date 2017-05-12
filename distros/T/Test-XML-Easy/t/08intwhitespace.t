#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;
use Test::Builder::Tester;
use Test::XML::Easy;

test_out("not ok 1 - xml test");
test_fail(+8);
test_diag(q{text inside '/foo[1]' didn't match});
test_diag(q{found:});
test_diag(q{  'bungle });
test_diag(q{womble      zoot   nurple'});
test_diag(q{expected:});
test_diag(q{  'bungle           womble});
test_diag(q{zoot nurple'});
is_xml(<<'ENDOFXML',<<'ENDOFXML2',{ignore_different_whitespace=>0});
<foo>bungle 
womble      zoot   nurple</foo>
ENDOFXML
<foo>bungle           womble
zoot nurple</foo>
ENDOFXML2
test_test("failing internal whitespace");

test_out("ok 1 - xml test");
is_xml(<<'ENDOFXML',<<'ENDOFXML2',{ignore_different_whitespace=>1});
<foo>bungle 
womble      zoot   nurple</foo>
ENDOFXML
<foo>bungle           womble
zoot nurple</foo>
ENDOFXML2
test_test("passing internal whitespace ignore_different_whitespace");

test_out("ok 1 - xml test");
is_xml(<<'ENDOFXML',<<'ENDOFXML2',{ignore_whitespace=>1});
<foo>bungle 
womble      zoot   nurple</foo>
ENDOFXML
<foo>bungle           womble
zoot nurple</foo>
ENDOFXML2
test_test("passing internal whitespace ignore_whitespace");


test_out("ok 1 - xml test");
is_xml(<<'ENDOFXML',<<'ENDOFXML2',{ignore_whitespace=>1});
<foo>bungle 
womble      zoot   nurple</foo>
ENDOFXML
<foo>
bungle           womble
zoot nurple   </foo>
ENDOFXML2
test_test("passing internal whitespace ignore_whitespace with surround");
