#!/usr/bin/env perl
# test complex type extensions

use warnings;
use strict;

use lib 'lib','t';
use TestTools;

use XML::Compile::Schema;
use XML::Compile::Tester;

use Test::More tests => 50;

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

<element name="test3" type="me:t3" />
<complexType name="t3">
  <attribute name="a3_a" type="int" />
</complexType>

<element name="test4">
  <complexType>
    <complexContent>
      <extension base="me:t3">
        <sequence>
          <element name="e4_a" type="int" />
        </sequence>
        <attribute name="a4_a" type="int" />
      </extension>
    </complexContent>
  </complexType>
</element>

<element name="test5" type="me:t5" />
<complexType name="t5">
  <sequence>
    <element name="e5" minOccurs="0" maxOccurs="5" />
  </sequence>
</complexType>

<element name="test6">
  <complexType>
    <sequence>
      <element name="e6" minOccurs="0" maxOccurs="5" type="me:t5" />
    </sequence>
    <attribute name="a6" type="int" />
  </complexType>
</element>

</schema>
__SCHEMA__

ok(defined $schema);

my %t1 = (t1_a => 11, t1_b => 12, a1_a => 13, a1_b => 14, t2_a => 15, a2_a=>16);

test_rw($schema, "test1" => <<__XML, \%t1);
<test1 a1_a="13" a1_b="14" a2_a="16">
   <t1_a>11</t1_a>
   <t1_b>12</t1_b>
   <t2_a>15</t2_a>
</test1>
__XML

### no base block

test_rw($schema, test3 => <<__XML, {a3_a => 20});
<test3 a3_a="20"/>
__XML

test_rw($schema, test4 => <<__XML, {a3_a => 21, a4_a => 22, e4_a => 23});
<test4 a3_a="21" a4_a="22">
  <e4_a>23</e4_a>
</test4>
__XML

### nested repeats

my %t6 = ( e6 => [ { e5 => [ 30, 31 ] }
                 , { e5 => [ 32 ] }
                 , { }
                 ] );

test_rw($schema, test6 => <<__XML, \%t6);
<test6>
  <e6><e5>30</e5><e5>31</e5></e6>
  <e6><e5>32</e5></e6>
  <e6/>
</test6>
__XML

test_rw($schema, test6 => '<test6/>', {});

test_rw($schema, test6 => '<test6><e6/></test6>', {e6 => [ {} ]} );

# attempt to reproduce bug rt.cpan.org#79986, reported by Karen Etheridge
my $out = templ_perl $schema, "{$TestNS}test1", skip_header => 1;
is($out, <<__EXPECT, 'templ of extension');
# Describing complex x0:test1
#     {http://test-types}test1

# is a x0:t2
{ # is a xs:int
  # becomes an attribute
  a1_a => 42,

  # is a xs:int
  # attribute a1_b is required
  a1_b => 42,

  # is a xs:int
  # becomes an attribute
  a2_a => 42,

  # sequence of t1_a, t1_b

  # is a xs:int
  t1_a => 42,

  # is a xs:int
  t1_b => 42,

  # sequence of t2_a

  # is a xs:int
  t2_a => 42, }
__EXPECT

