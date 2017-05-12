package Tie::StorableDir::Slot;

use 5.008;
use strict;
use warnings;
use Tie::StorableDir::BackedHash;
use Tie::StorableDir::BackedArray;
use Tie::StorableDir::BackedScalar;
use Carp;

# This is an internal class, representing one value out of a key/value
# entry in the root hash. It is used to write back data to the filesystem
# once it has been modified.
# Copyright (C) 2005 by Bryan Donlan
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.8.5 or,
# at your option, any later version of Perl 5 you may have available.

sub new {
	my ($class, $key, $value, $parent) = @_;
	$class = ref $class || $class;
	my $self = {
		key => $key,
		value => $value,
		parent => $parent,
	};
	bless $self, $class;
	return $self;
}

sub getvalue {
	return $_[0]->translate($_[0]->{value});
}

sub getkey {
	return $_[0]->{key};
}

sub disconnect {
	delete $_[0]->{parent};
}

sub translate {
	my ($self, $thing) = @_;
	my $newthing;
	return $thing unless ref $thing;
	return $thing unless $self->{parent};
	if (UNIVERSAL::isa($thing, 'HASH')) {
		$newthing = {};
		tie %$newthing, 'Tie::StorableDir::BackedHash', $self, $thing;
	} elsif (UNIVERSAL::isa($thing, 'ARRAY')) {
		$newthing = [];
		tie @$newthing, 'Tie::StorableDir::BackedArray', $self, $thing;
	} elsif (UNIVERSAL::isa($thing, 'SCALAR')) {
		my $temp = undef;
		$newthing = \$temp;
		tie $temp, 'Tie::StorableDir::BackedScalar', $self, $thing;
	} else {
		carp "Can't tie type: ".ref($thing);
		$newthing = $thing;
	}
	return $newthing;
}

sub writeback {
	my $self = $_[0];
	if (defined $self->{parent}) {
		$self->{parent}->STORE($self->{key}, $self->{value});
	}
}

sub DESTROY {
	$_[0]->writeback;
}

1;
