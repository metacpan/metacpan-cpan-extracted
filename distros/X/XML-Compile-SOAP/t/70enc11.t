#!/usr/bin/env perl
# Test SOAP encoding

use warnings;
use strict;

use lib 'lib','t';
use TestTools;

use Data::Dumper;
$Data::Dumper::Indent = 1;

use XML::Compile::SOAP11::Client;
use XML::Compile::SOAP11::Encoding;
use XML::Compile::SOAP::Util qw/:soap11/;
use XML::Compile::Util       qw/SCHEMA2001 pack_type/;
use XML::Compile::Tester;

use Test::More tests => 65;

use XML::LibXML;
use TestTools;

my $TestNS = 'http://test-ns';

my $soap = XML::Compile::SOAP11::Client->new;

ok(defined $soap, 'created client');
isa_ok($soap, 'XML::Compile::SOAP11::Client');

my $doc   = XML::LibXML::Document->new('1.0', 'UTF-8');
$soap->startEncoding;

my $int    = pack_type SCHEMA2001, 'int';
my $string = pack_type SCHEMA2001, 'string';

#
# enc()
#

my $enc1 = $soap->enc(int => 41);
compare_xml($enc1, '<SOAP-ENC:int>41</SOAP-ENC:int>');

my $enc2 = $soap->enc(int => 42, 'hhtg');
compare_xml($enc2, '<SOAP-ENC:int id="hhtg">42</SOAP-ENC:int>');

#
# typed()
#

my $typed1 = $soap->typed(pack_type(SCHEMA2001, 'int'), code => 43);
compare_xml($typed1, '<code xsi:type="xsd:int">43</code>');

my $typed2 = $soap->typed(float => price => 2.71);
compare_xml($typed2, '<price xsi:type="xsd:float">2.71</price>');

# no namespace less schema defined (yet)
# my $typed3 = $soap->typed('{}nons' => price => 12.1);
# compare_xml($typed3, '<price xsi:type="nons">12.1</price>');

#
# href()
#

my $href1 = $soap->href('ref', $enc1);
compare_xml($href1, '<ref href="#id-1"/>');
compare_xml($enc1, '<SOAP-ENC:int id="id-1">41</SOAP-ENC:int>');

my $href2 = $soap->href(pack_type(SOAP11ENC, 'xyz'), $enc2, 'myid');
compare_xml($href2, '<SOAP-ENC:xyz href="#hhtg"/>');
compare_xml($enc2, '<SOAP-ENC:int id="hhtg">42</SOAP-ENC:int>');

#
# NIL
#

my $nil1 = $soap->nil('friend');
compare_xml($nil1, '<friend xsi:nil="true"/>');

my $nil2 = $soap->nil(pack_type($TestNS, 'friend'));
compare_xml($nil2, <<__XML);
<friend xmlns="$TestNS" xsi:nil="true"/>
__XML

compare_xml($soap->nil($string, pack_type($TestNS, 'friend')), <<__XML);
<friend xmlns="http://test-ns" xsi:nil="true" xsi:type="xsd:string"/>
__XML

#
# array()
#

# SOAP11 NOTE example 1

my $e1a = $soap->element($int, number => 3);
isa_ok($e1a, 'XML::LibXML::Element', 'example 1');
compare_xml($e1a, '<number>3</number>');
my $e1b = $soap->element($int, number => 4);

my $a1 = $soap->array('myFavoriteNumbers', $int, [$e1a, $e1b], id => 'array-1');
isa_ok($a1, 'XML::LibXML::Element');
compare_xml($a1, <<__XML);
<myFavoriteNumbers id="array-1" SOAP-ENC:arrayType="xsd:int[2]">
  <number>3</number>
  <number>4</number>
</myFavoriteNumbers>
__XML

my $h1 = $soap->href(ref => $a1);
isa_ok($h1, 'XML::LibXML::Element');
compare_xml($h1, '<ref href="#array-1"/>');

# SOAP11 NOTE example 2

