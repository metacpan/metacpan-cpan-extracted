#!/use/bin/perl -w

use strict;
use Test::More;
BEGIN {
	plan tests => 0+@{[ <t/badxml/*> ]};
}

use XML::Fast 'xml2hash';

for (<t/badxml/*>) {
	diag "testing file $_";
	my $xml = do { local $/; open my $f,'<',$_; <$f> };
	local $SIG{__WARN__} = sub {};
	my $xx = XML::Fast::xml2hash($xml);
	ok ref $xx, "success $_";
}

exit;
require Test::NoWarnings;