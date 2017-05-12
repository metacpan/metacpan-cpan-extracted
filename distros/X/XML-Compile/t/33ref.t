#!/usr/bin/env perl

use warnings;
use strict;

use lib 'lib','t';
use TestTools;

use XML::Compile::Schema;
use XML::Compile::Tester;

use Test::More tests => 25;

my $TestNS2 = "http://second-ns";

set_compile_defaults
    elements_qualified => 'NONE';

my $schema  = XML::Compile::Schema->new( <<__SCHEMA__ );
<schemas>

<schema targetNamespace="$TestNS"
        xmlns="$SchemaNS"
        xmlns:me="$TestNS">

<element name="test1" type="me:c1" />
<complexType name="c1">
  <sequence>
     <element name="e1_a" type="int" />
     <element name="e1_b" type="int" />
  </sequence>
  <attribute name="a1_a" type="int" />
</complexType>

<group name="g2">
  <sequence>
     <element name="g2_a" type="int" />
     <element name="g2_b" type="int" />
  </sequence>
</group>

<element name="test2">
  <complexType>
    <sequence>
      <element name="e2_a" type="int" />
      <group ref="me:g2" />
      <element name="e2_b" type="int" />
    </sequence>
  </complexType>
</element>

<element name="test3">
  <complexType>
    <sequence>
      <group ref="me:g3" minOccurs="0" maxOccurs="unbounded" />
    </sequence>
  </complexType>
</element>

<group name="g3">
  <choice>
    <element name="g3_a" type="int"/>
    <element name="g3_b" type="int"/>
  </choice>
</group>

</schema>

<schema targetNamespace="$TestNS2"
        xmlns="$SchemaNS"
        xmlns:first="$TestNS">

<element name="test4">
  <complexType>
    <sequence>
      <element ref="first:test1" />
    </sequence>
  </complexType>
</element>

</schema>

</schemas>
__SCHEMA__

ok(defined $schema);

#
# element as reference to an element
#

my %r1_a = (a1_a => 10, e1_a => 11, e1_b => 12);
test_rw($schema, "{$TestNS2}test4" => <<__XML, {test1 => \%r1_a});
<test4>
   <test1 a1_a="10">
      <e1_a>11</e1_a>
      <e1_b>12</e1_b>
   </test1>
</test4>
__XML

#
# element groups
#

my %r2_a = (e2_a => 20, g2_a => 22, g2_b => 23, e2_b => 21);
test_rw($schema, test2 => <<__XML, \%r2_a);
<test2>
  <e2_a>20</e2_a>
  <g2_a>22</g2_a>
  <g2_b>23</g2_b>
  <e2_b>21</e2_b>
</test2>
__XML

#
# ref to choice
#

my %r3_a = (gr_g3 => [ {g3_a => 30}, {g3_a => 31}, {g3_b => 32}, {g3_a => 33} ]);
test_rw($schema, test3 => <<__XML, \%r3_a);
<test3>
  <g3_a>30</g3_a>
  <g3_a>31</g3_a>
  <g3_b>32</g3_b>
  <g3_a>33</g3_a>
</test3>
__XML
