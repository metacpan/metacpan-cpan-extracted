#!/usr/bin/env perl
# simpleType union

use warnings;
use strict;

use lib 'lib','t';
use TestTools;

use XML::Compile::Schema;
use XML::Compile::Tester;

use Test::More tests => 91;

set_compile_defaults
    elements_qualified => 'NONE';

my $schema   = XML::Compile::Schema->new( <<__SCHEMA__ );
<schema targetNamespace="$TestNS"
        xmlns="$SchemaNS"
        xmlns:me="$TestNS">

<simpleType name="t1">
  <union>
    <simpleType>
      <restriction base="int" />
    </simpleType>
    <simpleType>
      <restriction base="string">
        <enumeration value="unbounded" />
      </restriction>
    </simpleType>
  </union>
</simpleType>

<element name="test1" type="me:t1" />

<simpleType name="t2">
  <restriction base="string">
     <enumeration value="any" />
  </restriction>
</simpleType>

<simpleType name="t3">
  <union memberTypes="me:t2 int">
    <simpleType>
      <restriction base="string">
         <enumeration value="none" />
      </restriction>
    </simpleType>
  </union>
</simpleType>
<element name="test3" type="me:t3" />

<simpleType name="timestampType">
  <union memberTypes="date dateTime" />
</simpleType>
<element name="test4" type="me:timestampType" />

</schema>
__SCHEMA__

ok(defined $schema);
my $error;

### test1

test_rw($schema, test1 => <<__XML, 1 );
<test1>1</test1>
__XML

test_rw($schema, test1 => <<__XML, 'unbounded');
<test1>unbounded</test1>
__XML

$error = error_r($schema, test1 => <<__XML);
<test1>other</test1>
__XML
is($error, "no match for `other' in union at {http://test-types}test1#union");

$error = error_w($schema, test1 => 'other');
is($error, "no match for `other' in union at {http://test-types}test1#union");

### test3

test_rw($schema, test3 => <<__XML, 1 );
<test3>1</test3>
__XML

test_rw($schema, test3 => <<__XML, 'any');
<test3>any</test3>
__XML

test_rw($schema, test3 => <<__XML, 'none');
<test3>none</test3>
__XML

$error = error_r($schema, test3 => <<__XML);
<test3>other</test3>
__XML
is($error, "no match for `other' in union at {http://test-types}test3#union");

$error = error_w($schema, test3 => 'other');
is($error, "no match for `other' in union at {http://test-types}test3#union");

### test4

test_rw($schema, test4 => "<test4>2011-07-06</test4>", '2011-07-06');

test_rw($schema, test4 => "<test4>2011-07-06T10:06:24</test4>",
   '2011-07-06T10:06:24');

test_rw($schema, test4 => "<test4>2011-07-06T10:06:54Z</test4>",
   '2011-07-06T10:06:54Z');

test_rw($schema, test4 => "<test4>2011-07-06T10:10:32+02:00</test4>",
   '2011-07-06T10:10:32+02:00');
