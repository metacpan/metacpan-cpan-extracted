package Venus::Range;

use 5.018;

use strict;
use warnings;

# IMPORTS

use Venus::Class 'attr', 'base', 'with';

# INHERITS

base 'Venus::Kind::Utility';

# INTEGRATES

with 'Venus::Role::Valuable';

# ATTRIBUTES

attr 'start';
attr 'stop';
attr 'step';

# BUILDERS

sub build_data {
  my ($self, $data) = @_;

  $data->{value} = [] if !$data->{value} || !ref $data->{value} || ref $data->{value} ne 'ARRAY';
  $data->{start} //= 0;
  $data->{stop} //= $#{$data->{value}};
  $data->{step} //= 1;

  return $data;
}

# METHODS

sub after {
  my ($self, $pos) = @_;

  my $tail = $#{$self->value};

  my ($start, $stop) = defined $pos && $pos < $tail ? (($pos + 1), $tail) : (-1, 0);

  return $self->parse("${start}:${stop}", $self->value)->select;
}

sub before {
  my ($self, $pos) = @_;

  my $head = 0;

  my ($start, $stop) = defined $pos && $pos > $head ? ($head, ($pos - 1)) : (-1, 0);

  return $self->parse("${start}:${stop}", $self->value)->select;
}

sub compute {
  my ($self) = @_;

  my $start = $self->start;
  my $stop = $self->stop;
  my $step = $self->step;
  my $length = $self->length;

  $start += $length if $start < 0;
  $stop += $length if defined $stop && $stop < 0;

  $stop = $length - 1 unless defined $stop;

  return [] if $start > $stop;

  $step = 1 unless $step;

  $step = $step * -1 if $step < 0;

  my $range = [];

  for (my $i = $start; $i <= $stop; $i += $step) {
    push @{$range}, $i if $i >= 0 && $i < $length;
  }

  return $range;
}

sub iterate {
  my ($self) = @_;

  my $range = $self->compute;

  my $result = [@{$self->value}[@{$range}]];

  my $i = 0;

  return sub {
    return if $i >= @{$result};
    return $result->[$i++];
  };
}

sub length {
  my ($self) = @_;

  my $length = scalar @{$self->value};

  return $length;
}

sub parse {
  my ($self, $expr, $data) = @_;

  $expr //= '';

  my ($start, $stop, $step) = (0, undef, 1);

  if ($expr =~ /^(-?\d*):(-?\d*)(?::(-?\d+))?$/) {
    $start = $1 if CORE::length($1);
    $stop = CORE::length($2) ? $2 : undef;
    $step = $3 if defined $3;
  }
  elsif ($expr =~ /^(-?\d+)$/) {
    $start = $1;
    $stop = $start;
  }

  return $self->class->new(value => $data || [], start => $start, stop => $stop, step => $step);
}

sub partition {
  my ($self, $pos) = @_;

  my $result = [[], []];

  $pos = 0 if !defined $pos;

  push @{$result->[0]}, $self->before($pos);
  push @{$result->[1]}, $self->after($pos - 1);

  return wantarray ? (@{$result}) : $result;
}

sub select {
  my ($self) = @_;

  my $range = $self->compute;

  my $result = [@{$self->value}[@{$range}]];

  return wantarray ? (@{$result}) : $result;
}

sub split {
  my ($self, $pos) = @_;

  my $result = [[], []];

  $pos = 0 if !defined $pos;

  push @{$result->[0]}, $self->before($pos);
  push @{$result->[1]}, $self->after($pos);

  return wantarray ? (@{$result}) : $result;
}

1;



=head1 NAME

Venus::Range - Range Class

=cut

=head1 ABSTRACT

Range Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Range;

  my $range = Venus::Range->new(['a'..'i']);

  # $array->parse('0:2');

  # ['a', 'b', 'c']

=cut

=head1 DESCRIPTION

This package provides methods for selecting elements from an arrayref using
range expressions. A "range expression" is a string that specifies a subset of
elements in an array or arrayref, defined by a start, stop, and an optional
step value, separated by colons. For example, the expression '1:4' will select
elements starting from index 1 to index 4 (both inclusive). The components of
the range expression are:

=over 4

=item * B<Start>: The beginning index of the selection. If this value is
negative, it counts from the end of the array, where -1 is the last element.

=item * B<Stop>: The ending index of the selection. This value is also
inclusive, meaning the element at this index will be included in the selection.
Negative values count from the end of the array.

