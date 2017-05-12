use Test;
use strict;
$^W = 1; # play nice with old perl

BEGIN { plan tests=> 46 }

use FileHandle;

require XML::Mini::Document;
use strict;

my $sample = './t/sample/vocpboxes.xml';
my $numBoxes = 20;

{
	my $miniXML =  XML::Mini::Document->new();

	my $numchildren = $miniXML->fromFile($sample);

	ok($numchildren, 3);

	my $vocpBoxList = $miniXML->getElementByPath('VOCPBoxConfig/boxList') || ok(0);
	ok(1);
	

	$numchildren = $vocpBoxList->numChildren();

	ok($numchildren, $numBoxes);


	my $childList = $vocpBoxList->getAllChildren();

	ok($childList);

	ok(scalar @{$childList}, $numBoxes);

	foreach my $child (@{$childList})
	{

		my $childName = $child->name();
		ok($childName, '/^box$/', "boxList child with invalid name (should be 'box')");

		my $boxnum = $child->attribute('number');

		ok($boxnum, '/\d+$/', "box with invalid number (should be all digits)");
		
	}


	my $inputFileHandle = FileHandle->new();
	unless ($inputFileHandle->open("<$sample"))
	{
		ok(0);
	}

	my $sampleFile = join('', $inputFileHandle->getlines());
	$inputFileHandle->close();

	my $xmlOut = $miniXML->toString();

	ok($xmlOut, $sampleFile);

}

