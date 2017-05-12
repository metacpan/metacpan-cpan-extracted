use Test;
BEGIN { plan tests => 1 }

use XML::SemanticDiff;

my $diff = XML::SemanticDiff->new();

my $xml1 = qq*<?xml version="1.0"?>
<root>
<el1 el1attr="good"/>
<el2>Some Text</el2>
</root>
*;

my $foo = $diff->read_xml($xml1);

ok($foo);