my $e2a = $soap->enc(int => 3);
isa_ok($e2a, 'XML::LibXML::Element', 'example 2');
compare_xml($e2a, '<SOAP-ENC:int>3</SOAP-ENC:int>');

my $e2b = $soap->enc(int => 4);
isa_ok($e2b, 'XML::LibXML::Element');
compare_xml($e2b, '<SOAP-ENC:int>4</SOAP-ENC:int>');

my $a2 = $soap->array(undef, $int, [$e2a, $e2b]);
isa_ok($a2, 'XML::LibXML::Element');

compare_xml($a2, <<__XML);
<SOAP-ENC:Array SOAP-ENC:arrayType="xsd:int[2]">
  <SOAP-ENC:int>3</SOAP-ENC:int>
  <SOAP-ENC:int>4</SOAP-ENC:int>
</SOAP-ENC:Array>
__XML

# SOAP11 NOTE example 3

my $e3a = $soap->typed($int, thing => 12345);
isa_ok($e3a, 'XML::LibXML::Element');
compare_xml($e3a, '<thing xsi:type="xsd:int">12345</thing>');

my $e3b = $soap->typed(pack_type(SCHEMA2001, 'decimal'), thing => 6.789);
isa_ok($e3b, 'XML::LibXML::Element');
compare_xml($e3b, '<thing xsi:type="xsd:decimal">6.789</thing>');

my $e3t = 'Of Mans First ... ... and all our woe,';
my $e3c = $soap->typed($string, thing => $e3t);
isa_ok($e3c, 'XML::LibXML::Element');
compare_xml($e3c, "<thing xsi:type=\"xsd:string\">$e3t</thing>");

my $e3u = 'http://www.dartmouth.edu/~milton/reading_room/';

my $e3d = $soap->typed(pack_type(SCHEMA2001, 'anyURI'), thing => $e3u);
isa_ok($e3d, 'XML::LibXML::Element');
compare_xml($e3d, "<thing xsi:type=\"xsd:anyURI\">$e3u</thing>");

my $a3 = $soap->array(undef, pack_type(SCHEMA2001, 'anyType')
  , [ $e3a, $e3b, $e3c, $e3d ], id => 'label');
isa_ok($a3, 'XML::LibXML::Element');

compare_xml($a3, <<__XML);
<SOAP-ENC:Array id="label" SOAP-ENC:arrayType="xsd:anyType[4]">
   <thing xsi:type="xsd:int">12345</thing>
   <thing xsi:type="xsd:decimal">6.789</thing>
   <thing xsi:type="xsd:string">
       $e3t
   </thing>
   <thing xsi:type="xsd:anyURI">
       $e3u
   </thing>
</SOAP-ENC:Array>
__XML

# SOAP11 NOTE example 4

my $e4a = $soap->enc(int => 12345);
compare_xml($e4a, '<SOAP-ENC:int>12345</SOAP-ENC:int>');

my $e4b = $soap->enc(decimal => 6.789);
compare_xml($e4b, '<SOAP-ENC:decimal>6.789</SOAP-ENC:decimal>');

my $e4c = $e3c;

my $e4d = $soap->enc(anyURI => $e3u);
compare_xml($e4d, "<SOAP-ENC:anyURI>$e3u</SOAP-ENC:anyURI>");

my $a4 = $soap->array(undef, pack_type(SCHEMA2001, 'anyType')
  , [ $e4a, $e4b, $e4c, $e4d ], id => 'label');
isa_ok($a4, 'XML::LibXML::Element');

compare_xml($a4, <<__XML);
<SOAP-ENC:Array id="label" SOAP-ENC:arrayType="xsd:anyType[4]">
   <SOAP-ENC:int>12345</SOAP-ENC:int>
   <SOAP-ENC:decimal>6.789</SOAP-ENC:decimal>
   <thing xsi:type="xsd:string">
      $e3t
   </thing>
   <SOAP-ENC:anyURI>
      $e3u
   </SOAP-ENC:anyURI>
</SOAP-ENC:Array>
__XML

# SOAP11 NOTE example 5

$soap->schemas->importDefinitions( <<__SCHEMA );
<schema targetNamespace="$TestNS"
   xmlns="$SchemaNS"
   xmlns:me="$TestNS">

  <element name="Order">
    <complexType>
      <sequence>
        <element name="Product" type="string"/>
        <element name="Price"   type="decimal"/>
      </sequence>
    </complexType>
  </element>

</schema>
__SCHEMA

my $ot = pack_type $TestNS, 'Order';
my $order = $soap->schemas->compile(WRITER => $ot, include_namespaces => 0);

my $o1 = $order->($doc, {Product => 'Apple', Price => 1.56});
isa_ok($o1, 'XML::LibXML::Element');
compare_xml($o1, '<me:Order><Product>Apple</Product><Price>1.56</Price></me:Order>');

my $o2 = $order->($doc, {Product => 'Peach', Price => 1.48});
compare_xml($o2, '<me:Order><Product>Peach</Product><Price>1.48</Price></me:Order>');

my $a5 = $soap->array(undef, $ot, [$o1, $o2]);
isa_ok($a5, 'XML::LibXML::Element');
compare_xml($a5, <<'__XML');
<SOAP-ENC:Array SOAP-ENC:arrayType="me:Order[2]">
  <me:Order>
    <Product>Apple</Product>
    <Price>1.56</Price>
  </me:Order>
  <me:Order>
    <Product>Peach</Product>
    <Price>1.48</Price>
  </me:Order>
</SOAP-ENC:Array>
__XML

# SOAP11 NOTE example 6

my @e6 = map { $soap->element($string, item => $_) }
  qw/r1c1 r1c2 r1c3 r2c1 r2c2/;
my $a6a = $soap->array(undef, $string, [ @e6[0..2] ], id => 'array-1');
compare_xml($a6a, <<__XML);
<SOAP-ENC:Array id="array-1" SOAP-ENC:arrayType="xsd:string[3]">
  <item>r1c1</item>
  <item>r1c2</item>
  <item>r1c3</item>
</SOAP-ENC:Array>
__XML
my $a6b = $soap->array(undef, $string, [ @e6[3,4] ], id => 'array-2');
compare_xml($a6b, <<__XML);
<SOAP-ENC:Array id="array-2" SOAP-ENC:arrayType="xsd:string[2]">
  <item>r2c1</item>
  <item>r2c2</item>
</SOAP-ENC:Array>
__XML
my $h6a = $soap->href(item => $a6a);
compare_xml($h6a, '<item href="#array-1"/>');
my $h6b = $soap->href(item => $a6b);
my $a6c = $soap->array(undef, "$string\[]", [$h6a, $h6b] );
compare_xml($a6c, <<__XML);
<SOAP-ENC:Array SOAP-ENC:arrayType="xsd:string[][2]">
  <item href="#array-1"/>
  <item href="#array-2"/>
</SOAP-ENC:Array>
__XML

# SOAP11 NOTE example 7

my $soapenc = SOAP11ENC;
$soap->schemas->importDefinitions( <<__SCHEMA );
<schema targetNamespace="$TestNS"
        xmlns="$SchemaNS"
        xmlns:tns="$TestNS"
        xmlns:SOAP-ENC="$soapenc"
  >

<simpleType name="phoneNumber">
  <restriction base="string"/>
</simpleType>

<element name="ArrayOfPhoneNumbers">
  <complexType>
    <complexContent>
      <extension base="SOAP-ENC:Array">
        <sequence>
          <element name="phoneNumber" type="tns:phoneNumber"
            maxOccurs="unbounded"/>
        </sequence>
      </extension>
    </complexContent>
  </complexType>
</element>

</schema>
__SCHEMA


my $e7t = pack_type $TestNS, 'ArrayOfPhoneNumbers';
my $pn  = $soap->schemas->compile
  ( WRITER => $e7t
  , elements_qualified => 'TOP'
  , prefixes  => [ xyz => $TestNS ]     # same, shorter
  , include_namespaces => 0
  );

