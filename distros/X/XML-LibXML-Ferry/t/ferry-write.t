#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
#use Test::Deep;

use XML::LibXML;
use XML::LibXML::Ferry;

plan tests => 15;

my $doc = XML::LibXML::Document->new('1.0', 'UTF-8');
my $root = $doc->createElement('Root');
$doc->setDocumentElement($root);

# XML::LibXML::Element::attr()
#

$root->attr(
	foo => 'This is foo',
	bar => 'This is bar',
);
$root->attr(bar => 'This is really bar');

is($root->{foo}, 'This is foo', 'Normal attribute can be set');
is($root->{bar}, 'This is really bar', 'Overwritten attributes can be set');


# XML::LibXML::Element::create()
#

my $empty = $root->create('OutsiderEmpty');
my $emptyWithAttr = $root->create('OutsiderAttrs', undef, foo => 'bar', baz => undef);
my $emptyFull = $root->create('OutsiderFull', 'This is content', url => 'https://example.com/');

isa_ok($empty, 'XML::LibXML::Element', 'Created empty element');
is($empty->ownerDocument, $doc, 'Created empty element within document');

isa_ok($emptyWithAttr, 'XML::LibXML::Element', 'Created empty element with attributes');
is($emptyWithAttr->ownerDocument, $doc, 'Created empty element with attributes within document');
is($emptyWithAttr->{foo}, 'bar', 'Created empty element with attributes that can be read back');
ok(!exists($emptyWithAttr->{baz}));

isa_ok($emptyFull, 'XML::LibXML::Element', 'Created full element');
is($emptyFull->ownerDocument, $doc, 'Created full element within document');
is($emptyFull->textContent, 'This is content', 'Created full element that can be read back');


# XML::LibXML::Element::add()
#

$root->add('FirstChild', 'First child content', fcFOO => 'fcBAR')
	->add('SecondChild', 'Second child content', scFOO => 'scBAR')
	->add($emptyFull)
;
my $fc = $root->childNodes->[0];
is($fc->nodeName, 'FirstChild', 'Added child to root node');
my $sc = $fc->getElementsByTagName('SecondChild')->[0];
is($sc->nodeName, 'SecondChild', 'Added a deep child');
my $ec = $sc->getElementsByTagName('OutsiderFull')->[0];
is($ec->textContent, 'This is content', 'Added a very deep child');
is($ec->{url}, 'https://example.com/', 'Very deep child has its attributes');

