#!/usr/bin/env perl
#
# Run some general tests around the generation of elements.  We will
# test seperate components in more detail in other scripts.

use warnings;
use strict;

use lib 'lib','t';
use TestTools;

use XML::Compile::Schema;
use XML::Compile::Tester;

use Test::More tests => 65;

set_compile_defaults
    elements_qualified => 'NONE';

my $schema   = XML::Compile::Schema->new( <<__SCHEMA__ );
<schema targetNamespace="$TestNS"
        xmlns="$SchemaNS"
        xmlns:me="$TestNS">

<element name="test1" type="int" />

<element name="test3" type="me:st" />
<simpleType name="st">
  <restriction base="int" />
</simpleType>

<element name="test4" type="me:ct" />
<complexType name="ct">
  <sequence>
    <element name="ct_1" type="int" />
    <element name="ct_2" type="int" />
  </sequence>
</complexType>

<element name="test5">
  <complexType>
    <sequence>
      <element name="ct_1" type="int" />
      <element name="ct_2" type="int" />
    </sequence>
  </complexType>
</element>

<element name="test6">
  <simpleType>
    <restriction base="int" />
  </simpleType>
</element>

<element name="test7">
  <complexType>
    <sequence>
      <element name="ct_1" type="int" />
      <element name="ct_2" type="int" default="42" />
    </sequence>
  </complexType>
</element>

</schema>
__SCHEMA__

ok(defined $schema);

#
# simple element type
#

test_rw($schema, test1 => <<__XML, 42);
<test1>42</test1>
__XML

test_rw($schema, test1 => <<__XML, -1);
<test1>-1</test1>
__XML

test_rw($schema, test1 => <<__XML, 121);
<test1>

    121
  </test1>
__XML

#
# the simpleType, less simple type
#

test_rw($schema, test3 => <<__XML, 78);
<test3>78</test3>
__XML

test_rw($schema, test6 => <<__XML, 79);
<test6>79</test6>
__XML

#
# The not so complex complexType
#

test_rw($schema, test4 => <<__XML, {ct_1 => 14, ct_2 => 43}); 
<test4>
  <ct_1>14</ct_1>
  <ct_2>43</ct_2>
</test4>
__XML

test_rw($schema, test5 => <<__XML, {ct_1 => 15, ct_2 => 44}); 
<test5>
  <ct_1>15</ct_1>
  <ct_2>44</ct_2>
</test5>
__XML

# for test6 see above

#
# Test default: should not be set automatically
#

test_rw($schema, test7 => <<__XML, {ct_1 => 41, ct_2 => 42}, <<__XML, {ct_1 => 41});
<test7><ct_1>41</ct_1></test7>
__XML
<test7><ct_1>41</ct_1></test7>
__XML
