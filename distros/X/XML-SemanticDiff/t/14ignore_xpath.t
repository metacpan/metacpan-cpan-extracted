use strict;
use warnings;

use Test::More tests => 2;

use XML::SemanticDiff;

my $xml1 = <<'EOX';
<?xml version="1.0"?>
<root>
<el1 el1attr="good"/>
<el2 el2attr="good">Some Text</el2>
</root>
EOX

my $xml2 = <<'EOX';
<?xml version="1.0"?>
<root>
<el1 el1attr="good"/>
<el2 el2attr="good">Some Text</el2>
<el3/>
</root>
EOX


#TEST
{
    my $diff_simple = XML::SemanticDiff->new();
    my @results = $diff_simple->compare($xml1, $xml2);
    ok(@results, "XMLs are not identical");
}

#TEST
{
    my $diff_ignore = XML::SemanticDiff->new(ignorexpath=>["/root/el3"]);
    my @results = $diff_ignore->compare($xml1, $xml2);
    ok((!@results), "XMLs should count identical if xpath /root/el3 is excluded");
}

