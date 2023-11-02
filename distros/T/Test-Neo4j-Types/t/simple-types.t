#!perl
use strict;
use warnings;
use lib qw(lib t/lib);

use Test::More 0.88;
use Test::Neo4j::Types;
use Neo4j_Test::Simple;

plan tests => 7;


neo4j_node_ok 'Neo4j_Test::Node', \&Neo4j_Test::Node::new;

neo4j_relationship_ok 'Neo4j_Test::Rel', \&Neo4j_Test::Rel::new;

neo4j_path_ok 'Neo4j_Test::Path', \&Neo4j_Test::Path::new;

neo4j_point_ok 'Neo4j_Test::Point', \&Neo4j_Test::Point::new;

neo4j_datetime_ok 'Neo4j_Test::DateTime', \&Neo4j_Test::DateTime::new;

neo4j_duration_ok 'Neo4j_Test::Duration', \&Neo4j_Test::Duration::new;

neo4j_bytearray_ok 'Neo4j_Test::ByteArray', \&Neo4j_Test::ByteArray::new;


done_testing;