=item * B<Step>: An optional value that specifies the interval between
selected elements. For instance, a step of 2 will select every second element.
If not provided, the default step is 1.

=back

This package uses inclusive start and stop indices, meaning both bounds are
included in the selection. This differs from some common conventions where the
stop value is exclusive. The package also gracefully handles out-of-bound
indices. If the start or stop values exceed the length of the array, they are
adjusted to fit within the valid range without causing errors. Negative indices
are also supported, allowing for easy reverse indexing from the end of the
array.

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 start

  start(number $start) (number)

The start attribute is read-write, accepts C<(number)> values, and is
optional.

I<Since C<4.15>>

=over 4

=item start example 1

  # given: synopsis

  package main;

  my $start = $range->start(0);

  # 0

=back

=over 4

=item start example 2

  # given: synopsis

  # given: example-1 start

  package main;

  $start = $range->start;

  # 0

=back

=cut

=head2 stop

  stop(number $stop) (number)

The stop attribute is read-write, accepts C<(number)> values, and is
optional.

I<Since C<4.15>>

=over 4

=item stop example 1

  # given: synopsis

  package main;

  my $stop = $range->stop(9);

  # 9

=back

=over 4

=item stop example 2

  # given: synopsis

  # given: example-1 stop

  package main;

  $stop = $range->stop;

  # 9

=back

=cut

=head2 step

  step(number $step) (number)

The step attribute is read-write, accepts C<(number)> values, and is
optional.

I<Since C<4.15>>

=over 4

=item step example 1

  # given: synopsis

  package main;

  my $step = $range->step(1);

  # 1

=back

=over 4

=item step example 2

  # given: synopsis

  # given: example-1 step

  package main;

  $step = $range->step;

  # 1

=back

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Kind::Utility>

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Venus::Role::Valuable>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 after

  after(number $index) (arrayref)

The after method selects the elements after the index provided and returns the
selection using L</select>. The selection is not inclusive.

I<Since C<4.15>>

=over 4

=item after example 1

  # given: synopsis

  package main;

  my $after = $range->after;

  # []

=back

=over 4

=item after example 2

  # given: synopsis

  package main;

  my $after = $range->after(5);

  # ['g', 'h', 'i']

=back

=cut

=head2 before

  before(number $index) (arrayref)

The before method selects the elements before the index provided and returns the
selection using L</select>. The selection is not inclusive.

I<Since C<4.15>>

=over 4

=item before example 1

  # given: synopsis

  package main;

  my $before = $range->before;

  # []

=back

=over 4

=item before example 2

  # given: synopsis

  package main;

  my $before = $range->before(5);

  # ['a'..'e']

=back

=cut

=head2 iterate

  iterate( ) (coderef)

The iterate method returns an iterator which uses L</select> to iteratively
return each element of the selection.

I<Since C<4.15>>

=over 4

=item iterate example 1

  # given: synopsis

  package main;

  my $iterate = $range->iterate;

  # sub{...}

=back

=over 4

=item iterate example 2

  package main;

  my $range = Venus::Range->parse('4:', ['a'..'i']);

  my $iterate = $range->iterate;

  # sub{...}

=back

=cut

=head2 new

  new(any @args) (Venus::Range)

The new method constructs an instance of the package.

I<Since C<4.15>>

=over 4

=item new example 1

  package main;

  use Venus::Range;

  my $range = Venus::Range->new;

  # bless(..., 'Venus::Range')

=back

=over 4

=item new example 2

  package main;

  use Venus::Range;

  my $range = Venus::Range->new(['a'..'d']);

  # bless(..., 'Venus::Range')

=back

=over 4

=item new example 3

  package main;

  use Venus::Range;

  my $range = Venus::Range->new(value => ['a'..'d']);

  # bless(..., 'Venus::Range')

=back

=cut

=head2 parse

  parse(string $expr, arrayref $data) (Venus::Range)

The parse method parses the "range expression" provided and returns a new
instance of L<Venus::Range> representing the range expression, optionally
accepting and setting the arrayref to be used as the selection source. This
method can also be used as a class method.

I<Since C<4.15>>

=over 4

=item parse example 1

  # given: synopsis

  package main;

  my $parse = $range->parse('4:');

  # bless(..., "Venus::Range")

  # $parse->start
  # 4

  # $parse->stop
  # -1

  # $parse->step
  # 1

=back

=over 4

