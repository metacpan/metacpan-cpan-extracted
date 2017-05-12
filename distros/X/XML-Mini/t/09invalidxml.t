use Test;
use strict;
$^W = 1; # play nice with old perl

BEGIN { plan tests=> 2 }

use FileHandle;
require XML::Mini::Document;
use strict;
my $textBalancedUnavail;

my $sample = './t/sample/invalid.xml';

{
	$XML::Mini::DieOnBadXML = 0;
	ok($XML::Mini::DieOnBadXML, 0); # dumb thing to avoid a superfluous warning
	my $miniXML =  XML::Mini::Document->new();
	my $numchildren = $miniXML->fromFile($sample);

	ok($numchildren, 0);

}

