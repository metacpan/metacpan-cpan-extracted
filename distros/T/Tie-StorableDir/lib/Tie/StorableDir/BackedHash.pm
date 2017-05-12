package Tie::StorableDir::BackedHash;

use 5.008;
use strict;
use warnings;

use base 'Tie::ExtraHash';

sub TIEHASH {
	my ($class, $parent, $backing) = @_;
	$class = ref $class || $class;
	my $self = [$backing, $parent];
	bless $self, $class;
	return $self;
}

sub FETCH {
	my ($self, $key) = @_;
	return $self->[1]->translate($self->[0]{$key});
}

1;
