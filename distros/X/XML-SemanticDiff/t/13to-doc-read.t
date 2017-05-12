use strict;
use warnings;

use Test::More tests => 1;
use XML::SemanticDiff;

my $xml_text = <<'EOF';
<start>Hello <y>There</y>!</start>
EOF

my $diff = XML::SemanticDiff->new();

my $to_processed_xml = $diff->read_xml($xml_text);

my @results = $diff->compare($xml_text, $to_processed_xml);

# TEST
is_deeply(\@results, [], "Accepted the processed XML in the second argument");
