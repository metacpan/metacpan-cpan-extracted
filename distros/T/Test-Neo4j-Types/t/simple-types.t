#!perl
use strict;
use warnings;
use lib qw(lib);

use Test::More 0.88;
use Test::Neo4j::Types;

plan tests => 6;


neo4j_node_ok 'Neo4j_Test::Node', \&Neo4j_Test::Node::new;

neo4j_relationship_ok 'Neo4j_Test::Rel', \&Neo4j_Test::Rel::new;

neo4j_path_ok 'Neo4j_Test::Path', \&Neo4j_Test::Path::new;

neo4j_point_ok 'Neo4j_Test::Point', \&Neo4j_Test::Point::new;

neo4j_datetime_ok 'Neo4j_Test::DateTime', \&Neo4j_Test::DateTime::new;

neo4j_duration_ok 'Neo4j_Test::Duration', \&Neo4j_Test::Duration::new;


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
	my ($class, $params) = @_;
	bless [
		$params->{coordinates},
		$params->{srid},
	], $class;
}


package Neo4j_Test::DateTime;
sub DOES { $_[1] eq 'Neo4j::Types::DateTime' }

sub days { shift->[0] }
sub nanoseconds { shift->[1] }
sub seconds { shift->[2] }
sub tz_offset { shift->[4] }
sub tz_name {
	my $self = shift;
	if (! defined $self->[3] && defined $self->[4] && $self->[4] % 3600 == 0) {
		return 'Etc/GMT' if $self->[4] == 0;
		return sprintf 'Etc/GMT%+i', $self->[4] / -3600
			if $self->[4] <= 14*3600 && $self->[4] >= -12*3600;
	}
	return $self->[3];
}
sub epoch { my $self = shift; ($self->days//0) * 86400 + ($self->seconds//0) }
sub type {
	my $self = shift;
	my $days      = defined $self->days;
	my $seconds   = defined $self->seconds;
	my $tz_offset = defined $self->tz_offset;
	my $tz_name   = defined $self->tz_name;
	return 'DATE'
		if   $days && ! $seconds && ! $tz_offset && ! $tz_name;
	return 'LOCAL TIME'
		if ! $days &&   $seconds && ! $tz_offset && ! $tz_name;
	return 'ZONED TIME'
		if ! $days &&   $seconds &&   $tz_offset;
	return 'LOCAL DATETIME'
		if   $days &&   $seconds && ! $tz_offset && ! $tz_name;
	return 'ZONED DATETIME'
		if   $days &&   $seconds &&   ($tz_offset || $tz_name);
	die 'Type inconsistent';
}
sub new {
	my ($class, $params) = @_;
	bless [
		$params->{days},
		$params->{nanoseconds} // (defined $params->{seconds} ? 0 : undef),
		$params->{seconds} // (defined $params->{nanoseconds} ? 0 : undef),
		$params->{tz_name},
		$params->{tz_offset},
	], $class;
}


package Neo4j_Test::Duration;
sub DOES { $_[1] eq 'Neo4j::Types::Duration' }

sub months { shift->[0] }
sub days { shift->[1] }
sub seconds { shift->[2] }
sub nanoseconds { shift->[3] }
sub new {
	my ($class, $params) = @_;
	bless [
		$params->{months} // 0,
		$params->{days} // 0,
		$params->{seconds} // 0,
		$params->{nanoseconds} // 0,
	], $class;
}
