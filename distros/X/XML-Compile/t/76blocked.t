#!/usr/bin/env perl
# test blocking of namespaces

use warnings;
use strict;

use lib 'lib','t';
use TestTools;

use XML::Compile::Schema;
use XML::Compile::Tester;
#use Log::Report mode => 'DEBUG';

use Test::More tests => 129;

my $OtherNS = "http://test2/ns";

my $schema   = XML::Compile::Schema->new( <<__SCHEMA__ );
<schema
  targetNamespace="$TestNS"
  elementFormDefault="unqualified"
  xmlns="$SchemaNS"
  xmlns:me="$TestNS"
  xmlns:other="$OtherNS">

<element name="test1" type="other:t1" />
<element name="test2" type="int" />

<attribute name="test3" type="other:t3" />
<attribute name="test4" type="int" />

<element name="test5">
  <simpleType>
    <restriction base="other:t5" />
  </simpleType>
</element>

<element name="test6">
  <complexType>
    <choice>
      <element name="a" type="other:t6" />
      <element name="b" type="int" />
    </choice>
  </complexType>
</element>

<element name="test7">
  <complexType>
    <complexContent>
      <extension base="other:t7">
        <sequence>
          <element name="c" type="int" />
        </sequence>
      </extension>
    </complexContent>
  </complexType>
</element>

<element name="test8">
  <complexType>
    <complexContent>
      <restriction base="other:t8">
        <sequence>
          <element name="d" type="int" />
        </sequence>
      </restriction>
    </complexContent>
  </complexType>
</element>

<element name="test9">
  <complexType>
    <choice>
      <element ref="other:t9" />
      <element ref="me:test1" />
      <element ref="me:test2" />
    </choice>
  </complexType>
</element>

<element name="test10">
  <complexType>
    <sequence>
      <element ref="other:t10" minOccurs="0" />
      <element ref="me:test1"  minOccurs="0" />
      <element ref="me:test2"  minOccurs="0" />
    </sequence>
  </complexType>
</element>

</schema>
__SCHEMA__

ok(defined $schema);

set_compile_defaults
    elements_qualified => 'NONE'
  , block_namespace => $OtherNS;

#
# simple or complex element
#

my $error = error_r($schema, test1 => '<test1>11</test1>');
is($error, "use of `other:t1' blocked at {$TestNS}test1");

$error = error_w($schema, test1 => 11);
is($error, "use of `other:t1' blocked at {$TestNS}test1");

# should still work
test_rw($schema, test2 => '<test2>12</test2>', 12);

#
# simpleType
#

$error = error_r($schema, test3 => XML::LibXML::Attr->new('test3', 13));
is($error, "use of simpleType `other:t3' blocked at {$TestNS}test3/\@test3");

$error = error_w($schema, test3 => 13);
is($error, "use of simpleType `other:t3' blocked at {$TestNS}test3/\@test3");

test_rw($schema, test4 => XML::LibXML::Attr->new(test4 => '14')
       , 14, ' test4="14"');

$error = error_r($schema, test5 => '<test5>15</test5>');
is($error, "use of simpleType `other:t5' blocked at {$TestNS}test5#sres");

$error = error_w($schema, test5 => 15);
is($error, "use of simpleType `other:t5' blocked at {$TestNS}test5#sres");

#
# complexType choice
#

$error = error_r($schema, test6 => '<test6><a>16</a></test6>');
is($error, "use of `other:t6' blocked at {$TestNS}test6/a");

$error = error_w($schema, test6 => { a => 16 });
is($error, "use of `other:t6' blocked at {$TestNS}test6/a");

test_rw($schema, test6 => '<test6><b>16</b></test6>', {b => 16});

#
# complexType extension/restriction
#

test_rw($schema, test7 => '<test7><c>17</c></test7>', {c => 17});

test_rw($schema, test8 => '<test8><d>18</d></test8>', {d => 18});

#
# ref element in choice
#

$error = error_r($schema, test9 => '<test9><t9>90</t9></test9>');
is($error, "no applicable choice for `t9' at {$TestNS}test9");

$error = error_w($schema, test9 => { t9 => 90 });
is($error, "no match for required block `cho_test1' at {$TestNS}test9");

$error = error_r($schema, test9 => '<test9><test1>91</test1></test9>');
is($error, "use of `other:t1' blocked at {$TestNS}test9/me:test1");

$error = error_w($schema, test9 => { test1 => 91 });
is($error, "use of `other:t1' blocked at {$TestNS}test9/me:test1");

test_rw($schema, test9 => '<test9><test2>92</test2></test9>', {test2 => 92});

#
# ref element in sequence
#

$error = error_r($schema, test10 => '<test10><t10>100</t10></test10>');
is($error, "element `t10' not processed for {$TestNS}test10 at /test10/t10");

$error = error_w($schema, test10 => { t10 => 100 });
is($error, "tag `t10' not used at {$TestNS}test10");

$error = error_r($schema, test10 => '<test10><test1>101</test1></test10>');
is($error, "use of `other:t1' blocked at {$TestNS}test10/me:test1");

$error = error_w($schema, test10 => { test1 => 101 });
is($error, "use of `other:t1' blocked at {$TestNS}test10/me:test1");

test_rw($schema, test10 => '<test10><test2>102</test2></test10>', {test2 => 102});
