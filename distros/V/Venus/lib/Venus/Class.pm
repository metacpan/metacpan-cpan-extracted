package Venus::Class;

use 5.018;

use strict;
use warnings;

# IMPORTS

sub import {
  my ($self, @args) = @_;

  my $from = caller;

  require Venus::Core::Class;

  no strict 'refs';
  no warnings 'redefine';
  no warnings 'once';

  @args = grep defined && !ref && /^[A-Za-z]/, @args;

  my %exports = map +($_,$_), @args ? @args : qw(
    attr
    base
    false
    from
    mask
    mixin
    role
    test
    true
    with
  );

  @{"${from}::ISA"} = 'Venus::Core::Class';

  if ($exports{"attr"} && !*{"${from}::attr"}{"CODE"}) {
    *{"${from}::attr"} = sub {@_ = ($from, @_); goto \&attr};
  }
  if ($exports{"after"} && !*{"${from}::after"}{"CODE"}) {
    *{"${from}::after"} = sub ($$) {require Venus; goto \&Venus::after};
  }
  if ($exports{"around"} && !*{"${from}::around"}{"CODE"}) {
    *{"${from}::around"} = sub ($$) {require Venus; goto \&Venus::around};
  }
  if ($exports{"base"} && !*{"${from}::base"}{"CODE"}) {
    *{"${from}::base"} = sub {@_ = ($from, @_); goto \&base};
  }
  if ($exports{"before"} && !*{"${from}::before"}{"CODE"}) {
    *{"${from}::before"} = sub ($$) {require Venus; goto \&Venus::before};
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
  if ($exports{"handle"} && !*{"${from}::handle"}{"CODE"}) {
    *{"${from}::handle"} = sub ($$) {require Venus; goto \&Venus::handle};
  }
  if ($exports{"hook"} && !*{"${from}::hook"}{"CODE"}) {
    *{"${from}::hook"} = sub ($$$) {require Venus; goto \&Venus::hook};
  }
  if ($exports{"raise"} && !*{"${from}::raise"}{"CODE"}) {
    *{"${from}::raise"} = sub ($;$) {require Venus; goto \&Venus::raise};
  }
  if ($exports{"mask"} && !*{"${from}::mask"}{"CODE"}) {
    *{"${from}::mask"} = sub {@_ = ($from, @_); goto \&mask};
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

# ROUTINES

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

sub mask {
  my ($from, @args) = @_;

  $from->MASK(@args);

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

Venus::Class - Class Builder

=cut

=head1 ABSTRACT

Class Builder for Perl 5

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

This package provides a class builder which when used causes the consumer to
inherit from L<Venus::Core::Class> which provides object construction and
lifecycle L<hooks|Venus::Core>.

=cut

=head1 FUNCTIONS

This package provides the following functions:

=cut

=head2 after

  after(string $name, coderef $code) (coderef)

The after function installs a method modifier that executes after the original
method, allowing you to perform actions after a method call. B<Note:> The
return value of the modifier routine is ignored; the wrapped method always
returns the value from the original method. Modifiers are executed in the order
they are stacked. This function is only exported when requested.

I<Since C<4.15>>

=over 4

=item after example 1

  package Example1;

  use Venus::Class 'after', 'attr';

  attr 'calls';

  sub BUILD {
    my ($self) = @_;
    $self->calls([]);
  }

  sub test {
    my ($self) = @_;
    push @{$self->calls}, 'original';
    return 'original';
  }

  after 'test', sub {
    my ($self) = @_;
    push @{$self->calls}, 'after';
    return 'ignored';
  };

  package main;

  my $example = Example1->new;
  my $result = $example->test;

  # "original"

=back

=cut

=head2 around

  around(string $name, coderef $code) (coderef)

The around function installs a method modifier that wraps around the original
method. The callback provided will recieve the original routine as its first
argument. This function is only exported when requested.

I<Since C<4.15>>

=over 4

=item around example 1

  package Example2;

  use Venus::Class 'around', 'attr';

  sub test {
    my ($self, $value) = @_;
    return $value;
  }

  around 'test', sub {
    my ($orig, $self, $value) = @_;
    return $self->$orig($value) * 2;
  };

  package main;

  my $result = Example2->new->test(5);

  # 10

=back

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

=head2 before

  before(string $name, coderef $code) (coderef)

The before function installs a method modifier that executes before the
original method, allowing you to perform actions before a method call. B<Note:>
The return value of the modifier routine is ignored; the wrapped method always
returns the value from the original method. Modifiers are executed in the order
they are stacked. This function is only exported when requested.

I<Since C<4.15>>

=over 4

=item before example 1

  package Example3;

  use Venus::Class 'attr', 'before';

  attr 'calls';

  sub BUILD {
    my ($self) = @_;
    $self->calls([]);
  }

  sub test {
    my ($self) = @_;
    push @{$self->calls}, 'original';
    return $self;
  }

  before 'test', sub {
    my ($self) = @_;
    push @{$self->calls}, 'before';
    return $self;
  };

  package main;

  my $example = Example3->new;
  $example->test;
  my $calls = $example->calls;

  # ['before', 'original']

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

  package Example;

  use Venus::Class 'catch';

  sub attempt {
    catch {die};
  }

  package main;

  my $example = Example->new;

  my $error = $example->attempt;

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

  package Example;

  use Venus::Class 'error';

  sub attempt {
    error;
  }

  package main;

  my $example = Example->new;

  my $error = $example->attempt;

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

  use Venus::Class;

  sub AUDIT {
    my ($self, $from) = @_;
    die "Missing startup" if !$from->can('startup');
    die "Missing shutdown" if !$from->can('shutdown');
  }

  package Example;

  use Venus::Class;

  attr 'startup';
  attr 'shutdown';

  from 'Entity';

  # "Example"

=back

=cut

=head2 handle

  handle(string $name, coderef $code) (coderef)

The handle function installs a method modifier that wraps a method, providing
low-level control. The callback provided will recieve the original routine as
its first argument (or C<undef> if the source routine doesn't exist). This
function is only exported when requested.

I<Since C<4.15>>

=over 4

=item handle example 1

  package Example4;

  use Venus::Class 'attr', 'handle';

  sub test {
    my ($self, $value) = @_;
    return $value;
  }

  handle 'test', sub {
    my ($orig, $self, $value) = @_;
    return $orig ? $self->$orig($value * 2) : 0;
  };

  package main;

  my $result = Example4->new->test(5);

  # 10

=back

=cut

=head2 hook

  hook(string $type, string $name, coderef $code) (coderef)

The hook function installs a method modifier on a lifecycle hook method. The
first argument is the type of modifier desired, e.g., L</before>, L</after>,
L</around>, and the callback provided will recieve the original routine as its
first argument. This function is only exported when requested.

I<Since C<4.15>>

=over 4

=item hook example 1

  package Example5;

  use Venus::Class 'attr', 'hook';

  attr 'startup';

  sub BUILD {
    my ($self, $args) = @_;
    $self->startup('original');
  }

  hook 'after', 'build', sub {
    my ($self) = @_;
    $self->startup('modified');
  };

  package main;

  my $result = Example5->new->startup;

  # "modified"

=back

=cut

=head2 mask

  mask(string $name) (string)

The mask function creates private attribute accessors that can only be accessed
from within the class or its subclasses. This function is exported on-demand
unless a routine of the same name already exists.

I<Since C<4.15>>

=over 4

=item mask example 1

  package Example;

  use Venus::Class;

  mask 'secret';

  sub set_secret {
    my ($self, $value) = @_;
    $self->secret($value);
  }

  sub get_secret {
    my ($self) = @_;
    return $self->secret;
  }

  package main;

  my $example = Example->new;

  # $example->set_secret('...')

  # $example->get_secret

  # Exception! (if accessed externally)
  # $example->secret

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

  use Venus::Class;

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

  use Venus::Class;

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

  package Example;

  use Venus::Class 'raise';

  sub attempt {
    raise 'Example::Error';
  }

  package main;

  my $example = Example->new;

  my $error = $example->attempt;

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