package Venus::Throw;

use 5.018;

use strict;
use warnings;

use Venus::Class 'attr', 'base', 'with';

base 'Venus::Kind::Utility';

with 'Venus::Role::Stashable';

use overload (
  '""' => sub{$_[0]->catch('error')->explain},
  '~~' => sub{$_[0]->catch('error')->explain},
  fallback => 1,
);

# ATTRIBUTES

attr 'frame';
attr 'name';
attr 'message';
attr 'package';
attr 'parent';
attr 'context';

# BUILDERS

sub build_arg {
  my ($self, $data) = @_;

  return {
    package => $data,
  };
}

sub build_self {
  my ($self, $data) = @_;

  $self->parent('Venus::Error') if !$self->parent;

  return $self;
}

# METHODS

sub as {
  my ($self, $name) = @_;

  $self->name($name);

  return $self;
}

sub assertion {
  my ($self) = @_;

  my $assert = $self->SUPER::assertion;

  $assert->clear->expression('string');

  return $assert;
}

sub capture {
  my ($self, @args) = @_;

  my $frame = $self->frame;

  $self->stash(captured => {
    callframe => [caller($frame // 1)],
    arguments => [@args],
  });

  return $self;
}

sub error {
  my ($self, $data) = @_;

  require Venus::Error;

  my $frame = $self->frame;
  my $name = $self->name;
  my $context = $self->context || (caller($frame // 1))[3];
  my $package = $self->package || join('::', map ucfirst, (caller(0))[0], 'error');
  my $parent = $self->parent;
  my $message = $self->message;

  $data //= {};
  $data->{context} //= $context;
  $data->{message} //= $message if $message;
  $data->{name} //= $name if $name;

  if (%{$self->stash}) {
    $data->{'$stash'} //= $self->stash;
  }

  local $@;
  if (!$package->can('new') and !eval "package $package; use base '$parent'; 1") {
    my $throw = Venus::Throw->new(package => 'Venus::Throw::Error');
    $throw->message($@);
    $throw->stash(package => $package);
    $throw->stash(parent => $parent);
    $throw->error;
  }
  if (!$parent->isa('Venus::Error')) {
    my $throw = Venus::Throw->new(package => 'Venus::Throw::Error');
    $throw->message(qq(Parent '$parent' doesn't derive from 'Venus::Error'));
    $throw->stash(package => $package);
    $throw->stash(parent => $parent);
    $throw->error;
  }
  if (!$package->isa('Venus::Error')) {
    my $throw = Venus::Throw->new(package => 'Venus::Throw::Error');
    $throw->message(qq(Package '$package' doesn't derive from 'Venus::Error'));
    $throw->stash(package => $package);
    $throw->stash(parent => $parent);
    $throw->error;
  }

  @_ = ($package->new($data ? $data : ()));

  goto $package->can('throw');
}

sub on {
  my ($self, $name) = @_;

  my $frame = $self->frame;

  my $routine = (split(/::/, (caller($frame // 1))[3]))[-1];

  undef $routine if $routine eq '__ANON__' || $routine eq '(eval)';

  $self->name(join('.', 'on', grep defined, $routine, $name)) if $routine || $name;

  return $self;
}

1;



=head1 NAME

Venus::Throw - Throw Class

=cut

=head1 ABSTRACT

Throw Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Throw;

  my $throw = Venus::Throw->new;

  # $throw->error;

=cut

=head1 DESCRIPTION

This package provides a mechanism for generating and raising errors (exception
objects).

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 frame

  frame(Int)

This attribute is read-write, accepts C<(Int)> values, and is optional.

=cut

=head2 name

  name(Str)

This attribute is read-write, accepts C<(Str)> values, and is optional.

=cut

=head2 message

  message(Str)

This attribute is read-write, accepts C<(Str)> values, and is optional.

=cut

=head2 package

  package(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 parent

  parent(Str)

This attribute is read-only, accepts C<(Str)> values, is optional, and defaults to C<'Venus::Error'>.

=cut

=head2 context

  context(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Kind::Utility>

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Venus::Role::Stashable>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 as

  as(Str $name) (Throw)

The as method sets a L</name> for the error and returns the invocant.

I<Since C<2.55>>

=over 4

=item as example 1

  # given: synopsis

  package main;

  $throw = $throw->as('on.handler');

  # bless({...}, 'Venus::Throw')

=back

=cut

=head2 error

  error(HashRef $data) (Error)

The error method throws the prepared error object.

I<Since C<0.01>>

=over 4

=item error example 1

  # given: synopsis;

  my $error = $throw->error;

  # bless({
  #   ...,
  #   "context"  => "(eval)",
  #   "message"  => "Exception!",
  # }, "Main::Error")

=back

=over 4

=item error example 2

  # given: synopsis;

  my $error = $throw->error({
    message => 'Something failed!',
    context => 'Test.error',
  });

  # bless({
  #   ...,
  #   "context"  => "Test.error",
  #   "message"  => "Something failed!",
  # }, "Main::Error")

=back

=over 4

=item error example 3

  package main;

  use Venus::Throw;

  my $throw = Venus::Throw->new('Example::Error');

  my $error = $throw->error;

  # bless({
  #   ...,
  #   "context"  => "(eval)",
  #   "message"  => "Exception!",
  # }, "Example::Error")

=back

=over 4

=item error example 4

  package main;

  use Venus::Throw;

  my $throw = Venus::Throw->new(
    package => 'Example::Error',
    parent => 'Venus::Error',
  );

  my $error = $throw->error({
    message => 'Example error!',
  });

  # bless({
  #   ...,
  #   "context"  => "(eval)",
  #   "message"  => "Example error!",
  # }, "Example::Error")

=back

=over 4

=item error example 5

  package Example::Error;

  use base 'Venus::Error';

  package main;

  use Venus::Throw;

  my $throw = Venus::Throw->new(
    package => 'Example::Error::Unknown',
    parent => 'Example::Error',
  );

  my $error = $throw->error({
    message => 'Example error (unknown)!',
  });

  # bless({
  #   ...,
  #   "context"  => "(eval)",
  #   "message"  => "Example error (unknown)!",
  # }, "Example::Error::Unknown")

=back

=over 4

=item error example 6

  package main;

  use Venus::Throw;

  my $throw = Venus::Throw->new(
    package => 'Example::Error::NoThing',
    parent => 'No::Thing',
  );

  my $error = $throw->error({
    message => 'Example error (no thing)!',
  });

  # No::Thing does not exist

  # Exception! Venus::Throw::Error (isa Venus::Error)

=back

=over 4

=item error example 7

  # given: synopsis;

  my $error = $throw->error({
    name => 'on.test.error',
    context => 'Test.error',
    message => 'Something failed!',
  });

  # bless({
  #   ...,
  #   "context"  => "Test.error",
  #   "message"  => "Something failed!",
  #   "name"  => "on_test_error",
  # }, "Main::Error")

=back

=cut

=head2 on

  on(Str $name) (Throw)

The on method sets a L</name> for the error in the form of
C<"on.$subroutine.$name"> or C<"on.$name"> (if outside of a subroutine) and
returns the invocant.

I<Since C<2.55>>

=over 4

=item on example 1

  # given: synopsis

  package main;

  $throw = $throw->on('handler');

  # bless({...}, 'Venus::Throw')

  # $throw->name;

  # "on.handler"

=back

=over 4

=item on example 2

  # given: synopsis

  package main;

  sub execute {
    $throw->on('handler');
  }

  $throw = execute();

  # bless({...}, 'Venus::Throw')

  # $throw->name;

  # "on.execute.handler"

=back

=cut

=head1 OPERATORS

This package overloads the following operators:

=cut

=over 4

=item operation: C<("")>

This package overloads the C<""> operator.

B<example 1>

  # given: synopsis;

  my $result = "$throw";

  # "Exception!"

=back

=over 4

=item operation: C<(~~)>

This package overloads the C<~~> operator.

B<example 1>

  # given: synopsis;

  my $result = $throw ~~ 'Exception!';

  # 1

=back

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2000, Al Newkirk.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut