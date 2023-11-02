#!perl
use strict;
use warnings;
use lib qw(lib t/lib);

use Test::More 0.88;
use Test::Neo4j::Types;
use Neo4j_Test::Simple;

plan tests => 7;


# Verify that the test tools accept a custom test name
# without throwing an exception. (Not sure how to verify
# that the name is in fact used for the test.)


neo4j_node_ok 'Neo4j_Test::Node', \&Neo4j_Test::Node::new, 'n';

neo4j_relationship_ok 'Neo4j_Test::Rel', \&Neo4j_Test::Rel::new, 'r';

neo4j_path_ok 'Neo4j_Test::Path', \&Neo4j_Test::Path::new, 'p';

neo4j_point_ok 'Neo4j_Test::Point', \&Neo4j_Test::Point::new, 'sp';

neo4j_datetime_ok 'Neo4j_Test::DateTime', \&Neo4j_Test::DateTime::new, 'ti';

neo4j_duration_ok 'Neo4j_Test::Duration', \&Neo4j_Test::Duration::new, 'td';

neo4j_bytearray_ok 'Neo4j_Test::ByteArray', \&Neo4j_Test::ByteArray::new, 'ba';


done_testing;
