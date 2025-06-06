package Venus::Role::Throwable;

use 5.018;

use strict;
use warnings;

use Venus::Role 'with';

# METHODS

sub error {
  my ($self, $data) = @_;

  my @args = $data;

  unshift @args, delete $data->{throw} if $data->{throw};

  @_ = ($self, @args);

  goto $self->can('throw');
}

sub throw {
  my ($self, $data, @args) = @_;

  require Venus::Throw;

  my $throw = Venus::Throw->new(context => (caller(1))[3])->do(
    frame => 1,
  );

  if (!$data) {
    return $throw->do(
      'package', join('::', map ucfirst, ref($self), 'error')
    );
  }
  if (ref $data ne 'HASH') {
    if ($data =~ /^\w+$/ && $self->can($data)) {
      $data = $self->$data(@args);
    }
    else {
      return $throw->do(
        'package', $data,
      );
    }
  }

  if (exists $data->{as}) {
    $throw->as($data->{as});
  }
  if (exists $data->{capture}) {
    $throw->capture(@{$data->{capture}});
  }
  if (exists $data->{context}) {
    $throw->context($data->{context});
  }
  if (exists $data->{error}) {
    $throw->error($data->{error});
  }
  if (exists $data->{frame}) {
    $throw->frame($data->{frame});
  }
  if (exists $data->{message}) {
    $throw->message($data->{message});
  }
  if (exists $data->{name}) {
    $throw->name($data->{name});
  }
  if (exists $data->{package}) {
    $throw->package($data->{package});
  }
  else {
    $throw->package(join('::', map ucfirst, ref($self), 'error'));
  }
  if (exists $data->{parent}) {
    $throw->parent($data->{parent});
  }
  if (exists $data->{stash}) {
    $throw->stash($_, $data->{stash}->{$_}) for keys %{$data->{stash}};
  }
  if (exists $data->{on}) {
    $throw->on($data->{on});
  }
  if (exists $data->{raise}) {
    @_ = ($throw);
    goto $throw->can('error');
  }

  return $throw;
}

# EXPORTS

sub EXPORT {
  ['error', 'throw']
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

=head2 error

  error(hashref $data) (any)

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

  my $throw = $example->error;

  # bless({ "package" => "Example::Error", ..., }, "Venus::Throw")

  # $throw->error;

=back

=over 4

=item error example 2

  package main;

  my $example = Example->new;

  my $throw = $example->error({package => 'Example::Error::Unknown'});

  # bless({ "package" => "Example::Error::Unknown", ..., }, "Venus::Throw")

  # $throw->error;

=back

=over 4

=item error example 3

  package main;

  my $example = Example->new;

  my $throw = $example->error({
    name => 'on.example',
    capture => [$example],
    stash => {
      time => time,
    },
  });

  # bless({ "package" => "Example::Error", ..., }, "Venus::Throw")

  # $throw->error;

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

  my $throw = $example->error({throw => 'error_on_example'});

  # bless({ "package" => "Example::Error", ..., }, "Venus::Throw")

  # $throw->error;

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
      raise => 1,
    };
  }

  package main;

  my $throw = $example->error({throw => 'error_on_example'});

  # Exception! (isa Example::Error)

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

  # bless({ "package" => "Example::Error", ..., }, "Venus::Throw")

  # $throw->error;

=back

=over 4

=item throw example 2

  package main;

  my $example = Example->new;

  my $throw = $example->throw('Example::Error::Unknown');

  # bless({ "package" => "Example::Error::Unknown", ..., }, "Venus::Throw")

  # $throw->error;

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

  # bless({ "package" => "Example::Error", ..., }, "Venus::Throw")

  # $throw->error;

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

  # bless({ "package" => "Example::Error", ..., }, "Venus::Throw")

  # $throw->error;

=back

=over 4

=item throw example 5

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
      raise => 1,
    };
  }

  package main;

  my $throw = $example->throw('error_on_example');

  # Exception! (isa Example::Error)

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