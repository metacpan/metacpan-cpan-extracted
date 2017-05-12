use Test::Builder::Tester tests => 6;
use Test::XML::Count;

my $xml = "<foo></foo>";
my $xpath = '/foo';

test_out("not ok 1");
test_fail(+1);
xml_node_count $xml, $xpath, 0;
test_test("node count boundary check 1");

test_out("not ok 1");
test_fail(+1);
xml_node_count $xml, $xpath, 2;
test_test("node count boundary check 2");

$xml = "<foo><bar/><bar/></foo>";
$xpath = '/foo/bar';

test_out("not ok 1");
test_fail(+1);
xml_node_count $xml, $xpath, 1;
test_test("node count boundary check 3");

$xml = "<foo></foo>";
$xpath = '/foo/bar';

test_out("not ok 1");
test_fail(+1);
xml_max_nodes $xml, $xpath, -1;
test_test("Fails always when max nodes -1");

$xml = "<foo><bar/><bar/><bar/></foo>";
$xpath = '/foo/bar';

test_out("not ok 1");
test_fail(+1);
xml_max_nodes $xml, $xpath, 2;
test_test("Fails with too many nodes");

test_out("not ok 1");
test_fail(+1);
xml_min_nodes $xml, $xpath, 4;
test_test("Fails with min below threshold");
