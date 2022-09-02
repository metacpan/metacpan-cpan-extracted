package Venus::Throw;

use 5.018;

use strict;
use warnings;

use Venus::Class 'attr', 'base', 'with';

base 'Venus::Kind::Utility';

with 'Venus::Role::Stashable';

# ATTRIBUTES

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

sub assertion {
  my ($self) = @_;

  my $assert = $self->SUPER::assertion;

  $assert->constraints->clear;

  $assert->constraint('string', true);

  return $assert;
}

sub error {
  my ($self, $data) = @_;

  require Venus::Error;

  my $name = $self->name;
  my $context = $self->context || (caller(1))[3];
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