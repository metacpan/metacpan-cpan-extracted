use strict;
use warnings;

use Test::More tests => 3;

use XML::SemanticDiff;

my $xml1 = <<'EOX';
<?xml version="1.0"?>
<root>
<el1 el1attr="good"/>
<el2 el2attr="good">Some Text</el2>
<el4/>
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
    my $results = $diff_simple->compare($xml1, $xml2);
    ok($results == 2, "Two differences in XMLs");
}

#TEST
{
    my $diff_ignore = XML::SemanticDiff->new(ignorexpath=>["/root/el3"]);
    my $results = $diff_ignore->compare($xml1, $xml2);
    ok($results == 1, "Only one difference if /root/el3 is excluded");
}

#TEST
{
    my $diff_multiignore = XML::SemanticDiff->new(ignorexpath=>["/root/el3", "/root/el4"]);
    my $results = $diff_multiignore->compare($xml1, $xml2);
    ok($results == 0, "XMLs should count identical if xpaths /root/el3 and /root/el4 are excluded");
}