ok(defined $pn, 'test 7');
my $e7x = $pn->($doc, { phoneNumber => ['206-555-1212', '1-888-123-4567'] });

compare_xml($e7x, <<__XML);
<xyz:ArrayOfPhoneNumbers>
   <phoneNumber>206-555-1212</phoneNumber>
   <phoneNumber>1-888-123-4567</phoneNumber>
</xyz:ArrayOfPhoneNumbers>
__XML

# SOAP11 NOTE "partially transmitted arrays"

my @e8 = map { $soap->element($string, item => "The $_ element") }
   qw/first second third fourth fifth/;

my $a8a = $soap->array(undef, $string, \@e8);
compare_xml($a8a, <<__XML);
<SOAP-ENC:Array SOAP-ENC:arrayType="xsd:string[5]">
  <item>The first element</item>
  <item>The second element</item>
  <item>The third element</item>
  <item>The fourth element</item>
  <item>The fifth element</item>
</SOAP-ENC:Array>
__XML

my $a8b = $soap->array(undef, $string, \@e8, offset => 2, slice => 2);
compare_xml($a8b, <<__XML);
<SOAP-ENC:Array SOAP-ENC:arrayType="xsd:string[5]" SOAP-ENC:offset="[2]">
  <item>The third element</item>
  <item>The fourth element</item>
</SOAP-ENC:Array>
__XML

my $a8c = $soap->array(undef, $string, \@e8, offset => 2);
compare_xml($a8c, <<__XML);
<SOAP-ENC:Array SOAP-ENC:arrayType="xsd:string[5]" SOAP-ENC:offset="[2]">
  <item>The third element</item>
  <item>The fourth element</item>
  <item>The fifth element</item>
</SOAP-ENC:Array>
__XML

my $a8d = $soap->array(undef, $string, \@e8, slice => 3);
compare_xml($a8d, <<__XML);
<SOAP-ENC:Array SOAP-ENC:arrayType="xsd:string[5]">
  <item>The first element</item>
  <item>The second element</item>
  <item>The third element</item>
</SOAP-ENC:Array>
__XML

# sparse

my @e8s = (undef, $e8[1], undef, $e8[3], undef);
my $a8e = $soap->array(undef, $string, \@e8s);
compare_xml($a8e, <<__XML);
<SOAP-ENC:Array SOAP-ENC:arrayType="xsd:string[5]">
   <item SOAP-ENC:position="[1]">The second element</item>
   <item SOAP-ENC:position="[3]">The fourth element</item>
</SOAP-ENC:Array>
__XML

my $a8f = $soap->array(undef, $string, \@e8s, offset => 1, slice => 1);
compare_xml($a8f, <<__XML);
<SOAP-ENC:Array
   SOAP-ENC:arrayType="xsd:string[5]" SOAP-ENC:offset="[1]">
   <item>The second element</item>
</SOAP-ENC:Array>
__XML

my $a8g = $soap->array(undef, $string, \@e8s, offset => 0, slice => 2);
compare_xml($a8g, <<__XML);
<SOAP-ENC:Array
   SOAP-ENC:arrayType="xsd:string[5]" SOAP-ENC:offset="[1]">
   <item>The second element</item>
</SOAP-ENC:Array>
__XML

my $a8h = $soap->array(undef, $string, \@e8s, offset => 1, slice => 3);
compare_xml($a8h, <<__XML);
<SOAP-ENC:Array SOAP-ENC:arrayType="xsd:string[5]">
   <item SOAP-ENC:position="[1]">The second element</item>
   <item SOAP-ENC:position="[3]">The fourth element</item>
</SOAP-ENC:Array>
__XML

# SOAP11 NOTE multidimensional arrays

my @e9 = map { $soap->element($string, item => $_) }
   qw/r1c1 r1c2 r1c3 r2c1 r2c2 r2c3/;
