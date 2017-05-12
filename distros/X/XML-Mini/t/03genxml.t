use Test;
use strict;
$^W = 1; # play nice with old perl

BEGIN { plan tests=> 101 }

use XML::Mini::Document;
use strict;

my $expectedXML = 
 qq|<?xml version="1.0"?>\n|
.qq| <mycontainer>\n|
.qq|  <tag1>hola</tag1>\n|
.qq|  <tag2 stuff="bla" />\n|
.qq|  <tag3 stuff="morestuff">\n|
.qq|halo &amp; hola\n|
.qq|   <inside joke="hah" />\n|
.qq|  </tag3>\n|
.qq|  <tag4 />\n|
.qq| </mycontainer>\n|
.qq| <theoutcast />\n\n|;


{
	my $miniXMLDoc =  XML::Mini::Document->new();

	my $xmlRootNode = $miniXMLDoc->getRoot();

	ok($xmlRootNode);
	my $xmlHeader = $xmlRootNode->header('xml');
	$xmlHeader->attribute('version', '1.0');

	my $containerTag = $xmlRootNode->createChild('mycontainer');
	
	my $tag1 = $containerTag->createChild('tag1', 'hola');
	ok($tag1);

	my $tag2 = $containerTag->createChild('tag2');
	ok($tag2);
	$tag2->attribute('stuff', 'bla');

	my $orphan = $miniXMLDoc->createElement('tag3');
	ok($orphan);
	$orphan->text('halo & hola');
	$containerTag->appendChild($orphan);
	$orphan->attribute('stuff', 'morestuff');

	my $insideEl = $orphan->createChild('inside');
	$insideEl->attribute('joke', 'hah');

	my $tag4 = $containerTag->createChild('tag4');
	
	my $outsider = $xmlRootNode->createChild('theoutcast');

	my $xmlOutput = $miniXMLDoc->toString();
	ok($xmlOutput);
	
	ok($xmlOutput, $expectedXML);

	my $pathStr = '';
	my $leafChild = $tag4;
	for(my $i=0; $i<90; $i++)
	{
		$pathStr .= '/nested';
		$leafChild = $leafChild->createChild('nested');
		ok($leafChild);
	}

	$leafChild->text('--> Where Am I <--');

	$pathStr =~ s|^/(.+)$|$1|;

	my $foundElement = $xmlRootNode->getElementByPath($pathStr);
	ok($foundElement);
	
	
	my $text = $foundElement->getValue();
	ok($text, '--&gt; Where Am I &lt;--');

	my $removedChild = $xmlRootNode->removeChild($outsider);
	my $newNumChildren = $xmlRootNode->numChildren();

	ok($newNumChildren, 2);

	my $prepended = $orphan->prependChild($removedChild);
	ok($prepended);

	my $retList = $orphan->removeAllChildren();
	$newNumChildren = $orphan->numChildren();


	ok($newNumChildren, 0);

}

