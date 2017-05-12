package Tie::Array::Sorted::Lazy;

use base 'Tie::Array';

use strict;
use warnings;

=head1 NAME

Tie::Array::Sorted::Lazy - An array which is kept sorted

=head1 SYNOPSIS

	use Tie::Array::Sorted::Lazy;

	tie @a, "Tie::Array::Sorted::Lazy", sub { $_[0] <=> $_[1] };

	push @a, 10, 4, 7, 3, 4;
	print "@a"; # "3 4 4 7 10"

=head1 DESCRIPTION

This is a version Tie::Array::Sorted optimised for arrays which are
stored to more often than fetching. In this case the array is resorted
on retrieval, rather than insertion. (It only re-sorts if data has been
modified since the last sort).

	tie @a, "Tie::Array::Sorted::Lazy", sub { -s $_[0] <=> -s $_[1] };

=cut

sub TIEARRAY {
	my ($class, $comparator) = @_;
	bless {
		array => [],
		comp  => (defined $comparator ? $comparator : sub { $_[0] cmp $_[1] })
	}, $class;
}

sub STORE {
	my ($self, $index, $elem) = @_;
	splice @{ $self->{array} }, $index, 0;
	$self->PUSH($elem);
}

sub PUSH {
	my $self = shift;
	$self->{dirty} = 1;
	push @{ $self->{array} }, @_;
}

sub UNSHIFT {
	my $self = shift;
	$self->{dirty} = 1;
	push @{ $self->{array} }, @_;
}

sub _fixup {
	my $self = shift;
	$self->{array} = [ sort { $self->{comp}->($a, $b) } @{ $self->{array} } ];
	$self->{dirty} = 0;
}

sub FETCH {
	$_[0]->_fixup if $_[0]->{dirty};
	$_[0]->{array}->[ $_[1] ];
}

sub FETCHSIZE { 
	scalar @{ $_[0]->{array} } 
}

sub STORESIZE {
	$_[0]->_fixup if $_[0]->{dirty};
	$#{ $_[0]->{array} } = $_[1] - 1;
}

sub POP {
	$_[0]->_fixup if $_[0]->{dirty};
	pop(@{ $_[0]->{array} });
}

sub SHIFT {
	$_[0]->_fixup if $_[0]->{dirty};
	shift(@{ $_[0]->{array} });
}

sub EXISTS {
	$_[0]->_fixup if $_[0]->{dirty};
	exists $_[0]->{array}->[ $_[1] ];
}

sub DELETE {
	$_[0]->_fixup if $_[0]->{dirty};
	delete $_[0]->{array}->[ $_[1] ];
}

sub CLEAR { 
	@{ $_[0]->{array} } = () 
}

1;

