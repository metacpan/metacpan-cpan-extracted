package Venus::Random;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base', 'with';

base 'Venus::Kind::Utility';

with 'Venus::Role::Valuable';
with 'Venus::Role::Buildable';
with 'Venus::Role::Accessible';

# STATE

state $ORIG_SEED = srand;
state $SELF_SEED = substr(((time ^ $$) ** 2), 0, length($ORIG_SEED));
srand $ORIG_SEED;

# BUILDERS

sub build_self {
  my ($self, $data) = @_;

  $self->reseed($self->value);

  return $self;
}

# METHODS

sub assertion {
  my ($self) = @_;

  my $assertion = $self->SUPER::assertion;

  $assertion->match('number')->format(sub{
    (ref $self || $self)->new($_)
  });

  return $assertion;
}

sub bit {
  my ($self) = @_;

  return $self->select([1, 0]);
}

sub boolean {
  my ($self) = @_;

  return $self->select([true, false]);
}

sub byte {
  my ($self) = @_;

  return chr(int($self->pick * 256));
}

sub character {
  my ($self) = @_;

  my $code = $self->select(['digit', 'letter', 'symbol']);

  return $self->$code;
}

sub collect {
  my ($self, $times, $code, @args) = @_;

  return scalar($self->repeat($times, $code, @args));
}

sub default {
  state $default = $SELF_SEED;

  return $default++;
}

sub digit {
  my ($self) = @_;

  return int($self->pick(10));
}

sub float {
  my ($self, $place, $from, $upto) = @_;

  $from //= 0;
  $upto //= $self->number;

  my $tmp; $tmp = $from and $from = $upto and $upto = $tmp if $from > $upto;

  $place //= $self->nonzero;

  return sprintf("%.${place}f", $from + rand() * ($upto - $from));
}

sub letter {
  my ($self) = @_;

  my $code = $self->select(['uppercased', 'lowercased']);

  return $self->$code;
}

sub lowercased {
  my ($self) = @_;

  return lc(chr($self->range(97, 122)));
}

sub pick {
  my ($self, $data) = @_;

  return $data ? rand($data) : rand;
}

sub nonzero {
  my ($self, $code, @args) = @_;

  $code ||= 'digit';

  my $value = $self->$code(@args);

  return
    ($value < 0 && $value > -1) ? ($value + -1)
    : (($value < 1 && $value > 0) ? ($value + 1)
    : ($value == 0 ? $self->nonzero : $value));
}

sub number {
  my ($self, $from, $upto) = @_;

  $upto //= 0;
  $from //= $self->digit;

  return $self->range($from, $upto) if $upto;

  return int($self->pick(10 ** ($from > 9 ? 9 : $from) -1));
}

sub range {
  my ($self, $from, $upto) = @_;

  return 0 if !defined $from;
  return 0 if !defined $upto && $from == 0;

  return $from if $from == $upto;

  my $ceil = 2147483647;

  $from = 0 if !$from || $from > $ceil;
  $upto = $ceil if !$upto || $upto > $ceil;

  return $from + int($self->pick(($upto-$from) + 1));
}

sub repeat {
  my ($self, $times, $code, @args) = @_;

  my @values;

  $code ||= 'digit';
  $times ||= 1;

  push @values, $self->$code(@args) for 1..$times;

  return wantarray ? (@values) : join('', @values);
}

sub reseed {
  my ($self, $seed) = @_;

  my $THIS_SEED = !$seed || $seed =~ /\D/ ? $SELF_SEED : $seed;

  $self->value($THIS_SEED);

  srand $THIS_SEED;

  return $self;
}

sub reset {
  my ($self) = @_;

  $self->reseed($SELF_SEED);

  srand $SELF_SEED;

  return $self;
}

sub restore {
  my ($self) = @_;

  $self->reseed($ORIG_SEED);

  srand $ORIG_SEED;

  return $self;
}

sub select {
  my ($self, $data) = @_;

  if (UNIVERSAL::isa($data, 'ARRAY')) {
    my $keys = @$data;
    my $rand = $self->range(0, $keys <= 0 ? 0 : $keys - 1);
    return (@$data)[$rand];
  }

  if (UNIVERSAL::isa($data, 'HASH')) {
    my $keys = keys(%$data);
    my $rand = $self->range(0, $keys <= 0 ? 0 : $keys - 1);
    return $$data{(sort keys %$data)[$rand]};
  }

  return undef;
}

