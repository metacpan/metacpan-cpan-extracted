#!/usr/bin/env perl

use warnings;
use strict;

use lib 'lib','t';
use TestTools;

use XML::Compile::Schema;
use XML::Compile::Tester;

use Test::More tests => 14;

my $schema   = XML::Compile::Schema->new( <<__SCHEMA__ );
<schema targetNamespace="$TestNS"
   xmlns="$SchemaNS"
   xmlns:me="$TestNS"
   elementFormDefault="qualified">

<element name="test1" type="int" />

<element name="test2" type="me:test2" />
<simpleType name="test2">
  <restriction base="int" />
</simpleType>

<element name="test3" type="me:test3" />
<complexType name="test3">
  <sequence>
    <element name="test3_1" type="int" />
    <element name="test3_2" type="int" />
  </sequence>
</complexType>

</schema>
__SCHEMA__

ok(defined $schema);

#
# Direct schema access
#

my $dirr = $schema->compile(READER => "{$SchemaNS}int");
ok(defined $dirr, 'read an int');
my $val = $dirr->('<some>40</some>');
cmp_ok($val, '==', 40);

my $dirw = $schema->compile(WRITER => "{$SchemaNS}int");
my $doc  = XML::LibXML->createDocument('1.0', 'UTF-8');
ok(defined $dirw, 'write an int');
my $node = $dirw->($doc, '41');
ok(ref $node, 'created XML node');
isa_ok($node, 'XML::LibXML::Text');
compare_xml($node, '41');

#
# simple element type
#

my $read_t1   = $schema->compile
 ( READER      => "{$TestNS}test1"
 , check_values => 1
 );

ok(defined $read_t1, "reader element test1");
cmp_ok(ref($read_t1), 'eq', 'CODE');

my $t1 = $read_t1->( <<__XML );
<test1 xmlns="$TestNS">42</test1>
__XML

cmp_ok($t1, '==', 42);

#
# the simpleType, less simple type
#

my $read_t2   = $schema->compile
 ( READER       => "{$TestNS}test2"
 , check_values => 1
 );

ok(defined $read_t2, "reader simpleType test2");
cmp_ok(ref($read_t2), 'eq', 'CODE');

my $hash = $read_t2->( <<__XML );
<test2 xmlns="$TestNS">42</test2>
__XML

#
# The not so complex complexType
#

my $read_t3   = $schema->compile
 ( READER       => "{$TestNS}test3"
 , check_values => 1
 );

ok(defined $read_t3, "reader complexType test3");
cmp_ok(ref($read_t3), 'eq', 'CODE');

my $hash2 = $read_t3->( <<__XML );
<me:test3 xmlns:me="$TestNS">
  <me:test3_1>13</me:test3_1>
  <me:test3_2>42</me:test3_2>
</me:test3>
__XML
