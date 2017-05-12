#!/usr/bin/env perl
# test complex type simpleContent extensions

use warnings;
use strict;

use lib 'lib','t';
use TestTools;

use XML::Compile::Schema;
use XML::Compile::Tester;

use Test::More tests => 33;

set_compile_defaults
    elements_qualified => 'NONE';

my $schema   = XML::Compile::Schema->new( <<__SCHEMA__ );
<schema targetNamespace="$TestNS"
        xmlns="$SchemaNS"
        xmlns:me="$TestNS">

<simpleType name="t1">
  <restriction base="int" />
</simpleType>

<complexType name="t2">
  <simpleContent>
    <extension base="me:t1">
      <attribute name="a2_a" type="int" />
    </extension>
  </simpleContent>
</complexType>

<element name="test1" type="me:t2" />

<element name="test2">
  <complexType>
    <simpleContent>
      <extension base="int">
        <attribute name="a3_a" type="int" />
      </extension>
    </simpleContent>
  </complexType>
</element>

<element name="test3">
  <complexType>
    <simpleContent>
      <extension base="me:t2">
        <attribute name="a4" type="int" />
      </extension>
    </simpleContent>
  </complexType>
</element>
</schema>
__SCHEMA__

ok(defined $schema);

my %t1 = (_ => 11, a2_a => 16);
test_rw($schema, "test1" => <<__XML, \%t1);
<test1 a2_a="16">11</test1>
__XML

my %t2 = (_ => 12, a3_a => 17);
test_rw($schema, "test2" => <<__XML, \%t2);
<test2 a3_a="17">12</test2>
__XML

test_rw($schema, "test2" => <<__XML, {_ => 14});
<test2>14</test2>
__XML

my %t3 = (_ => 30, a2_a => 31, a4 => 32);
test_rw($schema, "test3" => <<__XML, \%t3);
<test3 a2_a="31" a4="32">30</test3>
__XML

