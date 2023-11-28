package Venus::Role;

use 5.018;

use strict;
use warnings;

# IMPORT

sub import {
  my ($self, @args) = @_;

  my $from = caller;

  require Venus::Core::Role;

  no strict 'refs';
  no warnings 'redefine';
  no warnings 'once';

  @args = grep defined && !ref && /^[A-Za-z]/, @args;

  my %exports = map +($_,$_), @args ? @args : qw(
    attr
    base
    false
    from
    mixin
    role
    test
    true
    with
  );

  @{"${from}::ISA"} = 'Venus::Core::Role';

  if ($exports{"attr"} && !*{"${from}::attr"}{"CODE"}) {
    *{"${from}::attr"} = sub {@_ = ($from, @_); goto \&attr};
  }
  if ($exports{"base"} && !*{"${from}::base"}{"CODE"}) {
    *{"${from}::base"} = sub {@_ = ($from, @_); goto \&base};
  }
  if ($exports{"catch"} && !*{"${from}::catch"}{"CODE"}) {
    *{"${from}::catch"} = sub (&) {require Venus; goto \&Venus::catch};
  }
  if ($exports{"error"} && !*{"${from}::error"}{"CODE"}) {
    *{"${from}::error"} = sub (;$) {require Venus; goto \&Venus::error};
  }
  if (!*{"${from}::false"}{"CODE"}) {
    *{"${from}::false"} = sub {require Venus; Venus::false()};
  }
  if ($exports{"fault"} && !*{"${from}::fault"}{"CODE"}) {
    *{"${from}::fault"} = sub (;$) {require Venus; goto \&Venus::fault};
  }
  if ($exports{"from"} && !*{"${from}::from"}{"CODE"}) {
    *{"${from}::from"} = sub {@_ = ($from, @_); goto \&from};
  }
  if ($exports{"raise"} && !*{"${from}::raise"}{"CODE"}) {
    *{"${from}::raise"} = sub ($;$) {require Venus; goto \&Venus::raise};
  }
  if ($exports{"mixin"} && !*{"${from}::mixin"}{"CODE"}) {
    *{"${from}::mixin"} = sub {@_ = ($from, @_); goto \&mixin};
  }
  if ($exports{"role"} && !*{"${from}::role"}{"CODE"}) {
    *{"${from}::role"} = sub {@_ = ($from, @_); goto \&role};
  }
  if ($exports{"test"} && !*{"${from}::test"}{"CODE"}) {
    *{"${from}::test"} = sub {@_ = ($from, @_); goto \&test};
  }
  if (!*{"${from}::true"}{"CODE"}) {
    *{"${from}::true"} = sub {require Venus; Venus::true()};
  }
  if ($exports{"with"} && !*{"${from}::with"}{"CODE"}) {
    *{"${from}::with"} = sub {@_ = ($from, @_); goto \&test};
  }

  ${"${from}::META"} = {};

  ${"${from}::@{[$from->METACACHE]}"} = undef;

  return $self;
}

sub attr {
  my ($from, @args) = @_;

  $from->ATTR(@args);

  return $from;
}

sub base {
  my ($from, @args) = @_;

  $from->BASE(@args);

  return $from;
}

sub from {
  my ($from, @args) = @_;

  $from->FROM(@args);

  return $from;
}

sub mixin {
  my ($from, @args) = @_;

  $from->MIXIN(@args);

  return $from;
}

sub role {
  my ($from, @args) = @_;

  $from->ROLE(@args);

  return $from;
}

sub test {
  my ($from, @args) = @_;

  $from->TEST(@args);

  return $from;
}

1;



=head1 NAME

Venus::Role - Role Builder

=cut

=head1 ABSTRACT

Role Builder for Perl 5

=cut

