#!/usr/bin/env perl

use warnings;
use strict;

use lib 'lib','t';
use TestTools;

use XML::Compile::Schema;
use XML::Compile::Tester;

use Test::More tests => 52;

my $NS2 = "http://test2/ns";

# <wsdl> as wrapper to group two schema's, is ignored.

my $schema   = XML::Compile::Schema->new( <<__SCHEMA__ );
<wsdl>
<xs:schema
   targetNamespace="$TestNS"
   xmlns:xs="$SchemaNS"
   xmlns:me="$TestNS">

<xs:element name="test1" type="xs:int" />

<xs:complexType name="ct1">
  <xs:sequence>
    <xs:element name="c1_a" type="xs:int" />
  </xs:sequence>
  <xs:attribute name="a1_a" type="xs:int" />
</xs:complexType>

<xs:element name="test2" type="me:ct1" />

<xs:element name="test5" type="me:ct5" abstract="true" />
<xs:complexType name="ct5">
  <xs:sequence>
    <xs:element name="e5a" type="xs:int" />
  </xs:sequence>
</xs:complexType>

</xs:schema>

<schema
   targetNamespace="$NS2"
   xmlns="$SchemaNS"
   xmlns:me="$NS2"
   xmlns:that="$TestNS">

<element name="test3" type="that:ct1" />

<element name="test4">
  <complexType>
    <complexContent>
      <extension base="that:ct1">
        <sequence>
          <element name="c4_a" type="int" />
        </sequence>
        <attribute name="a4_a" type="int" />
      </extension>
    </complexContent>
  </complexType>
</element>

<element name="test6" type="me:ct6" substitutionGroup="that:test5" />
<complexType name="ct6">
  <complexContent>
    <extension base="that:ct5">
      <sequence>
        <element name="e6a" type="string" />
      </sequence>
    </extension>
  </complexContent>
</complexType>

</schema>

</wsdl>
__SCHEMA__

ok(defined $schema);

is(join("\n", join "\n", $schema->types)."\n", <<__TYPES__);
{http://test-types}ct1
{http://test-types}ct5
{http://test2/ns}ct6
__TYPES__

is(join("\n", join "\n", $schema->elements)."\n", <<__ELEMS__);
{http://test-types}test1
{http://test-types}test2
{http://test-types}test5
{http://test2/ns}test3
{http://test2/ns}test4
{http://test2/ns}test6
__ELEMS__

set_compile_defaults
    elements_qualified    => 'ALL'
  , attributes_qualified  => 1
  , include_namespaces    => 1
  , use_default_namespace => 0
  , prefixes => [b => $NS2];

#
# simple name-space on schema
#

ok(1, "** Testing simple namespace");

test_rw($schema, test1 => <<_XML, 10);
<x0:test1 xmlns:x0="http://test-types">10</x0:test1>
_XML

test_rw($schema, "test2" => <<_XML, {c1_a => 11});
<x0:test2 xmlns:x0="http://test-types"><x0:c1_a>11</x0:c1_a></x0:test2>
_XML

test_rw($schema, "{$NS2}test3" => <<_XML, {c1_a => 12, a1_a => 13});
<b:test3 xmlns:b="http://test2/ns" xmlns:that="http://test-types"
   that:a1_a="13">
  <that:c1_a>12</that:c1_a>
</b:test3>
_XML

my %t4 = (c1_a => 14, a1_a => 15, c4_a => 16, a4_a => 17);
test_rw($schema, "{$NS2}test4" => <<_XML, \%t4);
<b:test4 xmlns:b="$NS2" xmlns:that="$TestNS"
   that:a1_a="15" b:a4_a="17">
  <that:c1_a>14</that:c1_a>
  <b:c4_a>16</b:c4_a>
</b:test4>
_XML

# now with name-spaces off

set_compile_defaults
    ignore_namespaces  => 1
  , elements_qualified => 'NONE';

test_rw($schema, "{$NS2}test3" => <<_XML, {c1_a => 18});
<test3>
  <c1_a>18</c1_a>
</test3>
_XML

#
# Test 5/6
#

set_compile_defaults
   elements_qualified => 'ALL'
 , ignore_namespaces  => 0
 , include_namespaces => 1;

my %h6 = (e5a => 42, e6a => 'aap');
test_rw($schema, "{$NS2}test6" => <<_XML, \%h6);
<test6 xmlns="$NS2" xmlns:that="$TestNS">
  <that:e5a>42</that:e5a>
  <e6a>aap</e6a>
</test6>
_XML

#
# Test 7
# element in "wrong" namespace.
#

# <element name="test7" type="int" targetNamespace="$TestNS" />
#test_rw($schema, "{$TestNS}test7" => <<_XML, 43);
#<test7 xmlns="$TestNS">43</test7>
#_XML
