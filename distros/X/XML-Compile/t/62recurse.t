#!/usr/bin/env perl
# Recursive schemas

use warnings;
use strict;

use lib 'lib','t';
use TestTools;
use Data::Dumper;

use XML::Compile::Schema;
use XML::Compile::Tester;

use Test::More tests => 65;

set_compile_defaults
    elements_qualified => 'NONE';

my $schema   = XML::Compile::Schema->new( <<__SCHEMA__ );
<schema targetNamespace="$TestNS"
        xmlns="$SchemaNS"
        xmlns:me="$TestNS">

<element name="test1">
  <complexType>
    <sequence>
      <element ref="me:test1" minOccurs="0" />
      <element name="count" type="int" />
    </sequence>
  </complexType>
</element>

<element name="test2" type="me:type2"/>
<complexType name="type2">
  <sequence>
    <element name="a" type="int" />
    <element name="b" type="me:type2" minOccurs="0" />
  </sequence>
</complexType>

# this is not recursion
<element name="test3">
  <complexType>
    <sequence>
      <element name="c">
        <complexType>
          <sequence>
            <element name="c" type="int"/>
          </sequence>
        </complexType>
      </element>
    </sequence>
  </complexType>
</element>

# ... neither is this one
<element name="test4">
  <complexType>
    <sequence>
      <element name="test4" type="int" />
    </sequence>
  </complexType>
</element>

</schema>
__SCHEMA__

ok(defined $schema);

### test 1, recursive element

test_rw($schema, test1 => <<__XML, {count => 1});
<test1>
  <count>1</count>
</test1>
__XML

test_rw($schema, test1 => <<__XML, {count => 1, test1 => {count => 2}});
<test1>
  <test1>
    <count>2</count>
  </test1>
  <count>1</count>
</test1>
__XML

test_rw($schema, test1 => <<__XML, {count => 1, test1 => {count => 2, test1 => {count => 3}}});
<test1>
  <test1>
    <test1>
      <count>3</count>
    </test1>
    <count>2</count>
  </test1>
  <count>1</count>
</test1>
__XML

### test 2, recursive type

test_rw($schema, test2 => <<__XML, {a => 4});
<test2>
  <a>4</a>
</test2>
__XML

test_rw($schema, test2 => <<__XML, {a => 5, b => {a => 6}});
<test2>
  <a>5</a>
  <b><a>6</a></b>
</test2>
__XML

test_rw($schema, test2 => <<__XML, {a => 7, b => {a => 8, b => {a => 9}}});
<test2>
  <a>7</a>
  <b><a>8</a>
     <b><a>9</a>
     </b>
  </b>
</test2>
__XML

### test 3, no recursion [when detected as recursion, you get errors]

test_rw($schema, test3 => <<__XML, { c => { c => 42 } } );
<test3><c><c>42</c></c></test3>
__XML

### test 4, no recursion

test_rw($schema, test4 => <<__XML, { test4 => 11 } );
<test4><test4>11</test4></test4>
__XML
