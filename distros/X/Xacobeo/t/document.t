#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 53;
use Test::Exception;
use Data::Dumper;
use Carp;

BEGIN {
	use_ok('Xacobeo::Document');
}

use XML::LibXML qw(XML_XML_NS);

my $FOLDER = "tests";
my @XML_NS = (XML_XML_NS() => 'xml');
my $LibXML_VERSION = XML::LibXML::LIBXML_RUNTIME_VERSION;


exit main() unless caller;


sub main {
	test_without_namespaces();
	
	test_namespaces1();
	test_namespaces2();
	test_namespaces3();
	test_namespaces4();
	test_namespaces5();

	test_empty_document();
	test_empty_pi_document();
	
	return 0;
}


sub test_without_namespaces {
	my $document = Xacobeo::Document->new_from_file("$FOLDER/xorg.xml", 'xml');
	isa_ok($document, 'Xacobeo::Document');
	
	is_deeply(
		$document->namespaces(),
		{@XML_NS},
		'Document without namespaces'
	);
	
	my $got;
	

	# Look for a non existing node
	$got = $document->find('//x');
	is_deeply(
		$got->size,
		0,
		'Nodes from a non existing element'
	);


	# Find an existing node set
	$got = $document->find('//description[@xml:lang="es"]');
	is($got->size, 461, 'A lot of nodes');
	
	my $regex_invalid;
	my $regex_ns;
	my $regex_syntax;
	my $regex_func;

	if ($LibXML_VERSION >= 20703) {
		$regex_invalid = qr/^XPath error : Invalid expression/;
		$regex_ns      = qr/^XPath error : Undefined namespace prefix/;
		$regex_syntax  = qr/^XPath error : Invalid predicate/;
		$regex_func    = qr/^ error : xmlXPathCompOpEval: function aaa not found\nXPath error : Unregistered function/;
	}
	elsif ($LibXML_VERSION >= 20632) {
		$regex_invalid = qr/^XPath error : Invalid expression/;
		$regex_ns      = qr/^ error : xmlXPathCompiledEval: evaluation failed/;
		$regex_syntax  = qr/^XPath error : Invalid predicate/;
		$regex_func    = qr/^XPath error : Unregistered function/;
	}
	else {
		$regex_invalid = qr/^Invalid expression/;
		$regex_ns      = qr/^Undefined namespace prefix\nxmlXPathCompiledEval: evaluation failed/;
		$regex_syntax  = qr/^Invalid predicate/;
		$regex_func    = qr/^xmlXPathCompOpEval: function aaa not found/;
	}

	# Test that an invalid xpath expression throws an error
	throws_ok
		{$document->find('//x/')}
		$regex_invalid,
		q(throws 'Invalid expression');

	# Fails because the namespace doesn't exist
	throws_ok
		{$document->find('/x:html//x:a[@href]')}
		$regex_ns,
		q(throws 'Undefined namespace');
	
	# Fails because the syntax is invalid
	throws_ok
		{$document->find('/html//a[@href')}
		$regex_syntax,
		q(throws 'Invalid predicate');
	
	# Fails because the function aaa() is not defined
	throws_ok
		{$document->find('aaa(1)')}
		$regex_func,
		q(throws 'Unregistered function/function not found');

	
	# This is fine
	$got = $document->validate('/xkbConfigRegistry');
	ok($got, 'Validate XPath query');
}



sub test_namespaces1 {
	my $document = Xacobeo::Document->new_from_file("$FOLDER/SVG.svg", 'xml');
	isa_ok($document, 'Xacobeo::Document');
	
	is_deeply(
		$document->namespaces(),
		{
			'http://purl.org/dc/elements/1.1/'                   => 'dc',
			'http://web.resource.org/cc/'                        => 'cc',
			'http://www.w3.org/1999/02/22-rdf-syntax-ns#'        => 'rdf',
			'http://www.inkscape.org/namespaces/inkscape'        => 'inkscape',
			'http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd' => 'sodipodi',
			'http://www.w3.org/1999/xlink'                       => 'xlink',
			'http://www.w3.org/2000/svg'                         => 'ns',
			@XML_NS,
		},
		'SVG namespaces'
	);
	
	my $got;
	
	# Find a existing node set
	$got = $document->find('//ns:text');
	is($got->size, 12, 'Count for SVG text elements');


	# Get some text strings
	$got = $document->find('//ns:text/ns:tspan/text()');
	is_deeply(
		[ map { $_->nodeValue } $got->get_nodelist ],
		[
			'<svg version="1.0" xml>',
			'<defs>',
			'<use xlink:href="#box_gr',
			'<use xlink:href="#circle',
			'<!--add more content-->',
			'<linearGradient x1="99.7"',
			'<?xml version="1.0"en>',
			'</defs>',
			'<circle cx1="90" r="4" ',
			'</svg>',
			'<use xlink:href="#circle',
			'<line x1="100" y1="300"',
		],
		'Reading SVG text elements'
	);

	
	# Mix various namespaces
	$got = $document->find('//ns:svg/ns:metadata/rdf:RDF/cc:Work/dc:type');
	is_deeply(
		[ map { $_->toString } $got->get_nodelist ],
		[
			'<dc:type id="type87" rdf:resource="http://purl.org/dc/dcmitype/StillImage"/>',
		],
		'Mixing namespaces in SVG'
	);
}


