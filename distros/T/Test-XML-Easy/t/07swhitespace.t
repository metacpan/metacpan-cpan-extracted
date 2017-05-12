#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 19;
use Test::Builder::Tester;
use Test::XML::Easy;

########################################################################
# leading whitespace with required option

test_out("not ok 1 - xml test");
test_fail(+6);
test_diag(q{text inside '/foo[1]' didn't match});
test_diag(q{found:});
test_diag(q{  '  zippy'});
test_diag(q{expected:});
test_diag(q{  'zippy'});
is_xml(<<'ENDOFXML',<<'ENDOFXML2',{ignore_leading_whitespace=>0});
<foo>  zippy</foo>
ENDOFXML
<foo>zippy</foo>
ENDOFXML2
test_test("failing leading whitespace");

test_out("ok 1 - xml test");
is_xml(<<'ENDOFXML',<<'ENDOFXML2',{ignore_leading_whitespace=>1});
<foo>  zippy</foo>
ENDOFXML
<foo>zippy</foo>
ENDOFXML2
test_test("passing leading whitespace");


test_out("not ok 1 - xml test");
test_fail(+7);
test_diag(q{text inside '/foo[1]' didn't match});
test_diag(q{found:});
test_diag(q{  '});
test_diag(q{  zippy'});
test_diag(q{expected:});
test_diag(q{  'zippy'});
is_xml(<<'ENDOFXML',<<'ENDOFXML2',{ignore_leading_whitespace=>0});
<foo>
  zippy</foo>
ENDOFXML
<foo>zippy</foo>
ENDOFXML2
test_test("failing leading whitespace return");

test_out("ok 1 - xml test");
is_xml(<<'ENDOFXML',<<'ENDOFXML2',{ignore_leading_whitespace=>1});
<foo>  
zippy</foo>
ENDOFXML
<foo>zippy</foo>
ENDOFXML2
test_test("passing leading whitespace return");

test_out("ok 1 - xml test");
is_xml(<<'ENDOFXML',<<'ENDOFXML2',{ignore_leading_whitespace=>1});
<foo>  zippy  </foo>
ENDOFXML
<foo>zippy  </foo>
ENDOFXML2
test_test("passing leading whitespace both ends");


########################################################################
# leading whitespace with ignore_whitespace option

test_out("not ok 1 - xml test");
test_fail(+6);
test_diag(q{text inside '/foo[1]' didn't match});
test_diag(q{found:});
test_diag(q{  '  zippy'});
test_diag(q{expected:});
test_diag(q{  'zippy'});
is_xml(<<'ENDOFXML',<<'ENDOFXML2',{ignore_whitespace=>0});
<foo>  zippy</foo>
ENDOFXML
<foo>zippy</foo>
ENDOFXML2
test_test("failing leading whitespace");

test_out("ok 1 - xml test");
is_xml(<<'ENDOFXML',<<'ENDOFXML2',{ignore_whitespace=>1});
<foo>  zippy</foo>
ENDOFXML
<foo>zippy</foo>
ENDOFXML2
test_test("passing leading whitespace");


test_out("not ok 1 - xml test");
test_fail(+7);
test_diag(q{text inside '/foo[1]' didn't match});
test_diag(q{found:});
test_diag(q{  '});
test_diag(q{  zippy'});
test_diag(q{expected:});
test_diag(q{  'zippy'});
is_xml(<<'ENDOFXML',<<'ENDOFXML2',{ignore_whitespace=>0});
<foo>
  zippy</foo>
ENDOFXML
<foo>zippy</foo>
ENDOFXML2
test_test("failing leading whitespace return");

test_out("ok 1 - xml test");
is_xml(<<'ENDOFXML',<<'ENDOFXML2',{ignore_whitespace=>1});
<foo>  
zippy</foo>
ENDOFXML
<foo>zippy</foo>
ENDOFXML2
test_test("passing leading whitespace return");

test_out("ok 1 - xml test");
is_xml(<<'ENDOFXML',<<'ENDOFXML2',{ignore_whitespace=>1});
<foo>  zippy</foo>
ENDOFXML
<foo>zippy</foo>
ENDOFXML2
test_test("passing leading whitespace");


########################################################################
# trailing whitespace with required option

test_out("not ok 1 - xml test");
test_fail(+6);
test_diag(q{text inside '/foo[1]' didn't match});
test_diag(q{found:});
test_diag(q{  'zippy  '});
test_diag(q{expected:});
test_diag(q{  'zippy'});
is_xml(<<'ENDOFXML',<<'ENDOFXML2',{ignore_trailing_whitespace=>0});
<foo>zippy  </foo>
ENDOFXML
<foo>zippy</foo>
ENDOFXML2
test_test("failing trailing whitespace");

test_out("ok 1 - xml test");
is_xml(<<'ENDOFXML',<<'ENDOFXML2',{ignore_trailing_whitespace=>1});
<foo>zippy  </foo>
ENDOFXML
<foo>zippy</foo>
ENDOFXML2
test_test("passing trailing whitespace");


test_out("not ok 1 - xml test");
test_fail(+7);
test_diag(q{text inside '/foo[1]' didn't match});
test_diag(q{found:});
test_diag(q{  'zippy});
test_diag(q{  '});
test_diag(q{expected:});
test_diag(q{  'zippy'});
is_xml(<<'ENDOFXML',<<'ENDOFXML2',{ignore_trailing_whitespace=>0});
<foo>zippy
  </foo>
ENDOFXML
<foo>zippy</foo>
ENDOFXML2
test_test("failing trailing whitespace return");

test_out("ok 1 - xml test");
is_xml(<<'ENDOFXML',<<'ENDOFXML2',{ignore_trailing_whitespace=>1});
<foo>zippy
  </foo>
ENDOFXML
<foo>zippy</foo>
ENDOFXML2
test_test("passing trailing whitespace return");

test_out("ok 1 - xml test");
is_xml(<<'ENDOFXML',<<'ENDOFXML2',{ignore_trailing_whitespace=>1});
<foo>  zippy  </foo>
ENDOFXML
<foo>  zippy</foo>
ENDOFXML2
test_test("passing trailing whitespace but not starting");

########################################################################
# trailing whitespace with ignore_whitespace option

test_out("not ok 1 - xml test");
test_fail(+6);
test_diag(q{text inside '/foo[1]' didn't match});
test_diag(q{found:});
test_diag(q{  'zippy  '});
test_diag(q{expected:});
test_diag(q{  'zippy'});
is_xml(<<'ENDOFXML',<<'ENDOFXML2',{ignore_whitespace=>0});
<foo>zippy  </foo>
ENDOFXML
<foo>zippy</foo>
ENDOFXML2
test_test("failing trailing whitespace");

test_out("ok 1 - xml test");
is_xml(<<'ENDOFXML',<<'ENDOFXML2',{ignore_whitespace=>1});
<foo>zippy  </foo>
ENDOFXML
<foo>zippy</foo>
ENDOFXML2
test_test("passing trailing whitespace");


test_out("not ok 1 - xml test");
test_fail(+7);
test_diag(q{text inside '/foo[1]' didn't match});
test_diag(q{found:});
test_diag(q{  'zippy});
test_diag(q{  '});
test_diag(q{expected:});
test_diag(q{  'zippy'});
is_xml(<<'ENDOFXML',<<'ENDOFXML2',{ignore_whitespace=>0});
<foo>zippy
  </foo>
ENDOFXML
<foo>zippy</foo>
ENDOFXML2
test_test("failing trailing whitespace return");

test_out("ok 1 - xml test");
is_xml(<<'ENDOFXML',<<'ENDOFXML2',{ignore_whitespace=>1});
<foo>zippy
  </foo>
ENDOFXML
<foo>zippy</foo>
ENDOFXML2
test_test("passing trailing whitespace return");
