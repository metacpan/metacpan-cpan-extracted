package Venus::Role::Throwable;

use 5.018;

use strict;
use warnings;

# IMPORTS

use Venus::Role 'with';

# METHODS

sub die {
  my ($self, $data) = @_;

  $data ||= {};

  if (!ref $data) {
    $data = $self->can($data) ? $self->$data : {package => $data};
  }

  $data = {} if ref $data ne 'HASH';

  my $args = $data->{throw} ? delete $data->{throw} : $data->{args} ? delete $data->{args} : undef;

  $data = $self->$args($data) if $args;

  require Venus::Throw;

  my ($throw) = @_ = (
    Venus::Throw->new(
      context => (caller(1))[3],
      package => join('::', map ucfirst, ref($self), 'error'),
    ),
    $data,
  );

  goto $throw->can('die');
}

sub error {
  my ($self, $data) = @_;

  $data ||= {};

  if (!ref $data) {
    $data = $self->can($data) ? $self->$data : {package => $data};
  }

  $data = {} if ref $data ne 'HASH';

  my $args = $data->{throw} ? delete $data->{throw} : $data->{args} ? delete $data->{args} : undef;

  $data = $self->$args($data) if $args;

  require Venus::Throw;

  my ($throw) = @_ = (
    Venus::Throw->new(
      context => (caller(1))[3],
      package => $data->{package} || join('::', map ucfirst, ref($self), 'error'),
    ),
    $data,
  );

  goto $throw->can('error');
}

sub throw {
  my ($self, $data) = @_;

  $data ||= {};

  if (!ref $data) {
    $data = $self->can($data) ? $self->$data : {package => $data};
  }

  $data = {} if ref $data ne 'HASH';

  my $args = $data->{throw} ? delete $data->{throw} : $data->{args} ? delete $data->{args} : undef;

  $data = $self->$args($data) if $args;

  require Venus::Throw;

  my $throw = Venus::Throw->new(
    context => (caller(1))[3],
    package => $data->{package} || join('::', map ucfirst, ref($self), 'error'),
  );

  for my $key (keys %{$data}) {
    $throw->$key($data->{$key}) if $throw->can($key);
  }

  return $throw;
}

# EXPORTS

sub EXPORT {
  ['die', 'error', 'throw']
}

1;



=head1 NAME

Venus::Role::Throwable - Throwable Role

=cut

=head1 ABSTRACT

Throwable Role for Perl 5

=cut

=head1 SYNOPSIS

  package Example;

  use Venus::Class;

  with 'Venus::Role::Throwable';

  package main;

  my $example = Example->new;

  # $example->throw;

=cut

=head1 DESCRIPTION

This package modifies the consuming package and provides a mechanism for
throwing context-aware errors (exceptions).

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 die

  die(maybe[string | hashref] $data) (any)

The die method builds a L<Venus::Throw> object using L</throw> and
automatically throws the exception.

I<Since C<4.15>>

=over 4

=item die example 1

  # given: synopsis

  package Example;

  # ...

  sub error_on_example {
    my ($self) = @_;

    return {
      name => 'on.example',
      capture => [$example],
      stash => {
        time => time,
      },
      raise => true,
    };
  }

  package main;

  my $die = $example->die('error_on_example');

  # Exception! isa Example::Error

=back

=cut

=head2 error

  error(maybe[string | hashref] $data) (any)

The error method dispatches to the L</throw> method, excepts a hashref of
options to be provided to the L</throw> method, and returns the result unless
an exception is raised automatically. If the C<throw> option is provided it is
excepted to be the name of a method used as a callback to provide arguments to
the thrower.

I<Since C<3.40>>

=over 4

=item error example 1

  package main;

  my $example = Example->new;

  my $error = $example->error;

  # bless(..., "Example::Error")

  # $error->throw;

  # Exception! isa "Example::Error"

=back

=over 4

=item error example 2

  package main;

  my $example = Example->new;

  my $error = $example->error('Example::Error::Unknown');

  # bless(..., "Example::Error::Unknown")

  # $error->throw;

  # Exception! isa "Example::Error::Unknown"

=back

=over 4

=item error example 3

  package main;

  my $example = Example->new;

  my $error = $example->error({
    name => 'on.example',
    capture => [$example],
    stash => {
      time => time,
    },
  });

  # bless(..., "Example::Error")

  # $error->throw;

  # Exception! isa "Example::Error"

=back

=over 4

=item error example 4

  # given: synopsis

  package Example;

  # ...

  sub error_on_example {
    my ($self) = @_;

    return {
      name => 'on.example',
      capture => [$example],
      stash => {
        time => time,
      },
    };
  }

  package main;

  my $error = $example->error('error_on_example');

  # bless(..., "Example::Error")

  # $error->throw;

  # Exception! isa "Example::Error"

=back

=over 4

=item error example 5

  # given: synopsis

  package Example;

  # ...

  sub error_on_example {
    my ($self) = @_;

    return {
      name => 'on.example',
      capture => [$example],
      stash => {
        time => time,
      },
      raise => false,
    };
  }

  package main;

  my $error = $example->error({throw => 'error_on_example'});

  # bless(..., "Example::Error")

  # $error->throw;

  # Exception! isa "Example::Error"

=back

=over 4

=item error example 6

  # given: synopsis

  package Example;

  # ...

  sub error_on_example {
    my ($self) = @_;

    return {
      name => 'on.example',
      capture => [$example],
      stash => {
        time => time,
      },
      raise => true,
    };
  }

  package main;

  my $error = $example->error({throw => 'error_on_example'});

  # Exception! isa Example::Error

=back

=cut

=head2 throw

  throw(maybe[string | hashref] $data, any @args) (any)

The throw method builds a L<Venus::Throw> object, which can raise errors
(exceptions). If passed a string representing a package name, the throw object
will be configured to throw an exception using that package name. If passed a
string representing a method name, the throw object will call that method
expecting a hashref to be returned which will be provided to L<Venus::Throw> as
arguments to configure the thrower. If passed a hashref, the keys and values
are expected to be method names and arguments which will be called to configure
the L<Venus::Throw> object returned. If passed additional arguments, assuming
they are preceeded by a string representing a method name, the additional
arguments will be supplied to the method when called. If the C<raise> argument
is provided (or returned from the callback), the thrower will automatically
throw the exception.

I<Since C<0.01>>

=over 4

=item throw example 1

  package main;

  my $example = Example->new;

  my $throw = $example->throw;

  # bless({"package" => "Example::Error", ...,}, "Venus::Throw")

  # $throw->die;

  # Exception! isa Example::Error

=back

=over 4

=item throw example 2

  package main;

  my $example = Example->new;

  my $throw = $example->throw('Example::Error::Unknown');

  # bless({"package" => "Example::Error::Unknown", ...,}, "Venus::Throw")

  # $throw->die;

  # Exception! isa Example::Error::Unknown

=back

=over 4

=item throw example 3

  package main;

  my $example = Example->new;

  my $throw = $example->throw({
    name => 'on.example',
    capture => [$example],
    stash => {
      time => time,
    },
  });

  # bless({"package" => "Example::Error", ...,}, "Venus::Throw")

  # $throw->die;

  # Exception! isa Example::Error

=back

=over 4

=item throw example 4

  # given: synopsis

  package Example;

  # ...

  sub error_on_example {
    my ($self) = @_;

    return {
      name => 'on.example',
      capture => [$example],
      stash => {
        time => time,
      },
    };
  }

  package main;

  my $throw = $example->throw('error_on_example');

  # bless({"package" => "Example::Error", ...,}, "Venus::Throw")

  # $throw->die;

  # Exception! isa Example::Error

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