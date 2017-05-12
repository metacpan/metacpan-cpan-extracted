use Test;
use strict;
$^W = 1; # play nice with old perl

BEGIN { plan tests=> 3 }


use FileHandle;
require XML::Mini::Document;
use strict;
my $textBalancedUnavail;

my $sample = './t/sample/voicexmlbbs.vxml';

{
	my $miniXML =  XML::Mini::Document->new();
	my $numchildren = $miniXML->fromFile($sample);

	ok($numchildren, 3);

	my $vxml = $miniXML->getElement('vxml');

	ok($vxml);

	my $forms = $vxml->getAllChildren('form');
	ok(scalar @{$forms}, 9);

	

}

