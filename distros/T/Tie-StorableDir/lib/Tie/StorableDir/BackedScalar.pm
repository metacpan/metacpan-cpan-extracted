package Tie::StorableDir::BackedScalar;

use 5.008;
use strict;
use warnings;

use base 'Tie::Scalar';

sub TIESCALAR {
	my ($class, $parent, $backing) = @_;
	$class = ref $class || $class;
	my $self = [$backing, $parent];
	bless $self, $class;
	return $self;
}

sub FETCH {
	my ($self) = @_;
	return $self->[1]->translate(${$self->[0]});
}

sub STORE {
	my ($self, $value) = @_;
	$self->[0] = $value;
}

1;