=head1 SYNOPSIS

  package Person;

  use Venus::Class 'attr';

  attr 'fname';
  attr 'lname';

  package Identity;

  use Venus::Role 'attr';

  attr 'id';
  attr 'login';
  attr 'password';

  sub EXPORT {
    # explicitly declare routines to be consumed
    ['id', 'login', 'password']
  }

  package Authenticable;

  use Venus::Role;

  sub authenticate {
    return true;
  }

  sub AUDIT {
    my ($self, $from) = @_;
    # ensure the caller has a login and password when consumed
    die "${from} missing the login attribute" if !$from->can('login');
    die "${from} missing the password attribute" if !$from->can('password');
  }

  sub BUILD {
    my ($self, $data) = @_;
    $self->{auth} = undef;
    return $self;
  }

  sub EXPORT {
    # explicitly declare routines to be consumed
    ['authenticate']
  }

  package User;

  use Venus::Class;

  base 'Person';

  with 'Identity';

  attr 'email';

  test 'Authenticable';

  sub valid {
    my ($self) = @_;
    return $self->login && $self->password ? true : false;
  }

  package main;

  my $user = User->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  # bless({fname => 'Elliot', lname => 'Alderson'}, 'User')

=cut

=head1 DESCRIPTION

This package provides a role builder which when used causes the consumer to
inherit from L<Venus::Core::Role> which provides role construction and
lifecycle L<hooks|Venus::Core>. A role differs from a L<"class"|Venus::Class>
in that it can't be instantiated using the C<new> method. A role can act as an
interface by defining an L<"audit"|Venus::Core/AUDIT> hook which is invoked
automatically by the L<"test"|Venus::Class/test> function.

=cut

=head1 FUNCTIONS

This package provides the following functions:

=cut

=head2 attr

  attr(string $name) (string)

The attr function creates attribute accessors for the calling package. This
function is always exported unless a routine of the same name already exists.

I<Since C<1.00>>

=over 4

=item attr example 1

  package Example;

  use Venus::Class;

  attr 'name';

  # "Example"

=back

=cut

=head2 base

  base(string $name) (string)

The base function registers one or more base classes for the calling package.
This function is always exported unless a routine of the same name already
exists.

I<Since C<1.00>>

=over 4

=item base example 1

  package Entity;

  use Venus::Class;

  sub output {
    return;
  }

  package Example;

  use Venus::Class;

  base 'Entity';

  # "Example"

=back

=cut

=head2 catch

  catch(coderef $block) (Venus::Error, any)

The catch function executes the code block trapping errors and returning the
caught exception in scalar context, and also returning the result as a second
argument in list context. This function isn't export unless requested.

I<Since C<1.01>>

=over 4

=item catch example 1

  package Ability;

  use Venus::Role 'catch';

  sub attempt_catch {
    catch {die};
  }

  sub EXPORT {
    ['attempt_catch']
  }

  package Example;

  use Venus::Class 'with';

  with 'Ability';

  package main;

  my $example = Example->new;

  my $error = $example->attempt_catch;

  $error;

  # "Died at ..."

=back

=cut

=head2 error

  error(maybe[hashref] $args) (Venus::Error)

The error function throws a L<Venus::Error> exception object using the
exception object arguments provided. This function isn't export unless requested.

I<Since C<1.01>>

=over 4

=item error example 1

  package Ability;

  use Venus::Role 'error';

  sub attempt_error {
    error;
  }

  sub EXPORT {
    ['attempt_error']
  }

  package Example;

  use Venus::Class 'with';

  with 'Ability';

  package main;

  my $example = Example->new;

  my $error = $example->attempt_error;

  # bless({...}, 'Venus::Error')

=back

=cut

=head2 false

  false() (boolean)

The false function returns a falsy boolean value which is designed to be
practically indistinguishable from the conventional numerical C<0> value. This
function is always exported unless a routine of the same name already exists.

I<Since C<1.00>>

=over 4

=item false example 1

  package Example;

  use Venus::Class;

  my $false = false;

  # 0

=back

=over 4

=item false example 2

  package Example;

  use Venus::Class;

  my $true = !false;

  # 1

=back

=cut

=head2 from

  from(string $name) (string)

The from function registers one or more base classes for the calling package
and performs an L<"audit"|Venus::Core/AUDIT>. This function is always exported
unless a routine of the same name already exists.

I<Since C<1.00>>

=over 4

=item from example 1

  package Entity;

  use Venus::Role;

  attr 'startup';
  attr 'shutdown';

  sub EXPORT {
    ['startup', 'shutdown']
  }

  package Record;

  use Venus::Class;

  sub AUDIT {
    my ($self, $from) = @_;
    die "Missing startup" if !$from->can('startup');
    die "Missing shutdown" if !$from->can('shutdown');
  }

  package Example;

  use Venus::Class;

  with 'Entity';

  from 'Record';

  # "Example"

