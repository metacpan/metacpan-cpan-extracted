#!/usr/bin/env perl
# Test schemas unqualified schemas with target-namespace

use warnings;
use strict;

use lib 'lib','t';
use TestTools;

use XML::Compile::Schema;
use XML::Compile::Tester;

use Test::More tests => 27;

set_compile_defaults
    include_namespaces => 1
  , prefixes           => [ me => $TestNS ];

# targetNamespace and elementFormDefault just to add confusion.

my $s = <<__SCHEMA;
<xs:schema xmlns:xs="$SchemaNS"
  xmlns:me="$TestNS"
  targetNamespace="http://will-be-overruled"
  elementFormDefault="unqualified"
  attributeFormDefault="unqualified">

<xs:element name="test1" type="xs:int" />

<xs:complexType name="ct1">
  <xs:sequence>
    <xs:element name="c1_a" type="xs:int" />
  </xs:sequence>
  <xs:attribute name="a1_a" type="xs:int" />
</xs:complexType>

<xs:element name="test2" type="me:ct1" />

<xs:element name="test4">
  <xs:complexType>
    <xs:complexContent>
      <xs:extension base="me:ct1">
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

my $schema   = XML::Compile::Schema->new($s
 , target_namespace     => $TestNS
 , element_form_default => 'qualified'
 );
# $schema->printIndex;

ok(defined $schema, 'compiled schema');

is(join("\n", join "\n", $schema->types)."\n", "{$TestNS}ct1\n");

is(join("\n", join "\n", $schema->elements)."\n", <<__ELEMS__);
{$TestNS}test1
{$TestNS}test2
{$TestNS}test4
__ELEMS__

test_rw($schema, test1 => <<__XML, 10);
<me:test1 xmlns:me="$TestNS">10</me:test1>
__XML

test_rw($schema, test2 => <<__XML, {c1_a => 11});
<me:test2 xmlns:me="$TestNS"><me:c1_a>11</me:c1_a></me:test2>
__XML

my %t4 = (c1_a => 14, a1_a => 15, c4_a => 16, a4_a => 17);
test_rw($schema, test4 => <<__XML, \%t4);
<me:test4 xmlns:me="$TestNS" a1_a="15" a4_a="17">
   <me:c1_a>14</me:c1_a>
   <me:c4_a>16</me:c4_a>
</me:test4>
__XML
