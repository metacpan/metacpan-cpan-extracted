#!/usr/bin/env perl
# Try different calling convensions (::Tester is only using one)
# A few options are not formally tested; hopefully in the future.

# This script should work before any output of the other tests
# starts to be useful.

use warnings;
use strict;

use lib 'lib','t';
use TestTools;

use XML::Compile::Schema;
use XML::Compile::Tester;
#use Log::Report mode => 3;

use Test::More tests => 11;

my $schema   = XML::Compile::Schema->new( <<__SCHEMA );
<schema xmlns="$SchemaNS">
<element name="test1">
  <complexType>
    <sequence>
      <element name="t1e1" type="int"/>
      <element name="t1e2" type="int"/>
    </sequence>
  </complexType>
</element>

<element name="test2" type="int" />

</schema>
__SCHEMA

ok(defined $schema);

###
### ComplexType writer
###

my $w1   = writer_create $schema, "complexType writer", 'test1';

my $xml1 = writer_test $w1, {t1e1 => 12, t1e2 => 13};

compare_xml($xml1, <<__EXPECT);
<test1>
  <t1e1>12</t1e1>
  <t1e2>13</t1e2>
</test1>
__EXPECT

###
### SimpleType writer
###

my $w2   = writer_create $schema, "simpleType writer", 'test2';

my $xml2 = writer_test $w2, 14;

compare_xml($xml2, '<test2>14</test2>');