=item parse example 2

  # given: synopsis

  package main;

  my $parse = $range->parse('0:1');

  # bless(..., "Venus::Range")

  # $parse->start
  # 0

  # $parse->stop
  # 1

  # $parse->step
  # 1

=back

=over 4

=item parse example 3

  # given: synopsis

  package main;

  my $parse = $range->parse('1:0');

  # bless(..., "Venus::Range")

  # $parse->start
  # 1

  # $parse->stop
  # 0

  # $parse->step
  # 1

=back

=over 4

=item parse example 4

  # given: synopsis

  package main;

  my $parse = $range->parse('2::2');

  # bless(..., "Venus::Range")

  # $parse->start
  # 2

  # $parse->stop
  # -1

  # $parse->step
  # 2

=back

=over 4

=item parse example 5

  # given: synopsis

  package main;

  my $parse = $range->parse(':4');

  # bless(..., "Venus::Range")

  # $parse->start
  # 0

  # $parse->stop
  # 4

  # $parse->step
  # 1

=back

=over 4

=item parse example 6

  # given: synopsis

  package main;

  my $parse = $range->parse(':4:1');

  # bless(..., "Venus::Range")

  # $parse->start
  # 0

  # $parse->stop
  # 4

  # $parse->step
  # 1

=back

=over 4

=item parse example 7

  # given: synopsis

  package main;

  my $parse = $range->parse(':-2', ['a'..'i']);

  # bless(..., "Venus::Range")

  # $parse->start
  # 0

  # $parse->stop
  # -2

  # $parse->step
  # 1

=back

=cut

=head2 partition

  partition(number $index) (tuple[arrayref, arrayref])

The partition method splits the elements into two sets of elements at the index
specific and returns a tuple of two arrayrefs. The first arrayref will include
everything L<"before"|/before> the index provided, and the second tuple will
include everything at and L<"after"|/after> the index provided.

I<Since C<4.15>>

=over 4

=item partition example 1

  # given: synopsis

  package main;

  my $partition = $range->partition;

  # [[], ['a'..'i']]

=back

=over 4

=item partition example 2

  # given: synopsis

  package main;

  my $partition = $range->partition(0);

  # [[], ['a'..'i']]

=back

=over 4

=item partition example 3

  # given: synopsis

  package main;

  my $partition = $range->partition(5);

  # [['a'..'e'], ['f'..'i']]

=back

=cut

=head2 select

  select() (arrayref)

The select method uses the start, stop, and step attributes to select elements
from the arrayref and returns the selection. Returns a list in list context.

I<Since C<4.15>>

=over 4

=item select example 1

  package main;

  use Venus::Range;

  my $range = Venus::Range->parse('4:', ['a'..'i']);

  my $select = $range->select;

  # ['e'..'i']

=back

=over 4

=item select example 2

  package main;

  use Venus::Range;

  my $range = Venus::Range->parse('0:1', ['a'..'i']);

  my $select = $range->select;

  # ['a', 'b']

=back

=over 4

=item select example 3

  package main;

  use Venus::Range;

  my $range = Venus::Range->parse('0:', ['a'..'i']);

  my $select = $range->select;

  # ['a'..'i']

=back

=over 4

=item select example 4

  package main;

  use Venus::Range;

  my $range = Venus::Range->parse(':-2', ['a'..'i']);

  my $select = $range->select;

  # ['a'..'h']

=back

=over 4

=item select example 5

  package main;

  use Venus::Range;

  my $range = Venus::Range->parse('2:8:2', ['a'..'i']);

  my $select = $range->select;

  # ['c', 'e', 'g', 'i']

=back

=cut

=head2 split

  split(number $index) (tuple[arrayref, arrayref])

The split method splits the elements into two sets of elements at the index
specific and returns a tuple of two arrayrefs. The first arrayref will include
everything L<"before"|/before> the index provided, and the second tuple will
include everything L<"after"|/after> the index provided. This operation will
always exclude the element at the index the elements are split on. See
L</partition> for an inclusive split operation.

I<Since C<4.15>>

=over 4

=item split example 1

  # given: synopsis

  package main;

  my $split = $range->split;

  # [[], ['b'..'i']]

=back

=over 4

=item split example 2

  # given: synopsis

  package main;

  my $split = $range->split(0);

  # [[], ['a'..'i']]

=back

=over 4

=item split example 3

  # given: synopsis

  package main;

  my $split = $range->split(5);

  # [['a'..'e'], ['g'..'i']]

=back

=cut

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2022, Awncorp, C<awncorp@cpan.org>.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut