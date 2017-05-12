use strict;
use warnings;

use Test::More tests => 2;

use XML::SemanticDiff;

my $xml1 = <<'EOX';
<?xml version="1.0"?>
<root>
<el1 el1attr="good"/>
<el2 el2attr="good">Some Text</el2>
<el3/>
</root>
EOX

my $xml2 = <<'EOX';
<?xml version="1.0"?>
<root>
<el1 el1attr="bad"/>
<el2 bogus="true"/>
<el4>Rogue</el4>
</root>
EOX

my $diff = XML::SemanticDiff->new();

my @results = $diff->compare($xml1, $xml2);

# TEST
is (scalar(@results), 6,
    "Number of results in comparing two different XML texts"
);

@results = $diff->compare($xml1, $xml1);

# TEST
ok ((!@results), "Identical XMLs generate identical results");

