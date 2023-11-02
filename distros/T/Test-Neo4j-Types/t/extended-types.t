#!perl
use strict;
use warnings;
use lib qw(lib t/lib);

use Test::More 0.88;
use Test::Neo4j::Types;
use Neo4j_Test::Simple;

plan tests => 2;


neo4j_node_ok 'Neo4j_Test::NodeExt', \&Neo4j_Test::NodeExt::new;

neo4j_relationship_ok 'Neo4j_Test::RelExt', \&Neo4j_Test::RelExt::new;


done_testing;


# These packages implement the extended/updated requirements
# for Neo4j::Types 2.00, particularly wrt element ID.


package Neo4j_Test::NodeExt;
use parent -norequire, 'Neo4j_Test::Node';

sub element_id {
	my $self = shift;
	return $self->[3] if defined $self->[3];
	warnings::warnif 'Neo4j::Types', 'eid unavailable';
	return $self->id;
}
sub new {
	my $self = shift->SUPER::new(@_);
	push @$self, pop->{element_id};
	return $self;
}


package Neo4j_Test::RelExt;
use parent -norequire, 'Neo4j_Test::Rel';

sub element_id {
	my $self = shift;
	return $self->[5] if defined $self->[5];
	warnings::warnif 'Neo4j::Types', 'eid unavailable';
	return $self->id;
}
sub start_element_id {
	my $self = shift;
	return $self->[6] if defined $self->[6];
	warnings::warnif 'Neo4j::Types', 'start eid unavailable';
	return $self->start_id;
}
sub end_element_id {
	my $self = shift;
	return $self->[7] if defined $self->[7];
	warnings::warnif 'Neo4j::Types', 'end eid unavailable';
	return $self->end_id;
}
sub new {
	my ($class, $params) = @_;
	my $self = $class->SUPER::new($params);
	push @$self, (
		$params->{element_id},
		$params->{start_element_id},
		$params->{end_element_id},
	);
	return $self;
}
