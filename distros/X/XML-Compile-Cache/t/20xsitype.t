#!/usr/bin/perl
# test the handling of xsi:type with prefixes.
# Adapted from t/75types.t in XML::Compile.

use warnings;
use strict;

use XML::Compile::Cache;
use XML::Compile::Tester;
use XML::Compile::Util    'SCHEMA2001';

use Test::More tests => 2;

our $TestNS   = 'http://test-types';
our $SchemaNS = SCHEMA2001;

my $schema    = XML::Compile::Cache->new( <<__SCHEMA__ );
<schema
    targetNamespace="$TestNS"
    xmlns="$SchemaNS"
    xmlns:me="$TestNS"
    elementFormDefault="qualified"
>

<complexType name="t1">
  <attribute name="a1" type="int"/>
</complexType>

<complexType name="t2">
  <complexContent>
    <extension base="me:t1">
      <sequence>
        <element name="a2" type="int"/>
      </sequence>
    </extension>
  </complexContent>
</complexType>

</schema>
__SCHEMA__

ok(defined $schema);
$schema->prefixes(me => $TestNS);
#$schema->printIndex;

my $xsi_type = $schema->xsiType('me:t1' => 'AUTO');
is_deeply($xsi_type,
  { "{$TestNS}t1" => [ "{$TestNS}t1", "{$TestNS}t2" ] });