my @t9 = ( [ @e9[0..2] ], [ @e9[3..5] ] );
my $a9a = $soap->multidim(undef, $string, \@t9);
isa_ok($a9a, 'XML::LibXML::Element');
compare_xml($a9a, <<__XML);
<SOAP-ENC:Array SOAP-ENC:arrayType="xsd:string[2,3]">
  <item>r1c1</item>
  <item>r1c2</item>
  <item>r1c3</item>
  <item>r2c1</item>
  <item>r2c2</item>
  <item>r2c3</item>
  </SOAP-ENC:Array>
__XML

my @t9s = ( [ $e9[0], undef, $e9[2] ], [ @e9[3,4] ] );
my $a9b = $soap->multidim(undef, $string, \@t9s);
compare_xml($a9b, <<__XML);
<SOAP-ENC:Array SOAP-ENC:arrayType="xsd:string[2,3]">
   <item SOAP-ENC:position="[0,0]">r1c1</item>
   <item SOAP-ENC:position="[0,2]">r1c3</item>
   <item SOAP-ENC:position="[1,0]">r2c1</item>
   <item SOAP-ENC:position="[1,1]">r2c2</item>
</SOAP-ENC:Array>
__XML

# now the example from the spec
my $t10;
$t10->[2][2] = $soap->element($string, item => 'Third row, third col');
$t10->[7][2] = $soap->element($string, item => 'Eight row, third col');
$t10->[9]    = undef;
$t10->[0][9] = undef;
my $a10a = $soap->multidim(undef, $string, $t10);

my $h10ref   = $soap->href(pack_type(SOAP11ENC, 'Array')
  , $a10a, 'array-1');
my @t10b     = (undef, undef, $h10ref, undef);
my $a10b     = $soap->array(undef, $string, \@t10b, nested_array => '[,]');

compare_xml($a10b->toString . $a10a->toString, <<__XML);
<SOAP-ENC:Array SOAP-ENC:arrayType="xsd:string[,][4]" SOAP-ENC:offset="[2]">
  <SOAP-ENC:Array href="#array-1"/>
</SOAP-ENC:Array>
<SOAP-ENC:Array SOAP-ENC:arrayType="xsd:string[10,10]" id="array-1">
  <item SOAP-ENC:position="[2,2]">Third row, third col</item>
  <item SOAP-ENC:position="[7,2]">Eight row, third col</item>
</SOAP-ENC:Array>
__XML

my @t10c     = (undef, undef, $a10a, undef);
my $a10c     = $soap->array(undef, $string, \@t10c, nested_array => '[,]');
compare_xml($a10c, <<__XML);
<SOAP-ENC:Array SOAP-ENC:arrayType="xsd:string[,][4]" SOAP-ENC:offset="[2]">
  <SOAP-ENC:Array SOAP-ENC:arrayType="xsd:string[10,10]" id="array-1">
    <item SOAP-ENC:position="[2,2]">Third row, third col</item>
    <item SOAP-ENC:position="[7,2]">Eight row, third col</item>
  </SOAP-ENC:Array>
</SOAP-ENC:Array>
__XML

#
# Struct
#

my $struct1 = $soap->struct(MyMessage => $enc1, $enc2, $typed1
  , $typed2, $href1, $href2, $a1, $a2);

compare_xml($struct1, <<'__XML');
<MyMessage>
  <SOAP-ENC:int id="id-1">41</SOAP-ENC:int>
  <SOAP-ENC:int id="hhtg">42</SOAP-ENC:int>
  <code xsi:type="xsd:int">43</code>
  <price xsi:type="xsd:float">2.71</price>
  <ref href="#id-1"/>
  <SOAP-ENC:xyz href="#hhtg"/>
  <myFavoriteNumbers id="array-1" SOAP-ENC:arrayType="xsd:int[2]">
    <number>3</number>
    <number>4</number>
  </myFavoriteNumbers>
  <SOAP-ENC:Array SOAP-ENC:arrayType="xsd:int[2]">
    <SOAP-ENC:int>3</SOAP-ENC:int>
    <SOAP-ENC:int>4</SOAP-ENC:int>
  </SOAP-ENC:Array>
</MyMessage>
__XML
