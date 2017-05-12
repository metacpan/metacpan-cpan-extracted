use strict;
use warnings;

use Test::More tests => 2;

use XML::SemanticDiff;

my $diff = XML::SemanticDiff->new();

my $xml_text = <<"EOX";
<?xml version="1.0" encoding="UTF-8"?>
<root>\x{263A}</root>
EOX

my @results = eval { $diff->compare($xml_text, $xml_text) };

# TEST
is ($@, q{}, "No exceptions were thrown");

# TEST
ok ((!@results), q{$xml_text is identical to itself});

