use Test;
use strict;
$^W = 1; # play nice with old perl

BEGIN { plan tests=> 4 }

use FileHandle;
require XML::Mini::Document;
use strict;


# Tests the various values passed through the parse() call

my $sample = './t/sample/vocpboxes.xml';
my $numBoxes = 20;

{
	my $miniXML =  XML::Mini::Document->new();

	my $numchildren = $miniXML->parse($sample);

	ok($numchildren, 3);

	$miniXML->init();
	if (! open(INFILE, "<$sample"))
	{
		ok(0);
	}

	$numchildren = $miniXML->parse(*INFILE);
	ok($numchildren, 3);

	$miniXML->init();
	my $fhObj = FileHandle->new();
	$fhObj->open($sample);
	$numchildren = $miniXML->parse($fhObj);
	ok($numchildren, 3);


	$miniXML->init();
	$fhObj = FileHandle->new();
	$fhObj->open("<$sample");
	my $contents = join('', $fhObj->getlines());
	$fhObj->close();
	$numchildren = $miniXML->parse($contents);
	ok($numchildren, 3);

}

