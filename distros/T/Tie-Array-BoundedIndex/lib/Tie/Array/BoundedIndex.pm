package Tie::Array::BoundedIndex;
use strict;
use warnings;
use Carp;

use Tie::Array;

our $VERSION = '0.06';

BEGIN
{
  $DB::single = 1;
  eval "require Attribute::Handlers";
  return if $@;
  Attribute::Handlers->import(autotie => { '__CALLER__::Bounded'
					   => __PACKAGE__ });
}

# The underlying object contains the bounds and also an
# inner object that is the result of tying an array to
# Tie::StdArray.  When the user performs an operation on
# the array tied to this class, it is passed on to the
# inner array after bounds checking and shifting the
# indices so that the inner array's indices start at 0
# and go up to <upper>-<lower>
sub TIEARRAY
{
  my ($class, %arg) = @_;
  my ($upper, $lower) = delete @arg{qw(upper lower)};
  croak "Illegal arguments in tie" if %arg;
  croak "No upper bound for array" unless defined $upper;

  $lower ||= 0;

  /\D/ and croak "Array bound '$_' must be integer" for ($upper, $lower);

  croak "Upper bound < lower bound" if $upper < $lower;

  my @array;
  my $inner = tie @array, 'Tie::StdArray';

  return bless { upper => $upper,
		 lower => $lower,
		 inner => $inner
	       }, $class;
}

# Delegate anything we haven't overridden to the inner array,
# which, being tied to Tie::StdArray, knows what to do.
# In this class we only need to implement methods that have
# to adjust an array index.
sub AUTOLOAD
{
  (my $method = our $AUTOLOAD) =~ s/.*://;
  my $self = shift;
  $self->{inner}->$method(@_);
}

sub DESTROY { }

sub _bound_check
{
  my ($self, $index) = @_;
  my ($upper, $lower) = @{$self}{qw(upper lower)};

  croak "Index $index out of range [$lower, $upper]"
    if $index < $lower || $index > $upper;

  return $lower;    # Convenience for several callers
}

# Only need to implement methods that can increase the
# size of the array or store outside the bounds.

sub STORE
{
  my ($self, $index, $value) = @_;
  my $lower = $self->_bound_check($index);
  $self->{inner}->STORE($index - $lower, $value);
}

sub FETCH
{
  my ($self, $index) = @_;
  my $lower = $self->_bound_check($index);
  $self->{inner}->FETCH($index - $lower);
}

sub STORESIZE
{
  my ($self, $size) = @_;
  $self->_bound_check($size-1);
  $self->{inner}->STORESIZE($size);
}

sub EXTEND
{
  my ($self, $newsize) = @_;

  # We may get called with a new size of 0, indicating that
  # the caller doesn't want to extend the array at all.
  # But since that would result in a bound check on
  # <lower> - 1, we return at that point since otherwise
  # we would generate an exception.  Our arrays are
  # guaranteed to have at least one elenment in them.

  return unless $newsize;
  my $lower = $self->{lower};
  $self->_bound_check($lower+$newsize-1);
}

sub PUSH
{
  my ($self, @new) = @_;
  $self->EXTEND($self->FETCHSIZE + @new);
  $self->{inner}->PUSH(@new);
}

sub UNSHIFT
{
  my ($self, @new) = @_;
  $self->EXTEND($self->FETCHSIZE + @new);
  $self->{inner}->UNSHIFT(@new);
}

sub SPLICE
{
  my $self   = shift;
  my $lower = $self->{lower};

  my $offset = shift;
  defined($offset) or $offset = $lower;

  my $size = $self->FETCHSIZE;

  $offset < 0 and $offset = $size + $lower - $offset;
  $self->_bound_check($offset);

  my $length = shift || $size - $offset + $lower;
  $length < 0 and $length = $lower + $size - $offset + $length;
  $length > $lower + $size - $offset and $length = $lower + $size - $offset;

  $self->EXTEND($size + @_ - $length);
  $self->{inner}->SPLICE($offset - $lower, $length, @_)
}


1;

__END__

=head1 NAME

Tie::Array::BoundedIndex - Bounded arrays

=head1 SYNOPSIS

  use Tie::Array::BoundedIndex;
  tie @array, "Tie::Array::BoundedIndex", upper => 100;
  tie @array, "Tie::Array::BoundedIndex", lower => 10, upper => 20;

  my @array : Bounded(upper => 20);

=head1 DESCRIPTION

C<Tie::Array::BoundedIndex> allows you to create arrays which perform
bounds checking upon their indices. A fatal exception will be thrown
upon an attempt to go outside the specified bounds.

Usage:

  tie @array, "Tie::Array::BoundedIndex",
              upper => $upper_limit [, lower => $lower_limit]

A mandatory upper limit is specified with the C<upper> keyword.
An optional lower limit is specified with the C<lower> keyword;
the default is 0.  Each specifies the limit of array indices
that may be used.  Any attempt to exceed them results in the
fatal exception "index <index> out of range [<lower>, <upper>]".

The bounds must be integers greater than or equal to zero with
the upper bound greater than or equal to the lower bound.

=head1 Use with Attribute::Handlers

Damian Conway's C<Attribute::Handlers> module provides a
nice alternative declaration syntax.  If you have it 
installed, then you can declare bounded arrays with:

  my @array : Bounded(upper => 20)

or

  my @array : Bounded(lower => 10, upper => 20)

=head1 BUGS

Slow.  But then, what were you expecting?  If you want fast
bounded arrays, submit an XS version (with tests) and I'll add it.

=head1 AUTHOR

Peter Scott, C<cpan@PSDT.com>.

This module is an expanded version of an example developed
in the book ``Perl Medic: Transforming Legacy Code''.  See
C<http://www.perlmedic.com>.

=head1 SEE ALSO

L<perltie>, L<Tie::Array>.

=cut
