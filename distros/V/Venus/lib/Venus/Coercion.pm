package Venus::Coercion;

use 5.018;

use strict;
use warnings;

# IMPORTS

use Venus::Class 'attr', 'base', 'with';

use Venus::Check;

# INHERITS

base 'Venus::Kind::Utility';

# INTEGRATES

with 'Venus::Role::Buildable';

# ATTRIBUTES

attr 'on_eval';

# BUILDERS

sub build_arg {
  my ($self, $data) = @_;

  return {
    on_eval => ref $data eq 'ARRAY' ? $data : [$data],
  };
}

sub build_args {
  my ($self, $data) = @_;

  $data->{on_eval} = [] if !$data->{on_eval};

  return $data;
}

# METHODS

sub accept {
  my ($self, $name, @args) = @_;

  if (!$name) {
    return $self;
  }
  if ($self->check->can($name)) {
    $self->check->accept($name, @args);
  }
  else {
    $self->check->identity($name, @args);
  }
  return $self;
}

sub check {
  my ($self, @args) = @_;

  $self->{check} = $args[0] if @args;

  return $self->{check} ||= Venus::Check->new;
}

sub clear {
  my ($self) = @_;

  @{$self->on_eval} = ();

  $self->check->clear;

  return $self;
}

sub format {
  my ($self, @code) = @_;

  push @{$self->on_eval}, @code;

  return $self;
}

sub eval {
  my ($self, $data) = @_;

  if (!$self->check->eval($data)) {
    return $data;
  }

  for my $callback (@{$self->on_eval}) {
    local $_ = $data;
    $data = $self->$callback($data);
  }

  return $data;
}

sub evaler {
  my ($self) = @_;

  return $self->defer('eval');
}

sub result {
  my ($self, $data) = @_;

  return $self->eval($data);
}

1;



=head1 NAME

Venus::Coercion - Coercion Class

=cut

=head1 ABSTRACT

Coercion Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Coercion;

  my $coercion = Venus::Coercion->new;

  # $coercion->accept('float');

  # $coercion->format(sub{sprintf '%.2f', $_});

  # $coercion->result(123.456);

  # 123.46

=cut

=head1 DESCRIPTION

This package provides a mechanism for evaluating type coercions on data.
Built-in type coercions are handled via L<Venus::Check>.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Kind::Utility>

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Venus::Role::Buildable>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 accept

  accept(string $name, any @args) (Venus::Coercion)

The accept method registers a condition via L</check> based on the arguments
provided. The built-in types are defined as methods in L<Venus::Check>.

I<Since C<3.55>>

=over 4

=item accept example 1

  # given: synopsis

  package main;

  $coercion = $coercion->accept('float');

  # bless(..., "Venus::Coercion")

  # $coercion->result;

  # undef

  # $coercion->result(1.01);

  # 1.01

=back

=over 4

=item accept example 2

  # given: synopsis

  package main;

  $coercion = $coercion->accept('number');

  # bless(..., "Venus::Coercion")

  # $coercion->result(1.01);

  # 1.01

  # $coercion->result(1_01);

  # 101

=back

=over 4

=item accept example 3

  # given: synopsis

  package Example1;

  sub new {
    bless {};
  }

  package Example2;

  sub new {
    bless {};
  }

  package main;

  $coercion = $coercion->accept('object');

  # bless(..., "Venus::Coercion")

  # $coercion->result;

  # undef

  # $coercion->result(qr//);

  # qr//

  # $coercion->result(Example1->new);

  # bless(..., "Example1")

  # $coercion->result(Example2->new);

  # bless(..., "Example2")

=back

=over 4

=item accept example 4

  # given: synopsis

  package Example1;

  sub new {
    bless {};
  }

  package Example2;

  sub new {
    bless {};
  }

  package main;

  $coercion = $coercion->accept('Example1');

  # bless(..., "Venus::Coercion")

  # $coercion->result;

  # undef

  # $coercion->result(qr//);

  # qr//

  # $coercion->result(Example1->new);

  # bless(..., "Example1")

  # $coercion->result(Example2->new);

  # bless(..., "Example2")

=back

=cut

=head2 check

  check(Venus::Check $data) (Venus::Check)

The check method gets or sets the L<Venus::Check> object used for performing
runtime data type validation.

I<Since C<3.55>>

=over 4

=item check example 1

  # given: synopsis

  package main;

  my $check = $coercion->check(Venus::Check->new);

  # bless(..., 'Venus::Check')

=back

=over 4

=item check example 2

  # given: synopsis

  package main;

  $coercion->check(Venus::Check->new);

  my $check = $coercion->check;

  # bless(..., 'Venus::Check')

=back

=cut

=head2 clear

  clear() (Venus::Coercion)

The clear method resets the L</check> attributes and returns the invocant.

I<Since C<3.55>>

=over 4

=item clear example 1

  # given: synopsis

  package main;

  $coercion->accept('string');

  $coercion = $coercion->clear;

  # bless(..., "Venus::Coercion")

=back

=cut

=head2 eval

  eval(any $data) (boolean)

The eval method dispatches to the L</check> object as well as evaluating any
custom conditions, and returns the coerced value if all conditions pass, and
the original value if any condition fails.

I<Since C<3.55>>

=over 4

=item eval example 1

  # given: synopsis

  package main;

  use Venus::Float;

  $coercion->accept('float');

  $coercion->format(sub{Venus::Float->new($_)});

  my $eval = $coercion->eval('1.00');

  # bless(..., "Venus::Float")

=back

=over 4

=item eval example 2

  # given: synopsis

  package main;

  use Venus::Float;

  $coercion->accept('float');

  $coercion->format(sub{Venus::Float->new($_)});

  my $eval = $coercion->eval(1_00);

  # 100

=back

=cut

=head2 evaler

  evaler(any @args) (coderef)

The evaler method returns a coderef which calls the L</eval> method with the
invocant when called.

I<Since C<3.55>>

=over 4

=item evaler example 1

  # given: synopsis

  package main;

  my $evaler = $coercion->evaler;

  # sub{...}

  # my $result = $evaler->();

  # undef

=back

=over 4

=item evaler example 2

  # given: synopsis

  package main;

  my $evaler = $coercion->accept('any')->evaler;

  # sub{...}

  # my $result = $evaler->('hello');

  # "hello"

=back

=cut

=head2 format

  format(coderef $code) (Venus::Coercion)

The format method registers a custom (not built-in) coercion condition and
returns the invocant.

I<Since C<3.55>>

=over 4

=item format example 1

  # given: synopsis

  package main;

  $coercion->accept('either', 'float', 'number');

  my $format = $coercion->format(sub {
    int $_
  });

  # bless(.., "Venus::Coercion")

=back

=cut

=head2 new

  new(any @args) (Venus::Coercion)

The new method constructs an instance of the package.

I<Since C<4.15>>

=over 4

=item new example 1

  package main;

  use Venus::Coercion;

  my $new = Venus::Coercion->new;

  # bless(..., "Venus::Coercion")

=back

=cut

=head2 result

  result(any $data) (boolean)

The result method dispatches to the L</eval> method and returns the result.

I<Since C<3.55>>

=over 4

=item result example 1

  # given: synopsis

  package main;

  $coercion->accept('float');

  $coercion->format(sub{int $_});

  my $result = $coercion->result('1.00');

  # 1

=back

=over 4

=item result example 2

  # given: synopsis

  package main;

  $coercion->accept('float');

  $coercion->format(sub{int $_});

  my $result = $coercion->result('0.99');

  # 0

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