use Test;
use strict;
$^W = 1; # play nice with old perl

BEGIN { plan tests=> 3 }

use FileHandle;
require XML::Mini::Document;
use strict;
my $textBalancedUnavail;

my $sample = './t/sample/xnested.xml';

{
eval "use Text::Balanced";
if ($@)
{
	$textBalancedUnavail = 'Text::Balanced unavailable. Cross-nested XML *will* fail.';
}
	# Text::Balanced is unavailable
	$XML::Mini::AutoEscapeEntities = 0;
	ok($XML::Mini::AutoEscapeEntities, 0); # avoid warning
	my $miniXML =  XML::Mini::Document->new();

	my $numchildren = $miniXML->fromFile($sample);

	skip($textBalancedUnavail, $numchildren, 4);
	my $inputFileHandle = FileHandle->new();
	unless ($inputFileHandle->open("<$sample"))
	{
		ok(0);
	}

	my $sampleFile = join('', $inputFileHandle->getlines());
	$inputFileHandle->close();

	my $xmlOut = $miniXML->toString();
	

	skip($textBalancedUnavail, $sampleFile, $xmlOut);

}

