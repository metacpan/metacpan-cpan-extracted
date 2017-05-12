#!/usr/bin/perl -T -I../lib/

use Test::More tests => 2;
use strict;

BEGIN {
	use_ok( 'XML::DOM2' );
}

my $xml_data = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<xml>
  <field1 attributeA="valueA">
    <child1 id="foo">value1</child1>
    <child2>
      <child21 attributeB="valueB">value2</child21>
    </child2>
    <child3>value3</child3>
    <child4>
      <list1>value41</list1>
      <list1>value42</list1>
      <list1>value43</list1>
    </child4>
  </field1>
</xml>';

my $doc = XML::DOM2->new( data => $xml_data, nocredits => 1 );

my $new_data = $doc->xmlify();

ok( $xml_data eq $new_data, "XML Generated is same as input" );

exit 0;
