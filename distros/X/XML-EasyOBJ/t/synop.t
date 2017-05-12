
use strict;
use Test;
use XML::EasyOBJ;
use FindBin qw/$Bin/;

BEGIN { plan tests => 9 }

ok( my $doc = XML::EasyOBJ->new("$Bin/read.xml") );
ok( my $doc2 = XML::EasyOBJ->new(-type => 'file', -param => "$Bin/read.xml") );

ok( my $doc3 = XML::EasyOBJ->new(-type => 'new', -param => 'root_tag') );

# write to document
$doc3->an_element->setString('some string');
$doc3->an_element->addString('some string');
ok( $doc3->an_element->getString, 'some stringsome string' );

$doc3->an_element->setAttr('attrname', 'val');
ok( $doc3->an_element->getAttr('attrname'), 'val' );

# access elements with non-name chars and the underlying DOM
my $element = $doc3->getElement('foo-bar')->getElement('bar-none');
$element->setString('test1234');
ok( $doc3->getElement('foo-bar')->getElement('bar-none')->getString, 'test1234' );

# remove elements/attrs
$doc3->remElement('foo-bar', 0);
ok( ! $doc3->getElement('foo-bar')->getElement('bar-none')->getString );
$doc3->an_element->remAttr('attrname');
ok( $doc3->an_element->getAttr('attrname'), '' );

# remap builtin methods
$doc3->remapMethod('getString', 's');
ok( $doc3->an_element->s, 'some stringsome string' );