sub test_namespaces2 {
	my $document = Xacobeo::Document->new_from_file("$FOLDER/beers.xml", 'xml');
	isa_ok($document, 'Xacobeo::Document');

	is_deeply(
		$document->namespaces(),
		{
			'http://www.w3.org/1999/xhtml' => 'ns',
			@XML_NS,
		},
		'Beers namespaces'
	);
	
	my $got;
	
	# Find the table header
	$got = $document->find('//ns:th/ns:td[count(.//node()) = 1]/text()');
	is_deeply(
		[ map { $_->data } $got->get_nodelist ],
		[ qw(Name Origin Description) ],
		'Got the table header'
	);


	# Try to find all nodes in the default namespace
	$got = $document->find('//ns:*');
	is($got->size, 9, "Got 9 in the default namespace");
}


sub test_namespaces3 {
	my $document = Xacobeo::Document->new_from_file("$FOLDER/stocks.xml", 'xml');
	isa_ok($document, 'Xacobeo::Document');

	is_deeply(
		$document->namespaces(),
		{
			'urn:schemas-microsoft-com:office:excel' => 'x',
			'http://www.w3.org/TR/REC-html40' => 'html',
			'urn:schemas-microsoft-com:office:office' => 'o',
			'urn:schemas-microsoft-com:office:spreadsheet' => 'ss',
			@XML_NS,
		},
		"Extract 'stocks.xml' namespaces"
	);
}


sub test_namespaces4 {
	my $document = Xacobeo::Document->new_from_file("$FOLDER/sample.xml", 'xml');
	isa_ok($document, 'Xacobeo::Document');

	is_deeply(
		$document->namespaces(),
		{
			'urn:x-is-simple' => 'x',
			'urn:m&#38;n'     => 'ns',
			@XML_NS,
		},
		"Extract 'sample.xml' namespaces"
	);
	
	my $got;
	
	# Find some stuff
	$got = $document->find('//*');
	is($got->size, 11, "Find all elements");
	
	$got = $document->find('//ns:*');
	is($got->size, 1, "Find all elements in the default namespace");
	is($got->[0]->nodeName, 'no-content');
	
	$got = $document->find('//x:*');
	is($got->size, 1, "Find all elements in the namespace 'x'");
	is($got->[0]->nodeName, 'x:div');
}


sub test_namespaces5 {
	my $document = Xacobeo::Document->new_from_file("$FOLDER/namespaces.xml", 'xml');
	isa_ok($document, 'Xacobeo::Document');

	is_deeply(
		$document->namespaces(),
		{
			'http://www.example.org/a' => 'a',
			'http://www.example.org/b' => 'b',
			'http://www.example.org/c' => 'c',
			'http://www.example.org/x' => 'ns',
			'http://www.example.org/y' => 'ns1',
			@XML_NS,
		},
		"Extract 'namespaces.xml' namespaces"
	);
	
	my $got;
	
	# Find some stuff
	$got = $document->find('//*');
	is($got->size, 17, "Find all elements");
	
	$got = $document->find('//a:*');
	is($got->size, 5, "Find all elements in the namespace 'a'");
	is_deeply(
		[ map { $_->nodeName }  $got->get_nodelist ],
		[ qw(a:p a:span c:div g4 a:p) ],
		"Match element names for namespace 'a'"
	);
	
	$got = $document->find('//b:*');
	is($got->size, 1, "Find all elements in the namespace 'b'");
	is($got->[0]->nodeName, 'b:i');
	
	$got = $document->find('//c:tag');
	is($got->size, 1, "Find all elements in the namespace 'c'");
	is($got->[0]->nodeName, 'c:tag');
	
	$got = $document->find('//ns:*');
	is($got->size, 2, "Find all elements in the 1st default namespace");
	is($got->[0]->nodeName, 'g1');
	
	$got = $document->find('//ns1:*');
	is($got->size, 2, "Find all elements in the 2nd default namespace");
	is_deeply(
		[ map { $_->nodeName }  $got->get_nodelist ],
		[ qw(g2 b) ],
		"Match element names for namespace 'ns1'"
	);
}


# Reads an empty file (there's no document)
sub test_empty_document {
	my $document = Xacobeo::Document->new_from_file("$FOLDER/empty.xml", 'xml');
	isa_ok($document, 'Xacobeo::Document');
	
	is_deeply(
		$document->namespaces(),
		{@XML_NS},
		'Document without namespaces'
	);
	
	
	# libxml 2.7.3 returns XML::LibXML::Document for empty documents
	if ($document->documentNode) {
		cmp_ok($LibXML_VERSION, '>=', 20703, 'libxml 2.7.3 or greater');
		isa_ok($document->documentNode, 'XML::LibXML::Document', 'there is a document');
		is($document->documentNode->hasChildNodes, 0, 'no child nodes');
	}
	else {
		is($document->documentNode, undef, 'there is no node');
		throws_ok
			{$document->find('/')}
			qr/^Document node is missing/,
			q(throws 'Document node is missing');
		throws_ok
			{$document->find('42')}
			qr/^Document node is missing/,
			q(again throws 'Document node is missing');
	}
}


# Reads a document that has only the XML PI (Document without root element)
sub test_empty_pi_document {
	my $document = Xacobeo::Document->new_from_file("$FOLDER/empty-pi.xml", 'xml');
	isa_ok($document, 'Xacobeo::Document');
	
	is_deeply(
		$document->namespaces(),
		{@XML_NS},
		'Document without namespaces'
	);

	
	isa_ok($document->documentNode, 'XML::LibXML::Document', "Parsed an XML document");
	is($document->documentNode->getDocumentElement, undef);

	my $list = $document->find('/');
	is($list->size, 1);
	my $root = $list->get_node(0);
	
	isa_ok($root, 'XML::LibXML::Document');
	my @child = $root->childNodes;
	is(scalar(@child), 0);
}
