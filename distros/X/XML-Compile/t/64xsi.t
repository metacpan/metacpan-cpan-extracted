#!/usr/bin/env perl
# xsi_type_everywhere

use warnings;
use strict;

use lib 'lib','t';
use TestTools;
use Data::Dumper;

use XML::Compile::Schema;
use XML::Compile::Tester;

use Test::More tests => 6;

set_compile_defaults
    elements_qualified  => 'NONE'
  , xsi_type_everywhere => 1;

my $schema   = XML::Compile::Schema->new( <<__SCHEMA__ );
<xsd:schema targetNamespace="$TestNS"
   xmlns:xsd="$SchemaNS"
   xmlns:me="$TestNS">

<xsd:element name="test1">
  <xsd:complexType>
    <xsd:sequence>
      <xsd:element name="count" type="xsd:int"/>
    </xsd:sequence>
    <xsd:attribute name="id" type="xsd:string" />
  </xsd:complexType>
</xsd:element>

</xsd:schema>
__SCHEMA__

ok(defined $schema);

my $w1 = writer_create $schema, "nameless with attrs" => "{$TestNS}test1";

my $w1b = writer_test($w1, { count => 3, id => 6});
compare_xml($w1b,  '<test1 id="6"><count xsi:type="xsd:int">3</count></test1>');