=back

=cut

=head2 mixin

  mixin(string $name) (string)

The mixin function registers and consumes mixins for the calling package. This
function is always exported unless a routine of the same name already exists.

I<Since C<1.02>>

=over 4

=item mixin example 1

  package YesNo;

  use Venus::Mixin;

  sub no {
    return 0;
  }

  sub yes {
    return 1;
  }

  sub EXPORT {
    ['no', 'yes']
  }

  package Answer;

  use Venus::Role;

  mixin 'YesNo';

  # "Answer"

=back

=over 4

=item mixin example 2

  package YesNo;

  use Venus::Mixin;

  sub no {
    return 0;
  }

  sub yes {
    return 1;
  }

  sub EXPORT {
    ['no', 'yes']
  }

  package Answer;

  use Venus::Role;

  mixin 'YesNo';

  sub no {
    return [0];
  }

  sub yes {
    return [1];
  }

  my $package = "Answer";

  # "Answer"

=back

=cut

=head2 raise

  raise(string $class | tuple[string, string] $class, maybe[hashref] $args) (Venus::Error)

The raise function generates and throws a named exception object derived from
L<Venus::Error>, or provided base class, using the exception object arguments
provided. This function isn't export unless requested.

I<Since C<1.01>>

=over 4

=item raise example 1

  package Ability;

  use Venus::Role 'raise';

  sub attempt_raise {
    raise 'Example::Error';
  }

  sub EXPORT {
    ['attempt_raise']
  }

  package Example;

  use Venus::Class 'with';

  with 'Ability';

  package main;

  my $example = Example->new;

  my $error = $example->attempt_raise;

  # bless({...}, 'Example::Error')

=back

=cut

=head2 role

  role(string $name) (string)

The role function registers and consumes roles for the calling package. This
function is always exported unless a routine of the same name already exists.

I<Since C<1.00>>

=over 4

=item role example 1

  package Ability;

  use Venus::Role;

  sub action {
    return;
  }

  package Example;

  use Venus::Class;

  role 'Ability';

  # "Example"

=back

=over 4

=item role example 2

  package Ability;

  use Venus::Role;

  sub action {
    return;
  }

  sub EXPORT {
    return ['action'];
  }

  package Example;

  use Venus::Class;

  role 'Ability';

  # "Example"

=back

=cut

=head2 test

  test(string $name) (string)

The test function registers and consumes roles for the calling package and
performs an L<"audit"|Venus::Core/AUDIT>, effectively allowing a role to act as
an interface. This function is always exported unless a routine of the same
name already exists.

I<Since C<1.00>>

=over 4

=item test example 1

  package Actual;

  use Venus::Role;

  package Example;

  use Venus::Class;

  test 'Actual';

  # "Example"

=back

=over 4

=item test example 2

  package Actual;

  use Venus::Role;

  sub AUDIT {
    die "Example is not an 'actual' thing" if $_[1]->isa('Example');
  }

  package Example;

  use Venus::Class;

  test 'Actual';

  # "Example"

=back

=cut

=head2 true

  true() (boolean)

The true function returns a truthy boolean value which is designed to be
practically indistinguishable from the conventional numerical C<1> value. This
function is always exported unless a routine of the same name already exists.

I<Since C<1.00>>

=over 4

=item true example 1

  package Example;

  use Venus::Class;

  my $true = true;

  # 1

=back

=over 4

=item true example 2

  package Example;

  use Venus::Class;

  my $false = !true;

  # 0

=back

=cut

=head2 with

  with(string $name) (string)

The with function registers and consumes roles for the calling package. This
function is an alias of the L</test> function and will perform an
L<"audit"|Venus::Core/AUDIT> if present. This function is always exported
unless a routine of the same name already exists.

I<Since C<1.00>>

=over 4

=item with example 1

  package Understanding;

  use Venus::Role;

  sub knowledge {
    return;
  }

  package Example;

  use Venus::Class;

  with 'Understanding';

  # "Example"

=back

=over 4

=item with example 2

  package Understanding;

  use Venus::Role;

  sub knowledge {
    return;
  }

  sub EXPORT {
    return ['knowledge'];
  }

  package Example;

  use Venus::Class;

  with 'Understanding';

  # "Example"

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