sub symbol {
  my ($self) = @_;

  state $symbols = [split //, q(~!@#$%^&*\(\)-_=+[]{}\|;:'",./<>?)];

  return $self->select($symbols);
}

sub uppercased {
  my ($self) = @_;

  return uc(chr($self->range(97, 122)));
}

1;



=head1 NAME

Venus::Random - Random Class

=cut

=head1 ABSTRACT

Random Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Random;

  my $random = Venus::Random->new(42);

  # my $bit = $random->bit;

  # 1

=cut

=head1 DESCRIPTION

This package provides an object-oriented interface for Perl's pseudo-random
number generator (or PRNG) which produces a deterministic sequence of bits
which approximate true randomness.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Kind::Utility>

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Venus::Role::Accessible>

L<Venus::Role::Buildable>

L<Venus::Role::Valuable>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 bit

  bit() (number)

The bit method returns a C<1> or C<0> value, randomly.

I<Since C<1.11>>

=over 4

=item bit example 1

  # given: synopsis

  package main;

  my $bit = $random->bit;

  # 0

  # $bit = $random->bit;

  # 1

=back

=cut

=head2 boolean

  boolean() (boolean)

The boolean method returns a C<true> or C<false> value, randomly.

I<Since C<1.11>>

=over 4

=item boolean example 1

  # given: synopsis

  package main;

  my $boolean = $random->boolean;

  # 0

  # $boolean = $random->boolean;

  # 1

=back

=cut

=head2 byte

  byte() (string)

The byte method returns random byte characters, randomly.

I<Since C<1.11>>

=over 4

=item byte example 1

  # given: synopsis

  package main;

  my $byte = $random->byte;

  # "\xBE"

  # $byte = $random->byte;

  # "W"

=back

=cut

=head2 character

  character() (string)

The character method returns a random character, which is either a L</digit>,
L</letter>, or L</symbol> value.

I<Since C<1.11>>

=over 4

=item character example 1

  # given: synopsis

  package main;

  my $character = $random->character;

  # ")"

  # $character = $random->character;

  # 4

=back

=cut

=head2 collect

  collect(number $times, string | coderef $code, any @args) (number | string)

The collect method dispatches to the specified method or coderef, repeatedly
based on the number of C<$times> specified, and returns the random concatenated
results from each dispatched call. By default, if no arguments are provided,
this method dispatches to L</digit>.

I<Since C<1.11>>

=over 4

=item collect example 1

  # given: synopsis

  package main;

  my $collect = $random->collect;

  # 7

  # $collect = $random->collect;

  # 3

=back

=over 4

=item collect example 2

  # given: synopsis

  package main;

  my $collect = $random->collect(2);

  # 73

  # $collect = $random->collect(2);

  # 14

=back

=over 4

=item collect example 3

  # given: synopsis

  package main;

  my $collect = $random->collect(5, "letter");

  # "iKWMv"

  # $collect = $random->collect(5, "letter");

  # "Papmm"




=back

=over 4

=item collect example 4

  # given: synopsis

  package main;

  my $collect = $random->collect(10, "character");

  # ")48R+a}[Lb"

  # $collect = $random->collect(10, "character");

  # "?&0725^,0w"

=back

=cut

=head2 digit

  digit() (number)

The digit method returns a random digit between C<0> and C<9>.

I<Since C<1.11>>

=over 4

=item digit example 1

  # given: synopsis

  package main;

  my $digit = $random->digit;

  # 7

  # $digit = $random->digit;

  # 3

=back

=cut

=head2 float

  float(number $place, number $from, number $upto) (number)

The float method returns a random float.

I<Since C<1.11>>

=over 4

=item float example 1

  # given: synopsis

  package main;

  my $float = $random->float;

  # 1447361.5

  # $float = $random->float;

  # "0.0000"

=back

=over 4

=item float example 2

  # given: synopsis

  package main;

  my $float = $random->float(2);

  # 380690.82

  # $float = $random->float(2);

  # 694.57

=back

=over 4

=item float example 3

  # given: synopsis

  package main;

  my $float = $random->float(2, 1, 5);

  # 3.98

  # $float = $random->float(2, 1, 5);

  # 2.37

=back

=over 4

=item float example 4

  # given: synopsis

  package main;

  my $float = $random->float(3, 1, 2);

  # 1.745

  # $float = $random->float(3, 1, 2);

  # 1.343

=back

=cut

=head2 letter

  letter() (string)

The letter method returns a random letter, which is either an L</uppercased> or
L</lowercased> value.

I<Since C<1.11>>

=over 4

=item letter example 1

  # given: synopsis

  package main;

  my $letter = $random->letter;

  # "i"

  # $letter = $random->letter;

  # "K"

=back

=cut

=head2 lowercased

  lowercased() (string)

The lowercased method returns a random lowercased letter.

I<Since C<1.11>>

=over 4

=item lowercased example 1

  # given: synopsis

  package main;

  my $lowercased = $random->lowercased;

  # "t"

  # $lowercased = $random->lowercased;

  # "i"

=back

=cut

=head2 nonzero

  nonzero(string | coderef $code, any @args) (number | string)

The nonzero method dispatches to the specified method or coderef and returns
the random value ensuring that it's never zero, not even a percentage of zero.
By default, if no arguments are provided, this method dispatches to L</digit>.

I<Since C<1.11>>

=over 4

=item nonzero example 1

  # given: synopsis

  package main;

  my $nonzero = $random->nonzero;

  # 7

  # $nonzero = $random->nonzero;

  # 3

=back

=over 4

=item nonzero example 2

  # given: synopsis

  package main;

  my $nonzero = $random->nonzero("pick");

  # 1.74452500006101

  # $nonzero = $random->nonzero("pick");

  # 1.34270147871891

=back

=over 4

=item nonzero example 3

  # given: synopsis

  package main;

  my $nonzero = $random->nonzero("number");

  # 3427014

  # $nonzero = $random->nonzero("number");

  # 3

=back

=over 4

=item nonzero example 4

  # given: synopsis

  package main;

  my $nonzero = $random->nonzero("number", 0, 10);

  # 8

  # $nonzero = $random->nonzero("number", 0, 10);

  # 3

=back

=cut

=head2 number

  number(number $from, number $upto) (number)

The number method returns a random number within the range provided. If no
arguments are provided, the range is from C<0> to C<2147483647>. If only the
first argument is provided, it's treated as the desired length of the number.

I<Since C<1.11>>

=over 4

=item number example 1

  # given: synopsis

  package main;

  my $number = $random->number;

  # 3427014

  # $number = $random->number;

  # 3

=back

=over 4

=item number example 2

  # given: synopsis

  package main;

  my $number = $random->number(5, 50);

  # 39

  # $number = $random->number(5, 50);

  # 20

=back

=over 4

=item number example 3

  # given: synopsis

  package main;

  my $number = $random->number(100, 20);

  # 42

  # $number = $random->number(100, 20);

  # 73

=back

=over 4

=item number example 4

  # given: synopsis

  package main;

  my $number = $random->number(5);

  # 74451

  # $number = $random->number(5);

  # 34269

=back

=cut

=head2 pick

  pick(Num $data) (Num)

The pick method is the random number generator and returns a random number. By
default, calling this method is equivalent to call L<perlfunc/rand>. This
method can be overridden in a subclass to provide a custom generator, e.g. a
more cyptographically secure generator.

I<Since C<1.23>>

=over 4

=item pick example 1

  # given: synopsis

  package main;

  my $pick = $random->pick;

  # 0.744525000061007

  # $pick = $random->pick;

  # 0.342701478718908

=back

=over 4

=item pick example 2

  # given: synopsis

  package main;

  my $pick = $random->pick(100);

  # 74.4525000061007

  # $pick = $random->pick(100);

  # 34.2701478718908

=back

=over 4

=item pick example 3

  # given: synopsis

  package main;

  my $pick = $random->pick(2);

  # 1.48905000012201

  # $pick = $random->pick(2);

  # 0.685402957437816

=back

=cut

=head2 range

  range(string $from, string $to) (number)

The range method returns a random number within the range provided. If no
arguments are provided, the range is from C<0> to C<2147483647>.

I<Since C<1.11>>

=over 4

=item range example 1

  # given: synopsis

  package main;

  my $range = $random->range(1, 10);

  # 8

  # $range = $random->range(1, 10);

  # 4

=back

=over 4

=item range example 2

  # given: synopsis

  package main;

  my $range = $random->range(10, 1);

  # 5

  # $range = $random->range(10, 1);

  # 8

=back

=over 4

=item range example 3

  # given: synopsis

  package main;

  my $range = $random->range(0, 60);

  # 45

  # $range = $random->range(0, 60);

  # 20

=back

=over 4

=item range example 4

  # given: synopsis

  package main;

  my $range = $random->range(-5, -1);

  # -2

  # $range = $random->range(-5, -1);

  # -4

=back

=cut

=head2 repeat

  repeat(number $times, string | coderef $code, any @args) (number | string)

The repeat method dispatches to the specified method or coderef, repeatedly
based on the number of C<$times> specified, and returns the random results from
each dispatched call. In list context, the results from each call is returned
as a list, in scalar context the results are concatenated.

I<Since C<1.11>>

=over 4

=item repeat example 1

  # given: synopsis

  package main;

  my @repeat = $random->repeat(2);

  # (7, 3)

  # @repeat = $random->repeat(2);

  # (1, 4)




=back

=over 4

=item repeat example 2

  # given: synopsis

  package main;

  my @repeat = $random->repeat(2, "float");

  # (1447361.5, "0.0000")

  # @repeat = $random->repeat(2, "float");

  # ("482092.1040", 1555.7410393)




=back

=over 4

=item repeat example 3

  # given: synopsis

  package main;

  my @repeat = $random->repeat(2, "character");

  # (")", 4)

  # @repeat = $random->repeat(2, "character");

  # (8, "R")

=back

=cut

=head2 reseed

  reseed(string $seed) (Venus::Random)

The reseed method sets the L<perlfunc/srand> (i.e. the PRNG seed) to the value
provided, or the default value used on instanstiation when no seed is passed to
the constructor. This method returns the object that invoked it.

I<Since C<1.11>>

=over 4

=item reseed example 1

  # given: synopsis

  package main;

  my $reseed = $random->reseed;

  # bless({value => ...}, "Venus::Random")

  # my $bit = $random->bit;

  # 0

=back

=over 4

=item reseed example 2

  # given: synopsis

  package main;

  my $reseed = $random->reseed(42);

  # bless({value => 42}, "Venus::Random")

  # my $bit = $random->bit;

  # 0

=back

=cut

=head2 reset

  reset() (Venus::Random)

The reset method sets the L<perlfunc/srand> (i.e. the PRNG seed) to the default
value used on instanstiation when no seed is passed to the constructor. This
method returns the object that invoked it.

I<Since C<1.11>>

=over 4

=item reset example 1

  # given: synopsis

  package main;

  my $reset = $random->reset;

  # bless({value => ...}, "Venus::Random")

=back

=cut

=head2 restore

  restore() (Venus::Random)

The restore method sets the L<perlfunc/srand> (i.e. the PRNG seed) to the
original value used by L<perlfunc/rand>. This method returns the object that
invoked it.

I<Since C<1.11>>

=over 4

=item restore example 1

  # given: synopsis

  package main;

  my $restore = $random->restore;

  # bless({value => ...}, "Venus::Random")

=back

=cut

=head2 select

  select(arrayref | hashref $data) (any)

The select method returns a random value from the I<"hashref"> or I<"arrayref">
provided.

I<Since C<1.11>>

=over 4

=item select example 1

  # given: synopsis

  package main;

  my $select = $random->select(["a".."d"]);

  # "c"

  # $select = $random->select(["a".."d"]);

  # "b"

=back

=over 4

=item select example 2

  # given: synopsis

  package main;

  my $select = $random->select({"a".."h"});

  # "f"

  # $select = $random->select({"a".."h"});

  # "d"

=back

=cut

=head2 symbol

  symbol() (string)

The symbol method returns a random symbol.

I<Since C<1.11>>

=over 4

=item symbol example 1

  # given: synopsis

  package main;

  my $symbol = $random->symbol;

  # "'"

  # $symbol = $random->symbol;

  # ")"

=back

=cut

=head2 uppercased

  uppercased() (string)

The uppercased method returns a random uppercased letter.

I<Since C<1.11>>

=over 4

=item uppercased example 1

  # given: synopsis

  package main;

  my $uppercased = $random->uppercased;

  # "T"

  # $uppercased = $random->uppercased;

  # "I"

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