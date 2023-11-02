use strict;
use warnings;


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

sub elements {
	grep { defined }
	map { ( $_[0]->{n}[$_], $_[0]->{r}[$_] ) }
	( 0 .. @{$_[0]->{n}} - 1 )
}
sub nodes { @{shift->{n}} }
sub relationships { @{shift->{r}} }
sub new {
	my ($class, $params) = @_;
	my $elements = $params->{elements};
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


package Neo4j_Test::ByteArray;
sub DOES { $_[1] eq 'Neo4j::Types::ByteArray' }

sub as_string {
	my $bytes = shift->[0];
	utf8::encode $bytes if utf8::is_utf8 $bytes;
	return $bytes;
}
sub new {
	my ($class, $params) = @_;
	bless [ $params->{as_string} ], $class;
}


package Neo4j_Test::Simple;
1;
