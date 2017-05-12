package Tie::Filter::Array;

use 5.008;
use strict;
use warnings;

use Tie::Filter;

our $VERSION = '1.02';

=head1 NAME

Tie::Filter::Array - Tie a facade around an array

=head1 DESCRIPTION

Don't use this package directly. Instead, see L<Tie::Filter>.

=cut

sub TIEARRAY {
	my ($class, $array, %args) = @_;
	$args{WRAP} = $array;
	return bless \%args, $class;
}

sub FETCH {
	my ($self, $index) = @_;
	Tie::Filter::_filter($$self{FETCH}, $$self{WRAP}[$index]);
}

sub STORE {
	my ($self, $index, $value) = @_;
	$$self{WRAP}[$index] = Tie::Filter::_filter($$self{STORE}, $value);
}

sub FETCHSIZE {
	my $self = shift;
	scalar(@{$$self{WRAP}});
}

sub STORESIZE {
	my ($self, $count) = @_;
	$#{$$self{WRAP}} = $count - 1;
}

# TODO (?) Detect if the wrappee is tied and call it's EXTEND if it is,
# otherwise do nothing.
sub EXTEND { }

sub EXISTS {
	my ($self, $index) = @_;
	exists $$self{WRAP}[$index];
}

sub DELETE {
	my ($self, $index) = @_;
	delete $$self{WRAP}[$index];
}

sub CLEAR {
	my $self = shift;
	@{$$self{WRAP}} = ();
}

sub PUSH {
	my $self = shift;
	push @{$$self{WRAP}}, map Tie::Filter::_filter($$self{STORE}, $_), @_;
}

sub POP {
	my $self = shift;
	Tie::Filter::_filter($$self{FETCH}, pop @{$$self{WRAP}});
}

sub SHIFT {
	my $self = shift;
	Tie::Filter::_filter($$self{FETCH}, shift @{$$self{WRAP}});
}

sub UNSHIFT {
	my $self = shift;
	unshift @{$$self{WRAP}}, map Tie::Filter::_filter($$self{STORE}, $_), @_;
}

sub SPLICE {
	my $self = shift;
	my $offset = shift;
	my $length = shift;
	map(Tie::Filter::_filter($$self{FETCH}, $_), 
		splice(@{$$self{WRAP}}, $offset, $length,
			map(Tie::Filter::_filter($$self{STORE}, $_), @_)));
}

sub UNTIE { }

sub DESTROY { }

=head1 SEE ALSO

L<perltie>, L<Tie::Filter>

=head1 AUTHOR

  Andrew Sterling Hanenkamp, <sterling@hanenkamp.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2003 Andrew Sterling Hanenkamp. All Rights Reserved. This library is
free software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut

1

