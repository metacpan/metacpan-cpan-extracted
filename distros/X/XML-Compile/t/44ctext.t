#!/usr/bin/env perl
# test complex type extensions

use warnings;
use strict;

use lib 'lib','t';
use TestTools;

use XML::Compile::Schema;
use XML::Compile::Tester;

use Test::More tests => 9;

set_compile_defaults
    elements_qualified => 'NONE';

my $schema   = XML::Compile::Schema->new( <<__SCHEMA__ );
<schema targetNamespace="$TestNS"
        xmlns="$SchemaNS"
        xmlns:me="$TestNS">

<complexType name="t1">
  <sequence>
    <element name="t1_a" type="int" />
    <element name="t1_b" type="int" />
  </sequence>
  <attribute name="a1_a" type="int" />
  <attribute name="a1_b" type="int" use="required" />
</complexType>

<complexType name="t2">
  <complexContent>
    <extension base="me:t1">
      <sequence>
        <element name="t2_a" type="int" />
      </sequence>
      <attribute name="a2_a" type="int" />
    </extension>
  </complexContent>
</complexType>

<element name="test1" type="me:t2" />

</schema>
__SCHEMA__

ok(defined $schema);

my %t1 = (t1_a => 11, t1_b => 12, a1_a => 13, a1_b => 14, t2_a => 15, a2_a=>16);

test_rw($schema, "test1" => <<__XML__, \%t1);
<test1 a1_a="13" a1_b="14" a2_a="16">
   <t1_a>11</t1_a>
   <t1_b>12</t1_b>
   <t2_a>15</t2_a>
</test1>
__XML__

