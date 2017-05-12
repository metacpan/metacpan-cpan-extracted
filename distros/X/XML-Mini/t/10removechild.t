use Test;
use strict;
$^W = 1; # play nice with old perl

BEGIN { plan tests=> 4 }

use FileHandle;

require XML::Mini::Document;
use strict;

my $sample = './t/sample/vocpboxes.xml';
my $numBoxes = 20;

my $resultAfterDeletes = qq|<box number="001">
 <owner>root</owner>
 <branch>0=998,1=011,2=012</branch>
</box>
|;
{
	my $miniXML =  XML::Mini::Document->new();

	my $numchildren = $miniXML->fromFile($sample);

	ok($numchildren, 3);

	my $vocpBoxList = $miniXML->getElementByPath('VOCPBoxConfig/boxList') || ok(0);
	ok(1);
	

	$numchildren = $vocpBoxList->numChildren();

	ok($numchildren, $numBoxes);

	my $firstBox = $vocpBoxList->getElement('box');
	$firstBox->removeChild('message');

	my $testtag = $firstBox->getElement('testtag');
	$firstBox->removeChild($testtag);

	ok($firstBox->toString(), $resultAfterDeletes);


	
}

