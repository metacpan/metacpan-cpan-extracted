#!/usr/bin/env perl
# simpleType list

use warnings;
use strict;

use lib 'lib','t';
use TestTools;

use XML::Compile::Schema;
use XML::Compile::Tester;

use Test::More tests => 92;

set_compile_defaults
    elements_qualified => 'NONE';

my $schema   = XML::Compile::Schema->new( <<__SCHEMA );
<schema targetNamespace="$TestNS"
        xmlns="$SchemaNS"
        xmlns:me="$TestNS">

<simpleType name="t1">
  <list itemType="int" />
</simpleType>

<element name="test1" type="me:t1" />

<simpleType name="t2">
  <list>
    <simpleType>
      <restriction base="int" />
    </simpleType>
  </list>
</simpleType>

<element name="test2" type="me:t2" />

<element name="test3">
  <simpleType>
    <restriction base="me:t2">
      <enumeration value="1 2" />
      <enumeration value="2 1" />
    </restriction>
  </simpleType>
</element>

<element name="test4">
  <simpleType>
    <restriction base="NMTOKENS">
      <enumeration value="3 4" />
      <enumeration value="5 6" />
    </restriction>
  </simpleType>
</element>

</schema>
__SCHEMA

ok(defined $schema);

test_rw($schema, test1 => <<__XML, [1]);
<test1>1</test1>
__XML

test_rw($schema, test1 => <<__XML, [2, 3]);
<test1>2 3</test1>
__XML

test_rw($schema, test1 => <<__XML, [4, 5, 6]);
<test1> 4
  5\t  6 </test1>
__XML

test_rw($schema, test2 => <<__XML, [1]);
<test2>1</test2>
__XML

test_rw($schema, test2 => <<__XML, [2, 3]);
<test2>2 3</test2>
__XML

test_rw($schema, test2 => <<__XML, [4, 5, 6]);
<test2> 4
  5\t  6 </test2>
__XML


# restriction on simple-list base

test_rw($schema, test3 => <<__XML, [1, 2]);
<test3>1 2</test3>
__XML

test_rw($schema, test3 => <<__XML, [2, 1]);
<test3>2 1</test3>
__XML

my $error = error_r($schema, test3 => '<test3>2 2</test3>');
is($error, "invalid enumerate `2 2' at {http://test-types}test3#facet");

$error = error_w($schema, test3 => [3, 3]);
is($error, "invalid enumerate `3 3' at {http://test-types}test3#facet");

# predefined

test_rw($schema, test4 => <<__XML, [3, 4]);
<test4>3 4</test4>
__XML

$error = error_w($schema, test4 => [3, 3]);
is($error, "invalid enumerate `3 3' at {http://test-types}test4#facet");

# element has attributes as well

my $w1 = writer_create($schema, "HASH param" => "{$TestNS}test1");
my $x1 = writer_test($w1, {_ => [7,8]});

compare_xml($x1->toString, <<'_XML');
<test1>7 8</test1>
_XML
