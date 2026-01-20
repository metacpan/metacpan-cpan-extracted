package Venus::Role::Encaseable;

use 5.018;

use strict;
use warnings;

# IMPORTS

use Venus::Role 'fault', 'mask';

# ATTRIBUTES

mask 'private';

# AUDITS

sub AUDIT {
  my ($self, $from) = @_;

  if (!$from->isa('Venus::Core')) {
    fault "${self} requires ${from} to derive from Venus::Core";
  }

  return $self;
}

# METHODS

sub clone {
  my ($self) = @_;

  return $self->CLONE;
}

sub encase {
  my ($self, $key, $value) = @_;

  return if !$key;

  my $caller = caller;

  require Scalar::Util;

  if (!Scalar::Util::blessed($self)) {
    fault "Can't encase variable \"${key}\" without an instance of \"${self}\"";
  }

  my $class = ref $self;

  if ($caller ne $class && !$class->isa($caller)) {
    fault "Can't encase variable \"${key}\" outside the class or subclass of \"${class}\"";
  }

  my $data = $self->private || $self->private({});

  return $data->{$key} if exists $data->{$key};

  return $data->{$key} = $value;
}

sub encased {
  my ($self, $key) = @_;

  return if !$key;

  my $caller = caller;

  require Scalar::Util;

  if (!Scalar::Util::blessed($self)) {
    fault "Can't retrieve encased variable \"${key}\" without an instance of \"${self}\"";
  }

  my $class = ref $self;

  if ($caller ne $class && !$class->isa($caller)) {
    fault "Can't retrieve encased variable \"${key}\" outside the class or subclass of \"${class}\"";
  }

  my $data = $self->private || $self->private({});

  return $data->{$key};
}

sub recase {
  my ($self, $key, $value) = @_;

  return if !$key;

  my $caller = caller;

  require Scalar::Util;

  if (!Scalar::Util::blessed($self)) {
    fault "Can't recase variable \"${key}\" without an instance of \"${self}\"";
  }

  my $class = ref $self;

  if ($caller ne $class && !$class->isa($caller)) {
    fault "Can't recase variable \"${key}\" outside the class or subclass of \"${class}\"";
  }

  my $data = $self->private || $self->private({});

  return $data->{$key} = $value;
}

sub uncase {
  my ($self, $key) = @_;

  return if !$key;

  my $caller = caller;

  require Scalar::Util;

  if (!Scalar::Util::blessed($self)) {
    fault "Can't uncase variable \"${key}\" without an instance of \"${self}\"";
  }

  my $class = ref $self;

  if ($caller ne $class && !$class->isa($caller)) {
    fault "Can't uncase variable \"${key}\" outside the class or subclass of \"${class}\"";
  }

  my $data = $self->private || $self->private({});

  return delete $data->{$key};
}

# EXPORTS

sub EXPORT {
  ['clone', 'encase', 'encased', 'private', 'recase', 'uncase']
}

1;



=head1 NAME

Venus::Role::Encaseable - Encaseable Role

=cut

=head1 ABSTRACT

Encaseable Role for Perl 5

=cut

=head1 SYNOPSIS

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    return $self->encase('count', 1);
  }

  package main;

  my $example = Example->new;

  # bless({}, 'Example')

  # $example->execute;

  # 1

=cut

=head1 DESCRIPTION

This package modifies the consuming package and provides methods for storing,
retrieving, and removing private instance variables, via the C<private>
(masked) attribute. B<Note:> A pre-existing attribute or routine named
C<private> in the consuming package may cause unexpected issues. This role
differs from L<Venus::Role::Stashable> in that it provides getters and setters
to help obscure the private instance data, whereas Stashable does not.

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 clone

  clone() (object)

The clone method clones the invocant and returns the result.

I<Since C<4.15>>

=over 4

=item clone example 1

  # given: synopsis

  package main;

  my $clone = $example->clone;

  # bless(..., "Example")

=back

=cut

=head2 encase

  encase(string $key, any $value) (any)

The encase method associates and stashes the key and value provided with the
class instance and returns the value provided. If the key is already associated
the value is not overwritten.

I<Since C<4.15>>

=over 4

=item encase example 1

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    return $self->encase;
  }

  package main;

  my $example = Example->new;

  # bless({}, 'Example')

  # $example->execute;

  # undef

=back

=over 4

=item encase example 2

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    return $self->encase('count');
  }

  package main;

  my $example = Example->new;

  # bless({}, 'Example')

  # $example->execute;

  # undef

=back

=over 4

=item encase example 3

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    return $self->encase('count', 1);
  }

  package main;

  my $example = Example->new;

  # bless({}, 'Example')

  # $example->execute;

  # 1

=back

=over 4

