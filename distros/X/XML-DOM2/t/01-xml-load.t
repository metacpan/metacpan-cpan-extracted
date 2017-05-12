#!/usr/bin/perl -T -I../lib/

use Test::More tests => 12;
use strict;

BEGIN {
	use_ok( 'XML::DOM2' );
}

my $xml_data = "<xml>
  <field1 attributeA='valueA'>
    <child1 id='foo'>value1</child1>
    <child2>
      <child21 attributeB='valueB'>value2</child21>
    </child2>
    <child3>value3</child3>
    <child4>
      <list1>value41</list1>
      <list1>value42</list1>
      <list1>value43</list1>
    </child4>
  </field1>
</xml>";

my $doc = XML::DOM2->new( data => $xml_data );

my $tag1 = $doc->getElementById( 'foo' );
my $tag2 = $doc->getElementById( 'bar' );
ok( $tag1, 'Get element by Id' );
ok( (not $tag2), 'Fail to get wrong element' );

ok( $tag1->localName() eq 'child1', 'Element tag local name' );

my $sibling = $tag1->getNextSibling();

ok( $sibling, 'Get next sibling' );
ok( $sibling->localName() eq 'child2', 'Sibling tag name' );

my $child = $sibling->getFirstChild();

ok( $child, 'Get first child' );
ok( $child->localName() eq 'child21', 'Child tag name' );

my $attr = $child->getAttribute( 'attributeB' );
ok( $attr, 'Load Attribute from element' );
ok( $attr->value() eq 'valueB', 'Attribute value' );
ok( $attr eq 'valueB', 'Attribute Overloaded' );

ok( $child->cdata()->text() eq 'value2', 'Element cdata contents' );

exit 0;
