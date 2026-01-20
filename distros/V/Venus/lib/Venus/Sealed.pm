package Venus::Sealed;

use 5.018;

use strict;
use warnings;

# IMPORTS

use Venus::Class 'with';

# INTEGRATES

with 'Venus::Role::Buildable';
with 'Venus::Role::Proxyable';
with 'Venus::Role::Tryable';
with 'Venus::Role::Throwable';
with 'Venus::Role::Catchable';

# BUILDERS

sub build_arg {
  my ($self, $data) = @_;

  return {
    value => $data,
  };
}

sub build_args {
  my ($self, $data) = @_;

  if (not(keys %$data == 1 && exists $data->{value})) {
    $data = (exists $data->{value}) ? {value => $data->{value}} : {};
  }

  require Storable;

  $data = Storable::dclone($data);

  my $state = {
    (exists $data->{value} ? (value => $data->{value}) : ())
  };

  my $subs = {
    map +($_, $self->can($_)), grep /^__\w+$/, $self->meta->subs,
  };

  my $scope = sub {
    my ($self, $name, @args) = @_;

    return if !$name;

    my $method = "__$name";

    return if !$subs->{$method};

    return $subs->{$method}->($self, $data, $state, @args);
  };

  return {
    scope => $scope,
  };
}

sub build_self {
  my ($self, $data) = @_;

  return $self;
}

sub build_proxy {
  my ($self, $package, $name, @args) = @_;

  my $method = $self->can("__$name");

  if (!$method && ref $method ne 'CODE') {
    return undef;
  }

  return sub {
    return $self->{scope}->($self, $name, @args);
  };
}

# METHODS

sub __get {
  my ($self, $init, $data) = @_;

  return $data->{value};
}

sub __set {
  my ($self, $init, $data, $value) = @_;

  return $data->{value} = $value;
}

1;



=head1 NAME

Venus::Sealed - Sealed Class

=cut

=head1 ABSTRACT

Sealed Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Sealed;

  my $sealed = Venus::Sealed->new('012345');

  # $sealed->get;

  # '012345'

=cut

=head1 DESCRIPTION

This package provides a mechanism for sealing object and restricting and/or
preventing access to the underlying data structures. This package can be used
directly but is meant to be subclassed.

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Venus::Role::Buildable>

L<Venus::Role::Catchable>

L<Venus::Role::Proxyable>

L<Venus::Role::Throwable>

L<Venus::Role::Tryable>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 get

  get(any @args) (any)

The get method can be used directly to get the sealed value set during
instantiation, but is meant to be overridden in a subclass to further control
access to the underlying data.

I<Since C<3.55>>

=over 4

=item get example 1

  # given: synopsis

  package main;

  my $get = $sealed->get;

  # "012345"

=back

=over 4

=item get example 2

  package Example;

  use Venus::Class;

  base 'Venus::Sealed';

  sub __get {
    my ($self, $init, $data) = @_;

    return $data->{value};
  }

  sub __set {
    my ($self, $init, $data, $value) = @_;

    return $data->{value} = $value;
  }

  package main;

  my $sealed = Example->new("012345");

  my $get = $sealed->get;

  # "012345"

=back

=cut

=head2 new

  new(any @args) (Venus::Sealed)

The new method constructs an instance of the package.

I<Since C<4.15>>

=over 4

=item new example 1

  package main;

  use Venus::Sealed;

  my $new = Venus::Sealed->new;

  # bless(..., "Venus::Sealed")

=back

=over 4

=item new example 2

  package main;

  use Venus::Sealed;

  my $new = Venus::Sealed->new('012345');

  # bless(..., "Venus::Sealed")

=back

=over 4

=item new example 3

  package main;

  use Venus::Sealed;

  my $new = Venus::Sealed->new(value => '012345');

  # bless(..., "Venus::Sealed")

=back

=cut

=head2 set

  set(any @args) (any)

The set method can be used directly to set the sealed value set during
instantiation, but is meant to be overridden in a subclass to further control
access to the underlying data.

I<Since C<3.55>>

=over 4

=item set example 1

  # given: synopsis

  package main;

  my $set = $sealed->set("098765");

  # "098765"

=back

=over 4

=item set example 2

  package Example;

  use Venus::Class;

  base 'Venus::Sealed';

  sub __get {
    my ($self, $init, $data) = @_;

    return $data->{value};
  }

  sub __set {
    my ($self, $init, $data, $value) = @_;

    return $data->{value} = $value;
  }

  package main;

  my $sealed = Example->new("012345");

  my $set = $sealed->set("098765");

  # "098765"

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