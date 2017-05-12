use Test::XML::Count tests => 6;

my $xml = "<foo></foo>";
my $xpath = '/foo';
my $count = 1;

xml_node_count $xml, $xpath, $count;

$xml = "<foo><bar/><bar/></foo>";
$xpath = '/foo/bar';
$count = 2;

xml_node_count $xml, $xpath, $count;

my $xml2 = "<foo><b /><b /><b /></foo>";

xml_node_count $xml2, '/foo', 1;
xml_node_count $xml2, '/foo/b', 3;

# do these quick
xml_min_nodes $xml2, '/foo', 1;
xml_max_nodes $xml2, '/foo/b', 3;
