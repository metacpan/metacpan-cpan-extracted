#!/usr/bin/env perl
# test use of big math

use warnings;
use strict;

use lib 'lib','t';
use TestTools;

use XML::Compile::Schema;
use XML::Compile::Tester;

use Test::More;

BEGIN {
   eval 'require Math::BigInt';
   if($@)
   {   plan skip_all => "Math::BigInt not installed";
   }

   plan tests => 66;
}

# Will fail when perl's longs get larger than 64bit
my $some_big1 = "12432156239876121237";
my $some_big2 = "243587092790745290879";

my $schema   = XML::Compile::Schema->new( <<__SCHEMA__ );
<schema targetNamespace="$TestNS"
        xmlns="$SchemaNS"
        xmlns:me="$TestNS">

<simpleType name="t1">
  <restriction base="integer" />
</simpleType>

<element name="test1" type="me:t1" />

<simpleType name="t2">
  <restriction base="integer">
    <minInclusive value="40" />
    <maxInclusive value="$some_big1" />
  </restriction>
</simpleType>

<element name="test2" type="me:t2" />

<element name="test3">
  <complexType>
    <sequence>
      <element name="t3a" type="integer" default="$some_big2" />
      <element name="t3b" type="int"     default="11" />
    </sequence>
  </complexType>
</element>

<element name="test4">
  <complexType>
    <sequence>
      <element name="t4" type="integer" fixed="$some_big2" />
    </sequence>
  </complexType>
</element>

</schema>
__SCHEMA__

ok(defined $schema);

set_compile_defaults
    elements_qualified => 'NONE'
  , sloppy_integers    => 0;

##
### Integers
##

test_rw($schema, "test1" => <<__XML, 12);
<test1>12</test1>
__XML

test_rw($schema, "test1" => <<__XML, Math::BigInt->new($some_big1));
<test1>$some_big1</test1>
__XML

test_rw($schema, "test2" => <<__XML, 42);
<test2>42</test2>
__XML

test_rw($schema, "test2" => <<__XML, Math::BigInt->new($some_big1));
<test2>$some_big1</test2>
__XML

# limit to huge maxInclusive

my $error = error_r($schema, test2 => <<__XML);
<test2>$some_big2</test2>
__XML

is($error, 'too large inclusive 243587092790745290879, max 12432156239876121237 at {http://test-types}test2#facet');

$error = error_w($schema, test2 => Math::BigInt->new($some_big2));
is($error, 'too large inclusive 243587092790745290879, max 12432156239876121237 at {http://test-types}test2#facet');

#
## Big defaults
#

my %t31 = (t3a => Math::BigInt->new($some_big1), t3b => 13);
test_rw($schema, "test3" => <<__XML, \%t31);
<test3><t3a>$some_big1</t3a><t3b>13</t3b></test3>
__XML

my %t34 = (t3a => Math::BigInt->new($some_big2), t3b => 11);
test_rw($schema, test3 => <<__XML, \%t34, <<__XML, {t3b => 11});
<test3 />
__XML
<test3><t3b>11</t3b></test3>
__XML

#
## Big fixed
#

my $bi4 = Math::BigInt->new($some_big2);
test_rw($schema, test4 => <<__XML, {t4 => $bi4}, <<__XML, {t4 => $bi4});
<test4><t4>$some_big2</t4></test4>
__XML
<test4><t4>$some_big2</t4></test4>
__XML
