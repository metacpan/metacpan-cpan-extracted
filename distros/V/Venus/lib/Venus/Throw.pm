package Venus::Throw;

use 5.018;

use strict;
use warnings;

# IMPORTS

use Venus::Class 'attr', 'base';

# INHERITS

base 'Venus::Error';

# OVERLOADS

use overload (
  '""' => sub{$_[0]->error->explain},
  '~~' => sub{$_[0]->error->explain},
  fallback => 1,
);

# ATTRIBUTES

attr 'package';
attr 'parent';

# BUILDERS

sub build_arg {
  my ($self, $data) = @_;

  return {
    package => $data,
  };
}

sub build_self {
  my ($self, $data) = @_;

  if (!$self->parent) {
    $self->parent('Venus::Error');
  }

  if (my $stash = delete $data->{stash}) {
    %{$self->stash} = %{$stash};
  }

  return $self;
}

# METHODS

sub die {
  my ($self, $data) = @_;

  $data ||= {};

  $data->{raise} = true;

  @_ = ($self, $data);

  goto $self->can('error');
}

sub error {
  my ($self, $data) = @_;

  $data ||= {};

  for my $key (keys %{$data}) {
    next if $key eq 'die';
    next if $key eq 'error';

    $self->$key($data->{$key}) if $self->can($key);
  }

  my $context = $self->context;

  if (!$context) {
    $context = $self->context((caller(($self->offset // 0) + 1))[3]);
  }

  my $package = $self->package;

  if (!$package) {
    $package = $self->package(join('::', map ucfirst, (caller($self->offset // 0))[0], 'error'));
  }

  my $parent = $self->parent;

  if (!$parent) {
    $parent = $self->parent('Venus::Error');
  }

  local $@;

  if (!$package->can('new') and !eval "package $package; use base '$parent'; 1") {
    my $throw = $self->class->new;
    $throw->message($@);
    $throw->package('Venus::Throw::Error');
    $throw->parent('Venus::Error');
    $throw->stash(package => $package);
    $throw->stash(parent => $parent);
    $throw->die;
  }

  if (!$parent->isa('Venus::Error')) {
    my $throw = $self->class->new;
    $throw->message(qq(Parent '$parent' doesn't derive from 'Venus::Error'));
    $throw->package('Venus::Throw::Error');
    $throw->parent('Venus::Error');
    $throw->stash(package => $package);
    $throw->stash(parent => $parent);
    $throw->die;
  }

  if (!$package->isa('Venus::Error')) {
    my $throw = $self->class->new;
    $throw->message(qq(Package '$package' doesn't derive from 'Venus::Error'));
    $throw->package('Venus::Throw::Error');
    $throw->parent('Venus::Error');
    $throw->stash(package => $package);
    $throw->stash(parent => $parent);
    $throw->die;
  }

  my $error = $package->new->copy($self);

  (@_ = ($error)) && goto $error->can('throw') if $data && $data->{raise};

  return $error;
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

=head2 package

  package(string $package) (string)

The package attribute is read-write, accepts C<(string)> values, and is
optional.

I<Since C<4.15>>

=over 4

=item package example 1

  # given: synopsis

  package main;

  my $package = $throw->package("Example");

  # "Example"

=back

=over 4

=item package example 2

  # given: synopsis

  # given: example-1 package

  package main;

  $package = $throw->package;

  # "Example"

=back

=cut

=head2 parent

  parent(string $parent) (string)

The parent attribute is read-write, accepts C<(string)> values, and is
optional.

I<Since C<4.15>>

=over 4

=item parent example 1

  # given: synopsis

  package main;

  my $parent = $throw->parent("Venus::Error");

  # "Venus::Error"

=back

=over 4

=item parent example 2

  # given: synopsis

  # given: example-1 parent

  package main;

  $parent = $throw->parent;

  # "Venus::Error"

=back

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Error>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 die

  die(hashref $data) (Venus::Error)

The die method builds an error object from the attributes set on the invocant
and throws it.

I<Since C<4.15>>

=over 4

=item die example 1

  # given: synopsis;

  my $die = $throw->die;

  # bless({
  #   ...,
  #   "context"  => "(eval)",
  #   "message"  => "Exception!",
  # }, "Main::Error")

=back

=over 4

=item die example 2

  # given: synopsis;

  my $die = $throw->die({
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

=item die example 3

  package main;

  use Venus::Throw;

  my $throw = Venus::Throw->new('Example::Error');

  my $die = $throw->die;

  # bless({
  #   ...,
  #   "context"  => "(eval)",
  #   "message"  => "Exception!",
  # }, "Example::Error")

=back

=over 4

=item die example 4

  package main;

  use Venus::Throw;

  my $throw = Venus::Throw->new(
    package => 'Example::Error',
    parent => 'Venus::Error',
  );

  my $die = $throw->die({
    message => 'Example error!',
  });

  # bless({
  #   ...,
  #   "context"  => "(eval)",
  #   "message"  => "Example error!",
  # }, "Example::Error")

=back

=over 4

=item die example 5

  package Example::Error;

  use base 'Venus::Error';

  package main;

  use Venus::Throw;

  my $throw = Venus::Throw->new(
    package => 'Example::Error::Unknown',
    parent => 'Example::Error',
  );

  my $die = $throw->die({
    message => 'Example error (unknown)!',
  });

  # bless({
  #   ...,
  #   "context"  => "(eval)",
  #   "message"  => "Example error (unknown)!",
  # }, "Example::Error::Unknown")

=back

=over 4

=item die example 6

  package main;

  use Venus::Throw;

  my $throw = Venus::Throw->new(
    package => 'Example::Error::NoThing',
    parent => 'No::Thing',
  );

  my $die = $throw->die({
    message => 'Example error (no thing)!',
    raise => true,
  });

  # No::Thing does not exist

  # Exception! Venus::Throw::Error (isa Venus::Error)

=back

=over 4

=item die example 7

  # given: synopsis;

  my $die = $throw->die({
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

=head2 error

  error(hashref $data) (Venus::Error)

The error method builds an error object from the attributes set on the invocant
and returns or optionally automatically throws it.

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
    raise => true,
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

=head2 new

  new(any @args) (Venus::Throw)

The new method constructs an instance of the package.

I<Since C<4.15>>

=over 4

=item new example 1

  package main;

  use Venus::Throw;

  my $new = Venus::Throw->new;

  # bless(..., "Venus::Throw")

=back

=over 4

=item new example 2

  package main;

  use Venus::Throw;

  my $new = Venus::Throw->new(package => 'Example::Error', parent => 'Venus::Error');

  # bless(..., "Venus::Throw")

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