=item encase example 4

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    my $count = 1;

    $count = $self->encase('count', $count);

    $count = $self->encase('count', $count + 1);

    $count = $self->encase('count', $count + 1);

    return $count;
  }

  package main;

  my $example = Example->new;

  # bless({}, 'Example')

  # $example->execute;

  # 1

=back

=over 4

=item encase example 5

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    my $count = 1;

    $count = $self->encase('count', $count);

    return $count;
  }

  package main;

  my $execute = Example->execute;

  # Exception! Venus::Fault

=back

=over 4

=item encase example 6

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    my $count = 1;

    $count = $self->encase('count', $count);

    return $count;
  }

  package main;

  my $example = Example->new;

  $example->encase('count', 1);

  # Exception! Venus::Fault

=back

=cut

=head2 encased

  encased(string $key) (any)

The encased method retrieves the value associated with the key provided,
associated and stashed with the class instance.

I<Since C<4.15>>

=over 4

=item encased example 1

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    return $self->encased;
  }

  package main;

  my $example = Example->new;

  # bless({}, 'Example')

  # $example->execute;

  # undef

=back

=over 4

=item encased example 2

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    return $self->encased('count');
  }

  package main;

  my $example = Example->new;

  # bless({}, 'Example')

  # $example->execute;

  # undef

=back

=over 4

=item encased example 3

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    $self->encase('count', 1);

    return $self->encased('count');
  }

  package main;

  my $example = Example->new;

  # bless({}, 'Example')

  # $example->execute;

  # 1

=back

=over 4

=item encased example 4

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    my $count = 1;

    $count = $self->recase('count', $count);

    $count = $self->recase('count', $count + 1);

    $count = $self->recase('count', $count + 1);

    return $self->encased('count');
  }

  package main;

  my $example = Example->new;

  # bless({}, 'Example')

  # $example->execute;

  # 3

=back

=over 4

=item encased example 5

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    return $self->encased('count');
  }

  package main;

  my $execute = Example->execute;

  # Exception! Venus::Fault

=back

=over 4

=item encased example 6

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    return $self->encased('count');
  }

  package main;

  my $example = Example->new;

  $example->encased('count');

  # Exception! Venus::Fault

=back

=cut

=head2 recase

  recase(string $key, any $value) (any)

The recase method associates and stashes the key and value provided with the
class instance and returns the value provided. The value is always overwritten.

I<Since C<4.15>>

=over 4

=item recase example 1

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    return $self->recase;
  }

  package main;

  my $example = Example->new;

  # bless({}, 'Example')

  # $example->execute;

  # undef

=back

=over 4

=item recase example 2

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    my $count = 1;

    $count = $self->encase('count', $count);

    return $self->recase('count', $count + 1);
  }

  package main;

  my $example = Example->new;

  # bless({}, 'Example')

  # $example->execute;

  # 2

=back

=over 4

=item recase example 3

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    my $count = 1;

    $count = $self->recase('count', $count);

    $count = $self->recase('count', $count + 1);

    $count = $self->recase('count', $count + 1);

    return $self->recase('count', $count + 1);
  }

  package main;

  my $example = Example->new;

  # bless({}, 'Example')

  # $example->execute;

  # 4

=back

=over 4

=item recase example 5

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    my $count = 1;

    $count = $self->recase('count', $count);

    return $count;
  }

  package main;

  my $execute = Example->execute;

  # Exception! Venus::Fault

=back

=cut

=head2 uncase

  uncase(string $key) (any)

The uncase method dissociatesthe key and its corresponding value from the class
instance and returns the value.

I<Since C<4.15>>

=over 4

=item uncase example 1

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    return $self->uncase;
  }

  package main;

  my $example = Example->new;

  # bless({}, 'Example')

  # $example->execute;

  # undef

=back

=over 4

=item uncase example 2

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    return $self->uncase('count');
  }

  package main;

  my $example = Example->new;

  # bless({}, 'Example')

  # $example->execute;

  # undef

=back

=over 4

=item uncase example 3

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    my $count = 1;

    $self->encase('count', $count);

    return $self->uncase('count');
  }

  package main;

  my $example = Example->new;

  # bless({}, 'Example')

  # $example->execute;

  # 1

=back

=over 4

=item uncase example 4

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    my $count = 1;

    $self->encase('count', $count);

    $count = $self->uncase('count');

    return $self->uncase('count');
  }

  package main;

  my $example = Example->new;

  # bless({}, 'Example')

  # $example->execute;

  # undef

=back

=over 4

=item uncase example 5

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    return $self->uncase('count');
  }

  package main;

  my $execute = Example->execute;

  # Exception! Venus::Fault

=back

=over 4

=item uncase example 6

  package Example;

  use Venus::Class 'with';

  with 'Venus::Role::Encaseable';

  sub execute {
    my ($self) = @_;

    return $self->uncase('count');
  }

  package main;

  my $example = Example->new;

  $example->uncase('count');

  # Exception! Venus::Fault

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