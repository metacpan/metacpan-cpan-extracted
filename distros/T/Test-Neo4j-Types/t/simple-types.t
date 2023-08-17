#!perl
use strict;
use warnings;
use lib qw(lib);

use Test::More 0.88;
use Test::Neo4j::Types;

plan tests => 5;


neo4j_node_ok 'Neo4j_Test::Node', \&Neo4j_Test::Node::new;

neo4j_relationship_ok 'Neo4j_Test::Rel', \&Neo4j_Test::Rel::new;

neo4j_path_ok 'Neo4j_Test::Path', \&Neo4j_Test::Path::new;

neo4j_point_ok 'Neo4j_Test::Point';

neo4j_datetime_ok 'Neo4j_Test::DateTime', \&Neo4j_Test::DateTime::new;


done_testing;


# These packages intentionally use slightly unusual data structures
# in order to confirm that the implementation of the testing tool
# doesn't depend on details like that.


package Neo4j_Test::Node;
sub DOES { $_[1] eq 'Neo4j::Types::Node' }

sub id { shift->[0] }
sub labels { @{shift->[1]} }
sub properties { shift->[2] }
sub get { shift->properties->{+pop} }
sub new {
	my ($class, $params) = @_;
	bless [
		$params->{id},
		$params->{labels} // [],
		$params->{properties} // {},
	], $class;
}


package Neo4j_Test::Rel;
sub DOES { $_[1] eq 'Neo4j::Types::Relationship' }

sub id { shift->[0] }
sub start_id { shift->[1] }
sub end_id { shift->[2] }
sub type { shift->[3] }
sub properties { shift->[4] }
sub get { shift->properties->{+pop} }
sub new {
	my ($class, $params) = @_;
	bless [
		$params->{id},
		$params->{start_id},
		$params->{end_id},
		$params->{type},
		$params->{properties} // {},
	], $class;
}


package Neo4j_Test::Path;
sub DOES { $_[1] eq 'Neo4j::Types::Path' }

use List::Util 1.56 'mesh';
sub elements { grep { defined } mesh $_[0]->{n}, $_[0]->{r} }
sub nodes { @{shift->{n}} }
sub relationships { @{shift->{r}} }
sub new {
	my ($class, $elements) = @_;
	my @n = grep {$_->DOES('Neo4j::Types::Node')} @$elements;
	my @r = grep {$_->DOES('Neo4j::Types::Relationship')} @$elements;
	bless { n => \@n, r => \@r }, $class;
}


package Neo4j_Test::Point;
sub DOES { $_[1] eq 'Neo4j::Types::Point' }

sub srid { shift->[1] }
sub coordinates { @{shift->[0]} }
sub new {
	my ($class, $srid, @coordinates) = @_;
	my $dim = { 4326 => 2, 4979 => 3, 7203 => 2, 9157 => 3 }->{$srid // 0};
	die "Unsupported SRID ".($srid//"") unless defined $dim;
	die "Points with SRID $srid must have $dim dimensions" if @coordinates < $dim;
	die unless defined $dim && @coordinates >= $dim;  # this alone is enough
	return bless [ [@coordinates[0 .. $dim - 1]], $srid ], $class;
}


package Neo4j_Test::DateTime;
sub DOES { $_[1] eq 'Neo4j::Types::DateTime' }

sub days { shift->[0] }
sub nanoseconds { shift->[1] }
sub seconds { shift->[2] }
sub tz_name { shift->[3] }
sub tz_offset { shift->[4] }
sub epoch { my $self = shift; ($self->days//0) * 86400 + ($self->seconds//0) }
sub type {
	my $self = shift;
	return "DATE" if ! defined $self->seconds;
	my $type = defined $self->days ? "DATETIME" : "TIME";
	my $zone = defined $self->tz_offset || defined $self->tz_name ? "ZONED" : "LOCAL";
	return "$zone $type";
}
sub new {
	my ($class, $params) = @_;
	bless [
		$params->{days},
		$params->{nanoseconds},
		$params->{seconds},
		$params->{tz_name},
		$params->{tz_offset},
	], $class;
}
