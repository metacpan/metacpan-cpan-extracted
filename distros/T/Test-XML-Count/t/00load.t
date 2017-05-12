use Test::More tests => 4;

use_ok('Test::XML::Count');
can_ok('main', 'xml_node_count');
can_ok('main', 'xml_max_nodes');
can_ok('main', 'xml_min_nodes');
