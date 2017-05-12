#!/usr/bin/env perl

use warnings;
use strict;

use lib 'lib','t';
use TestTools;

use XML::Compile::Schema;
use XML::Compile::Tester;

use Test::More tests => 95;

set_compile_defaults
    elements_qualified => 'NONE';

my $schema   = XML::Compile::Schema->new( <<__SCHEMA__ );
<schema targetNamespace="$TestNS"
        xmlns="$SchemaNS"
        xmlns:me="$TestNS">

<element name="test1" type="me:t1" />
<complexType name="t1">
  <sequence>
    <element name="t1_a" type="int" />
    <element name="t1_b" type="int" />
  </sequence>
  <attribute name="a1_a" type="int" />
  <attribute name="a1_b" type="int" use="required" />
</complexType>

<element name="test2" type="me:t2" />
<complexType name="t2">
  <sequence>
    <element name="t2_a" type="int" minOccurs="0" />
    <element name="t2_b" type="int" />
  </sequence>
  <attribute name="a2_a" type="int" />
  <attributeGroup ref="me:a2" />
  <attribute name="a2_b" type="int" />
</complexType>

<attributeGroup name="a2">
  <attribute name="a2_c" type="int" use="required" />
  <attribute name="a2_d" type="int" use="optional" />
  <attribute name="a2_e" type="int" use="prohibited" />
</attributeGroup>

<element name="test3">
  <complexType>
    <attribute name="a3">
      <simpleType>
         <restriction base="int" />
      </simpleType>
    </attribute>
  </complexType>
</element>

<attribute name="a4" type="int" />
<element name="test4">
  <complexType>
    <attribute ref="me:a4"/>
  </complexType>
</element>

<attribute name="a5">
  <simpleType>
    <restriction base="token">
      <enumeration value="only-one"/>
    </restriction>
  </simpleType>
</attribute>
<element name="test5">
  <complexType>
    <attribute ref="me:a5"/>
  </complexType>
</element>

</schema>
__SCHEMA__

ok(defined $schema);

## test 1

my %t1 = (t1_a => 10, t1_b => 9, a1_a => 11, a1_b => 12);
test_rw($schema, test1 => <<__XML, \%t1);
<test1 a1_a="11" a1_b="12">
  <t1_a>10</t1_a>
  <t1_b>9</t1_b>
</test1>
__XML

my %t1_b = (t1_a => 20, t1_b => 21, a1_b => 23);
test_rw($schema, test1 => <<__XML, \%t1_b);
<test1 a1_b="23">
  <t1_a>20</t1_a>
  <t1_b>21</t1_b>
</test1>
__XML

my $error = error_r($schema, test1 => <<__XML);
<test1>
  <t1_a>25</t1_a>
  <t1_b>26</t1_b>
</test1>
__XML
is($error, "attribute `a1_b' is required at {http://test-types}test1/\@a1_b");

my %t1_c = (a1_b => 24, t1_a => 25);
$error = error_w($schema, test1 => \%t1_c);
is($error, "required value for element `t1_b' missing at {http://test-types}test1");

## test 2  attributeGroup

my %t2_a = (a2_a => 30, a2_b => 31, a2_c => 29, t2_b => 100);
test_rw($schema, test2 => <<__XML, \%t2_a);
<test2 a2_a="30" a2_c="29" a2_b="31">
  <t2_b>100</t2_b>
</test2>
__XML

my %t2_b = (a2_a => 32, a2_b => 33, a2_c => 34, a2_d => 35
  , t2_a => 99, t2_b => 101);
test_rw($schema, test2 => <<__XML, \%t2_b);
<test2 a2_a="32" a2_c="34" a2_d="35" a2_b="33">
  <t2_a>99</t2_a><t2_b>101</t2_b>
</test2>
__XML

$error = error_r($schema, test2 => <<__XML);
<test2 a2_c="29" a2_e="666"><t2_b>102</t2_b></test2>
__XML

is($error, "attribute `a2_e' is prohibited at {http://test-types}test2/\@a2_e");

$error = error_w($schema, test2
  => {a2_c => 29, a2_e => 666, t2_b => 77} );
is($error, "attribute `a2_e' is prohibited at {http://test-types}test2/\@a2_e");

test_rw($schema, test3 => '<test3 a3="41"/>', { a3 => 41 });

### toplevel attributes

# test 4

test_rw($schema, test4 => '<test4 a4="42"/>', { a4 => 42 });

test_rw($schema, a4 => XML::LibXML::Attr->new('a4', 43), 43, ' a4="43"');

# test 5

test_rw($schema, test5 => '<test5 a5="only-one"/>', { a5 => 'only-one' });

$error = error_r($schema, test5 => '<test5 a5="not-two"/>');
is($error, "invalid enumerate `not-two' at {http://test-types}test5#facet");

test_rw($schema, a5 => XML::LibXML::Attr->new(a5 => 'only-one')
  , 'only-one', ' a5="only-one"');
