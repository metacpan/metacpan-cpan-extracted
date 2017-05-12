#!/usr/bin/env perl
# Test schemas unqualified schemas without target-namespace

use warnings;
use strict;

use lib 'lib','t';
use TestTools;

use XML::Compile::Schema;
use XML::Compile::Tester;

use Test::More tests => 27;

set_compile_defaults
    elements_qualified => 'NONE';

# elementFormDefault just to add confusion.

my $schema   = XML::Compile::Schema->new( <<__SCHEMA);
<xs:schema xmlns:xs="$SchemaNS"
  elementFormDefault="unqualified"
  attributeFormDefault="unqualified">

<xs:element name="test1" type="xs:int" />

<xs:complexType name="ct1">
  <xs:sequence>
    <xs:element name="c1_a" type="xs:int" />
  </xs:sequence>
  <xs:attribute name="a1_a" type="xs:int" />
</xs:complexType>

<xs:element name="test2" type="ct1" />

<xs:element name="test4">
  <xs:complexType>
    <xs:complexContent>
      <xs:extension base="ct1">
        <xs:sequence>
          <xs:element name="c4_a" type="xs:int" />
        </xs:sequence>
        <xs:attribute name="a4_a" type="xs:int" />
      </xs:extension>
    </xs:complexContent>
  </xs:complexType>
</xs:element>

</xs:schema>
__SCHEMA

ok(defined $schema);

is(join("\n", join "\n", $schema->types)."\n", "ct1\n");

is(join("\n", join "\n", $schema->elements)."\n", <<__ELEMS__);
test1
test2
test4
__ELEMS__

test_rw($schema, "{}test1" => <<__XML, 10);
<test1>10</test1>
__XML

test_rw($schema, "{}test2" => <<__XML, {c1_a => 11});
<test2><c1_a>11</c1_a></test2>
__XML

my %t4 = (c1_a => 14, a1_a => 15, c4_a => 16, a4_a => 17);
test_rw($schema, "{}test4" => <<__XML, \%t4);
<test4 a1_a="15" a4_a="17">
   <c1_a>14</c1_a>
   <c4_a>16</c4_a>
</test4>
__XML
