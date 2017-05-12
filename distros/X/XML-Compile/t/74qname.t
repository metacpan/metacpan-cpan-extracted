#!/usr/bin/env perl
# QName builtins are harder, because they need the node which is processed
# to lookup the name-space.

use warnings;
use strict;

use lib 'lib','t';
use TestTools;

use XML::Compile::Schema;
use XML::Compile::Tester;

use Test::More tests => 33;

set_compile_defaults
    elements_qualified => 'NONE';

my $NS2 = "http://test2/ns";

my $schema   = XML::Compile::Schema->new( <<__SCHEMA__ );
<schema
   targetNamespace="$TestNS"
   xmlns="$SchemaNS"
   xmlns:me="$TestNS"
   elementFormDefault="qualified">

<element name="test1" type="QName" />

<element name="test2">
  <simpleType>
    <list itemType="QName" />
  </simpleType>
</element>

<element name="test3">
  <simpleType>
    <restriction base="QName" />
  </simpleType>
</element>

<element name="test4">
  <simpleType name="t1">
    <union>
      <simpleType>
        <restriction base="QName" />
      </simpleType>
      <simpleType>
        <restriction base="string">
          <enumeration value="unbounded" />
        </restriction>
      </simpleType>
    </union>
  </simpleType>
</element>


</schema>
__SCHEMA__

ok(defined $schema);

my %prefixes =
  ( $TestNS => { prefix => '', uri => $TestNS }
  , $NS2    => { prefix => 'two', uri => $NS2, used => 1 }
  );

set_compile_defaults
    include_namespaces => 1
  , prefixes => \%prefixes;

### QName direct

test_rw($schema, test1 => <<__TRY1, "{$NS2}aaa"); 
<test1 xmlns="$TestNS" xmlns:two="$NS2">two:aaa</test1>
__TRY1

### QName in LIST

$prefixes{$NS2}{used} = 1;
test_rw($schema, test2 => <<__TRY2, [ "{$NS2}aaa", "{$NS2}bbb" ]); 
<test2 xmlns="$TestNS" xmlns:two="$NS2">
  two:aaa
  two:bbb
</test2>
__TRY2

### QName extended

$prefixes{$NS2}{used} = 1;
test_rw($schema, test3 => <<__TRY3, "{$NS2}aaa"); 
<test3 xmlns="$TestNS" xmlns:two="$NS2">two:aaa</test3>
__TRY3

### QName union

$prefixes{$NS2}{used} = 1;
test_rw($schema, test4 => <<__TRY4, "{$NS2}aaa"); 
<test4 xmlns="$TestNS" xmlns:two="$NS2">two:aaa</test4>
__TRY4
