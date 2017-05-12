#!/usr/bin/env perl
# test complex type simpleContent restrictions

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

<element name="test1" type="me:t1" />
<complexType name="t1">
  <simpleContent>
    <restriction base="int">
       <attribute name="a1_a" type="int" />
    </restriction>
  </simpleContent>
</complexType>

<element name="test2" type="me:t2" />
<complexType name="t2">
  <simpleContent>
    <restriction base="int">
       <attribute name="a2_a" type="int" />
    </restriction>
  </simpleContent>
</complexType>

<element name="test3" type="me:t3" />
<complexType name="t3">
  <simpleContent>
    <restriction>
       <simpleType>
         <restriction base="int" />
       </simpleType>
       <attribute name="a3_a" type="int" />
    </restriction>
  </simpleContent>
</complexType>

<element name="test4">
  <complexType>
    <simpleContent>
      <restriction base="anyType">
        <simpleType>
          <restriction base="string">
            <minLength value="1"/>
          </restriction>
        </simpleType>
        <attribute name="language" use="required"/>
      </restriction>
    </simpleContent>
  </complexType>
</element>

</schema>
__SCHEMA__

ok(defined $schema);

my %t1 = (_ => 11, a1_a => 10);
test_rw($schema, test1 => <<_XML, \%t1);
<test1 a1_a="10">11</test1>
_XML

my %t2 = (_ => 12, a2_a => 13);
test_rw($schema, test2 => <<_XML, \%t2);
<test2 a2_a="13">12</test2>
_XML

my %t3 = (_ => 14, a3_a => 15);
test_rw($schema, test3 => <<_XML, \%t3);
<test3 a3_a="15">14</test3>
_XML

# test 4, report rt.cpan.org#46212  by Erich Weigand

test_rw($schema, test4 => <<_XML, { language => 'de', _ => 'Hallo Welt' } );
<test4 language="de">Hallo Welt</test4>
_XML
