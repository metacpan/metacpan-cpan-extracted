#!/use/bin/perl -w

use strict;
use Test::More;
BEGIN {
	my $add = 0;
	eval {require Test::NoWarnings;Test::NoWarnings->import; ++$add; 1 }
		or diag "Test::NoWarnings missed, skipping no warnings test";
	plan tests => @{[ <t/reports/*> ]} + $add;
}

use XML::Fast 'xml2hash';

for (<t/reports/*>) {
	diag "testing file $_";
	my $xml = do { local $/; open my $f,'<',$_; <$f> };
	my $xx = XML::Fast::xml2hash($xml);
	ok ref $xx, "success $_";
}
