#!perl
use strict;
use warnings;
use lib qw(lib);

use Test::More 0.88;
use Test::Neo4j::Types;

plan tests => 4;


# These packages extend the outdated Neo4j::Types 1.00
# default implementations just to the point where they
# can pass these tests. Changes are primarily related to
# method call context.


neo4j_node_ok 'Neo4j_Test::NodeDef', sub { bless pop, shift };

neo4j_relationship_ok 'Neo4j_Test::RelDef', sub {
	my ($class, $params) = @_;
	return bless {
		%$params,
		start => $params->{start_id},
		end   => $params->{end_id},
	}, $class;
};

neo4j_path_ok 'Neo4j_Test::PathDef', sub { bless pop, shift };

neo4j_point_ok 'Neo4j_Test::PointDef';


done_testing;


package Neo4j_Test::NodeDef;
use parent 'Neo4j::Types::Node';

sub labels {
	my @l = shift->SUPER::labels(@_);
}
sub get {
	scalar shift->SUPER::get(@_);
}


package Neo4j_Test::RelDef;
use parent 'Neo4j::Types::Relationship';

sub get {
	scalar shift->SUPER::get(@_);
}


package Neo4j_Test::PathDef;
use parent 'Neo4j::Types::Path';

sub elements {
	my @e = shift->SUPER::elements(@_);
}
sub nodes {
	my @n = shift->SUPER::nodes(@_);
}
sub relationships {
	my @r = shift->SUPER::relationships(@_);
}


package Neo4j_Test::PointDef;
use parent 'Neo4j::Types::Point';

sub coordinates {
	my @c = shift->SUPER::coordinates(@_);
}
