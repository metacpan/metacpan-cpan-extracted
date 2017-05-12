package Tie::StorableDir::BackedArray;

use 5.008;
use strict;
use warnings;

use base 'Tie::Array';

sub TIEARRAY {
	my ($class, $parent, $backing) = @_;
	$class = ref $class || $class;
	my $self = [$backing, $parent];
	bless $self, $class;
	return $self;
}

sub FETCH {
	my ($self, $index) = @_;
	return $self->[1]->translate($self->[0][$index]);
}

sub FETCHSIZE {
	my ($self) = @_;
	return scalar @{$self->[0]};
}

sub STORE {
	my ($self, $index, $value) = @_;
	$self->[0][$index] = $value;
}

sub STORESIZE {
	my ($self, $size) = @_;
	@{$self->[0]} = $size;
}

sub EXISTS {
	my ($self, $index) = @_;
	return exists $self->[0][$index];
}

sub DELETE {
	my ($self, $index) = @_;
	delete $self->[0][$index];
}

sub CLEAR {
	my ($self) = @_;
	@{$self->[0]} = ();
}

sub PUSH {
	my ($self, @v) = @_;
	push @{$self->[0]}, @v;
}

sub POP {
	my $self = shift;
	return $self->[1]->translate(pop @{$self->[0]});
}

sub SHIFT {
	my $self = shift;
	return $self->[1]->translate(shift @{$self->[0]});
}

sub UNSHIFT {
	my ($self, @v) = @_;
	unshift @{$self->[0]}, @v;
}

sub SPLICE {
	my ($this, $offset, $length, @l) = @_;
	my @v = splice @{$this->[0]}, $offset, $length, @l;
	@v = map { $this->[1]->translate($_) } @v;
	return @v;
}

1;
