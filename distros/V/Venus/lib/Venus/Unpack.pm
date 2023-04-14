package Venus::Unpack;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base', 'with';

base 'Venus::Kind::Utility';

# BUILDERS

sub build_arg {
  my ($self, $data) = @_;

  return {
    args => ref $data eq 'ARRAY' ? $data : [$data],
  };
}

# METHODS

sub all {
  my ($self) = @_;

  $self->use(0..$#{$self->{args}});

  return $self;
}

sub arg {
  my ($self, $name) = @_;

  return $self->{args}->[$name];
}

sub args {
  my ($self, @args) = @_;

  $self->{args} = [@args] if @args;

  return wantarray ? (@{$self->{args}}) : $self->{args};
}

sub array {
  my ($self) = @_;

  require Venus::Array;

  return Venus::Array->new(scalar $self->args);
}

sub cast {
  my ($self, @args) = @_;

  require Venus::Type;

  my $code = sub {
    my ($self, $data, $into) = @_;

    my $type = Venus::Type->new($data);

    return $into ? $type->cast($into) : $type->deduce;
  };

  return $self->foreach($code, @args);
}

sub checks {
  my ($self, @args) = @_;

  require Venus::Assert;

  my $code = sub {
    my ($self, $data, $expr, $index) = @_;

    my $name = 'argument #' . ($index + 1);
    return scalar Venus::Assert->new($name)->expression($expr)->check($data);
  };

  return $self->foreach($code, @args);
}

sub copy {
  my ($self, @args) = @_;

  for (my $i = 0; $i < @args; $i += 2) {
    my $name = $args[$i];
    my $attr = $args[$i+1];
    $self->can($attr)
      ? $self->$attr($self->get($name))
      : ($self->{$attr} = $self->get($name));
  }

  return $self;
}

sub first {
  my ($self) = @_;

  $self->use(0) if @{$self->{args}};

  return $self;
}

sub foreach {
  my ($self, $code, @args) = @_;

  my $results = [];

  return $results if !$code;

  for my $name (0..$#{$self->{uses}}) {
    my $data = $self->get($self->{uses}->[$name]);
    my $args = $name > $#args ? $args[-1] : $args[$name];
    push @$results, $self->$code($data, $args, $name);
  }

  return $results;
}

sub from {
  my ($self, $data) = @_;

  $self = $self->new if !ref $self;

  $self->{from} = ref $data || $data if $data;

  return $self;
}

sub get {
  my ($self, $name) = @_;

  return if !defined $name;

  return $self->{args}->[$name];
}

sub into {
  my ($self, @args) = @_;

  require Venus::Space;

  my $code = sub {
    my ($self, $data, $name) = @_;

    return $data if UNIVERSAL::isa($data, $name);
    return Venus::Space->new($name)->load->new($data);
  };

  return $self->foreach($code, @args);
}

sub last {
  my ($self) = @_;

  $self->use($#{$self->{args}}) if @{$self->{args}};

  return $self;
}

sub list {
  my ($self, $code, @args) = @_;

  my $results = $self->$code(@args);

  return wantarray ? (ref $results eq 'ARRAY' ? @$results : $results) : $results;
}

sub move {
  my ($self, @args) = @_;

  my %seen;
  for (my $i = 0; $i < @args; $i += 2) {
    $seen{$args[$i]}++;
    my $name = $args[$i];
    my $attr = $args[$i+1];
    $self->can($attr)
      ? $self->$attr($self->get($name))
      : ($self->{$attr} = $self->get($name));
  }

  $self->{args} = [map $self->{args}[$_], grep !$seen{$_}++, 0..$#{$self->{args}}];

  return $self;
}

sub name {
  my ($self, $data) = @_;

  $self->{name} = $data if $data;

  return $self;
}

sub one {
  my ($self, $code, @args) = @_;

  my $results = $self->$code(@args);

  return $results->[0];
}

sub reset {
  my ($self, @args) = @_;

  $self->{args} = [@args] if @args;
  $self->{uses} = [];

  return $self;
}

sub set {
  my ($self, $name, $data) = @_;

  return if !defined $name;

  return $self->{args}->[$name] = $data;
}

sub signature {
  my ($self, @args) = @_;

  require Venus::Assert;

  my ($from, $name) = ((caller(1))[0,3]);
  my ($file, $line) = ((caller(0))[1,2]);

  $from = $self->{from} if defined $self->{from};
  $name = $self->{name} if defined $self->{name};

  if (!$name) {
    $from = "$file at line $line";
    $name = "signature";
  }
  else {
    $name = (split /::/, $name)[-1];
    $name = "signature \"$name\"";
  }

  my $code = sub {
    my ($self, $data, $expr, $index) = @_;

    my $name = qq(argument #@{[$index + 1]} for $name in $from);
    return scalar Venus::Assert->new($name)->expression($expr)->validate($data);
  };

  return $self->list('foreach', $code, @args);
}

sub types {
  my ($self, @args) = @_;

  $self->validate(@args);

  return $self;
}

sub use {
  my ($self, @args) = @_;

  $self->{uses} = [map 0+$_, @args];

  return $self;
}

sub validate {
  my ($self, @args) = @_;

  require Venus::Assert;

  my $code = sub {
    my ($self, $data, $expr, $index) = @_;

    my $name = 'argument #' . ($index + 1);
    return scalar Venus::Assert->new($name)->expression($expr)->validate($data);
  };

  return $self->foreach($code, @args);
}

1;



=head1 NAME

Venus::Unpack - Unpack Class

=cut

=head1 ABSTRACT

Unpack Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Unpack;

  my $unpack = Venus::Unpack->new(args => ["hello", 123, 1.23]);

  # my $args = $unpack->all->types('string', 'number', 'float')->args;

  # ["hello", 123, 1.23]

=cut

=head1 DESCRIPTION

This package provides methods for validating, coercing, and otherwise operating
on lists of arguments.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Kind::Utility>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 all

  all() (Unpack)

The all method selects all arguments for processing returns the invocant.

I<Since C<2.01>>

=over 4

=item all example 1

  # given: synopsis

  package main;

  $unpack = $unpack->all;

  # bless(..., 'Venus::Unpack')

=back

=cut

=head2 arg

  arg(Str $index) (Any)

The arg method returns the argument at the index specified.

I<Since C<2.01>>

=over 4

=item arg example 1

  # given: synopsis

  package main;

  my $arg = $unpack->arg(0);

  # "hello"

=back

=over 4

=item arg example 2

  # given: synopsis

  package main;

  my $arg = $unpack->arg(1);

  # 123

=back

=over 4

=item arg example 3

  # given: synopsis

  package main;

  my $arg = $unpack->arg(2);

  # 1.23

=back

=cut

=head2 args

  args(Any @args) (ArrayRef)

The args method returns all arugments as an arrayref, or list in list context.
If arguments are provided they will overwrite the existing arugment list.

I<Since C<2.01>>

=over 4

=item args example 1

  # given: synopsis

  package main;

  my $args = $unpack->args;

  # ["hello", 123, 1.23]

=back

=over 4

=item args example 2

  # given: synopsis

  package main;

  my $args = $unpack->args(1.23, 123, "hello");

  # [1.23, 123, "hello"]

=back

=cut

=head2 array

  array() (Venus::Array)

The array method returns the argument list as a L<Venus::Array> object.

I<Since C<2.01>>

=over 4

=item array example 1

  # given: synopsis

  package main;

  my $array = $unpack->array;

  # bless(..., 'Venus::Array')

=back

=cut

=head2 cast

  cast(Str $name) (ArrayRef)

The cast method processes the selected arguments, passing each value to the
class name specified, or the L<Venus::Type/cast> method, and returns results.

I<Since C<2.01>>

=over 4

=item cast example 1

  # given: synopsis

  package main;

  my $cast = $unpack->all->cast;

  # [
  #   bless(..., 'Venus::String'),
  #   bless(..., 'Venus::Number'),
  #   bless(..., 'Venus::Float'),
  # ]

=back

=over 4

=item cast example 2

  # given: synopsis

  package main;

  my $cast = $unpack->all->cast('scalar');

  # [
  #   bless(..., 'Venus::Scalar'),
  #   bless(..., 'Venus::Scalar'),
  #   bless(..., 'Venus::Scalar'),
  # ]

=back

=cut

=head2 checks

  checks(Str @types) (ArrayRef)

The checks method processes the selected arguments, passing each value to the
L<Venus::Assert/check> method with the type expression provided, and returns
results.

I<Since C<2.01>>

=over 4

=item checks example 1

  # given: synopsis

  package main;

  my $checks = $unpack->all->checks('string');

  # [true, false, false]

=back

=over 4

=item checks example 2

  # given: synopsis

  package main;

  my $checks = $unpack->all->checks('string | number');

  # [true, true, false]

=back

=over 4

=item checks example 3

  # given: synopsis

  package main;

  my $checks = $unpack->all->checks('string | number', 'float');

  # [true, false, true]

=back

=over 4

=item checks example 4

  # given: synopsis

  package main;

  my $checks = $unpack->all->checks('string', 'number', 'float');

  # [true, true, true]

=back

=over 4

=item checks example 5

  # given: synopsis

  package main;

  my $checks = $unpack->all->checks('boolean', 'value');

  # [false, true, true]

=back

=cut

=head2 copy

  copy(Str @pairs) (Unpack)

The copy method copies values from the arugment list as properties of the
underlying object and returns the invocant.

I<Since C<2.01>>

=over 4

=item copy example 1

  # given: synopsis

  package main;

  $unpack = $unpack->copy(0 => 'arg1');

  # bless({..., arg1 => 'hello'}, 'Venus::Unpack')

=back

=over 4

=item copy example 2

  # given: synopsis

  package main;

  $unpack = $unpack->copy(0 => 'arg1', 2 => 'arg3');

  # bless({..., arg1 => 'hello', arg3 => 1.23}, 'Venus::Unpack')

=back

=over 4

=item copy example 3

  # given: synopsis

  package main;

  $unpack = $unpack->copy(0 => 'arg1', 1 => 'arg2', 2 => 'arg3');

  # bless({..., arg1 => 'hello', arg2 => 123, arg3 => 1.23}, 'Venus::Unpack')

=back

=cut

=head2 first

  first() (Unpack)

The first method selects the first argument for processing returns the
invocant.

I<Since C<2.01>>

=over 4

=item first example 1

  # given: synopsis

  package main;

  $unpack = $unpack->first;

  # bless(..., 'Venus::Unpack')

=back

=cut

=head2 from

  from(Str $data) (Unpack)

The from method names the source of the unpacking operation and is used in
exception messages whenever the L<Venus::Unpack/signature> operation fails.
This method returns the invocant.

I<Since C<2.23>>

=over 4

=item from example 1

  # given: synopsis

  package main;

  $unpack = $unpack->from;

  # bless(..., 'Venus::Unpack')

=back

=over 4

=item from example 2

  # given: synopsis

  package main;

  $unpack = $unpack->from('Example');

  # bless(..., 'Venus::Unpack')

=back

=cut

=head2 get

  get(Str $index) (Any)

The get method returns the argument at the index specified.

I<Since C<2.01>>

=over 4

=item get example 1

  # given: synopsis

  package main;

  my $get = $unpack->get;

  # undef

=back

=over 4

=item get example 2

  # given: synopsis

  package main;

  my $get = $unpack->get(0);

  # "hello"

=back

=over 4

=item get example 3

  # given: synopsis

  package main;

  my $get = $unpack->get(1);

  # 123

=back

=over 4

=item get example 4

  # given: synopsis

  package main;

  my $get = $unpack->get(2);

  # 1.23

=back

=over 4

=item get example 5

  # given: synopsis

  package main;

  my $get = $unpack->get(3);

  # undef

=back

=cut

=head2 into

  into(Str @args) (Any)

The into method processes the selected arguments, passing each value to the
class name specified, and returns results.

I<Since C<2.01>>

=over 4

=item into example 1

  # given: synopsis

  package main;

  my $cast = $unpack->all->into('Venus::String');

  # [
  #   bless(..., 'Venus::String'),
  #   bless(..., 'Venus::String'),
  #   bless(..., 'Venus::String'),
  # ]

=back

=over 4

=item into example 2

  # given: synopsis

  package main;

  my $cast = $unpack->all->into('Venus::String', 'Venus::Number');

  # [
  #   bless(..., 'Venus::String'),
  #   bless(..., 'Venus::Number'),
  #   bless(..., 'Venus::Number'),
  # ]

=back

=over 4

=item into example 3

  # given: synopsis

  package main;

  my $cast = $unpack->all->into('Venus::String', 'Venus::Number', 'Venus::Float');

  # [
  #   bless(..., 'Venus::String'),
  #   bless(..., 'Venus::Number'),
  #   bless(..., 'Venus::Float'),
  # ]

=back

=cut

=head2 last

  last() (Unpack)

The last method selects the last argument for processing returns the
invocant.

I<Since C<2.01>>

=over 4

=item last example 1

  # given: synopsis

  package main;

  $unpack = $unpack->last;

  # bless(..., 'Venus::Unpack')

=back

=cut

=head2 list

  list(Str | CodeRef $code, Any @args) (ArrayRef)

The list method returns the result of the dispatched method call as an
arrayref, or list in list context.

I<Since C<2.01>>

=over 4

=item list example 1

  # given: synopsis

  package main;

  my (@args) = $unpack->all->list('cast');

  # (
  #   bless(..., 'Venus::String'),
  #   bless(..., 'Venus::Number'),
  #   bless(..., 'Venus::Float'),
  # )

=back

=over 4

=item list example 2

  # given: synopsis

  package main;

  my ($string) = $unpack->all->list('cast');

  # (
  #   bless(..., 'Venus::String'),
  # )

=back

=over 4

=item list example 3

  # given: synopsis

  package main;

  my (@args) = $unpack->all->list('cast', 'string');

  # (
  #   bless(..., 'Venus::String'),
  #   bless(..., 'Venus::String'),
  #   bless(..., 'Venus::String'),
  # )

=back

=over 4

=item list example 4

  # given: synopsis

  package main;

  my (@args) = $unpack->use(0,2)->list('cast', 'string', 'float');

  # (
  #   bless(..., 'Venus::String'),
  #   bless(..., 'Venus::Float'),
  # )

=back

=cut

=head2 move

  move(Str @pairs) (Unpack)

The move method moves values from the arugment list, reducing the arugment
list, as properties of the underlying object and returns the invocant.

I<Since C<2.01>>

=over 4

=item move example 1

  # given: synopsis

  package main;

  $unpack = $unpack->move(0 => 'arg1');

  # bless({..., arg1 => 'hello'}, 'Venus::Unpack')

=back

=over 4

=item move example 2

  # given: synopsis

  package main;

  $unpack = $unpack->move(0 => 'arg1', 2 => 'arg3');

  # bless({..., arg1 => 'hello', arg3 => 1.23}, 'Venus::Unpack')

=back

=over 4

=item move example 3

  # given: synopsis

  package main;

  $unpack = $unpack->move(0 => 'arg1', 1 => 'arg2', 2 => 'arg3');

  # bless({..., arg1 => 'hello', arg2 => 123, arg3 => 1.23}, 'Venus::Unpack')

=back

=cut

=head2 name

  name(Str $data) (Unpack)

The name method names the unpacking operation and is used in exception messages
whenever the L<Venus::Unpack/signature> operation fails. This method returns
the invocant.

I<Since C<2.23>>

=over 4

=item name example 1

  # given: synopsis

  package main;

  $unpack = $unpack->name;

  # bless(..., 'Venus::Unpack')

=back

=over 4

=item name example 2

  # given: synopsis

  package main;

  $unpack = $unpack->name('example');

  # bless(..., 'Venus::Unpack')

=back

=cut

=head2 one

  one(Str | CodeRef $code, Any @args) (Any)

The one method returns the first result of the dispatched method call.

I<Since C<2.01>>

=over 4

=item one example 1

  # given: synopsis

  package main;

  my $one = $unpack->all->one('cast');

  # (
  #   bless(..., 'Venus::String'),
  # )

=back

=over 4

=item one example 2

  # given: synopsis

  package main;

  my $one = $unpack->all->one('cast', 'string');

  # (
  #   bless(..., 'Venus::String'),
  # )

=back

=cut

=head2 reset

  reset(Any @args) (Unpack)

The reset method resets the arugments list (if provided) and deselects all
arguments (selected for processing) and returns the invocant.

I<Since C<2.01>>

=over 4

=item reset example 1

  # given: synopsis

  package main;

  $unpack = $unpack->all->reset;

  # bless(..., 'Venus::Unpack')

=back

=over 4

=item reset example 2

  # given: synopsis

  package main;

  $unpack = $unpack->all->reset(1.23, 123, "hello");

  # bless(..., 'Venus::Unpack')

=back

=cut

=head2 set

  set(Str $index, Any $value) (Any)

The set method assigns the value provided at the index specified and returns
the value.

I<Since C<2.01>>

=over 4

=item set example 1

  # given: synopsis

  package main;

  my $set = $unpack->set;

  # undef

=back

=over 4

=item set example 2

  # given: synopsis

  package main;

  my $set = $unpack->set(0, 'howdy');

  # "howdy"

=back

=over 4

=item set example 3

  # given: synopsis

  package main;

  my $set = $unpack->set(1, 987);

  # 987

=back

=over 4

=item set example 4

  # given: synopsis

  package main;

  my $set = $unpack->set(2, 12.3);

  # 12.3

=back

=over 4

=item set example 5

  # given: synopsis

  package main;

  my $set = $unpack->set(3, 'goodbye');

  # "goodbye"

=back

=cut

=head2 signature

  signature(Str $name, Str @types) (ArrayRef)

The signature method processes the selected arguments, passing each value to
the L<Venus::Assert/validate> method with the type expression provided and
throws an exception on failure and otherise returns the results as an arrayref,
or as a list in list context.

I<Since C<2.01>>

=over 4

=item signature example 1

  # given: synopsis

  package main;

  my ($string, $number, $float) = $unpack->all->name('example-1')->signature(
    'string | number | float',
  );

  # ("hello", 123, 1.23)

=back

=over 4

=item signature example 2

  # given: synopsis

  package main;

  my ($string, $number, $float) = $unpack->all->name('example-2')->signature(
    'string', 'number', 'float',
 );

  # ("hello", 123, 1.23)

=back

=over 4

=item signature example 3

  # given: synopsis

  package main;

  my $results = $unpack->all->name('example-3')->signature(
    'string', 'number',
  );

  # Exception! (isa Venus::Assert::Error)

=back

=over 4

=item signature example 4

  # given: synopsis

  package main;

  my $results = $unpack->all->name('example-4')->signature(
    'string',
  );

  # Exception! (isa Venus::Assert::Error)

=back

=over 4

=item signature example 5

  # given: synopsis

  package main;

  my $results = $unpack->all->name('example-5')->from('t/Venus_Unpack.t')->signature(
    'object',
  );

  # Exception! (isa Venus::Assert::Error)

=back

=cut

=head2 types

  types(Str @types) (Unpack)

The types method processes the selected arguments, passing each value to the
L<Venus::Assert/validate> method with the type expression provided, and unlike
the L</validate> method returns the invocant.

I<Since C<2.01>>

=over 4

=item types example 1

  # given: synopsis

  package main;

  $unpack = $unpack->all->types('string | number | float');

  # bless({...}, 'Venus::Unpack')

=back

=over 4

=item types example 2

  # given: synopsis

  package main;

  $unpack = $unpack->all->types('string', 'number', 'float');

  # bless({...}, 'Venus::Unpack')

=back

=over 4

=item types example 3

  # given: synopsis

  package main;

  $unpack = $unpack->all->types('string', 'number');

  # Exception! (isa Venus::Error)

  # argument #3 error

=back

=over 4

=item types example 4

  # given: synopsis

  package main;

  $unpack = $unpack->all->types('string');

  # Exception! (isa Venus::Error)

  # argument #2 error

=back

=cut

=head2 use

  use(Int @args) (Unpack)

The use method selects the arguments specified (by index) for processing
returns the invocant.

I<Since C<2.01>>

=over 4

=item use example 1

  # given: synopsis

  package main;

  $unpack = $unpack->use(1,2);

  # bless(..., 'Venus::Unpack')

=back

=over 4

=item use example 2

  # given: synopsis

  package main;

  $unpack = $unpack->use(1,0);

  # bless(..., 'Venus::Unpack')

=back

=over 4

=item use example 3

  # given: synopsis

  package main;

  $unpack = $unpack->use(2,1,0);

  # bless(..., 'Venus::Unpack')

=back

=cut

=head2 validate

  validate(Str @types) (Unpack)

The validate method processes the selected arguments, passing each value to the
L<Venus::Assert/validate> method with the type expression provided and throws
an exception on failure and otherise returns the resuts.

I<Since C<2.01>>

=over 4

=item validate example 1

  # given: synopsis

  package main;

  my $results = $unpack->all->validate('string | number | float');

  # ["hello", 123, 1.23]

=back

=over 4

=item validate example 2

  # given: synopsis

  package main;

  my $results = $unpack->all->validate('string', 'number', 'float');

  # ["hello", 123, 1.23]

=back

=over 4

=item validate example 3

  # given: synopsis

  package main;

  my $results = $unpack->all->validate('string', 'number');

  # Exception! (isa Venus::Assert::Error)

=back

=over 4

=item validate example 4

  # given: synopsis

  package main;

  my $results = $unpack->all->validate('string');

  # Exception! (isa Venus::Assert::Error)

=back

=cut

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2000, Al Newkirk.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut