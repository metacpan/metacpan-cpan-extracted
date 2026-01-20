package Venus::Module;

use 5.018;

use strict;
use warnings;

# IMPORTS

sub import {
  my ($self, @args) = @_;

  my $from = caller;

  require Venus::Core;

  no strict 'refs';
  no warnings 'redefine';
  no warnings 'once';

  @args = grep defined && !ref && /^[A-Za-z]/, @args;

  my %exports = map +($_,$_), @args ? @args : qw(
    false
    mixin
    role
    test
    true
    with
  );

  @{"${from}::ISA"} = 'Venus::Core';

  if ($exports{"after"} && !*{"${from}::after"}{"CODE"}) {
    *{"${from}::after"} = sub ($$) {require Venus; goto \&Venus::after};
  }
  if ($exports{"around"} && !*{"${from}::around"}{"CODE"}) {
    *{"${from}::around"} = sub ($$) {require Venus; goto \&Venus::around};
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
  if ($exports{"handle"} && !*{"${from}::handle"}{"CODE"}) {
    *{"${from}::handle"} = sub ($$) {require Venus; goto \&Venus::handle};
  }
  if ($exports{"hook"} && !*{"${from}::hook"}{"CODE"}) {
    *{"${from}::hook"} = sub ($$$) {require Venus; goto \&Venus::hook};
  }
  if (!*{"${from}::import"}{"CODE"}) {
    *{"${from}::import"} = sub {my $target = caller; $_[0]->USE($target); $_[0]->IMPORT($target, @_)};
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
  if (!*{"${from}::unimport"}{"CODE"}) {
    *{"${from}::unimport"} = sub {my $target = caller; $_[0]->UNIMPORT($target, @_)};
  }
  if ($exports{"with"} && !*{"${from}::with"}{"CODE"}) {
    *{"${from}::with"} = sub {@_ = ($from, @_); goto \&test};
  }

  ${"${from}::META"} = {};

  ${"${from}::@{[$from->METACACHE]}"} = undef;

  return $self;
}

# ROUTINES

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

Venus::Module - Module Builder

=cut

=head1 ABSTRACT

Module Builder for Perl 5

=cut

=head1 SYNOPSIS

  package MakeError;

  use Venus::Module;

  sub make_error {
    require Venus::Error;
    Venus::Error->new(@_);
  }

  sub EXPORT {
    # explicitly declare routines to be consumed
    ['make_error']
  }

  package main;

  BEGIN {
    MakeError->import;
  }

  my $error = make_error 'Oops';

  # bless({message => 'Oops'}, 'Venus::Error')

=cut

=head1 DESCRIPTION

This package provides a package/module builder which when used causes the
consumer to inherit from L<Venus::Core> which provides lifecycle
L<hooks|Venus::Core>.

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
they are stacked. This function is always exported unless a routine of the same
name already exists.

I<Since C<4.15>>

=over 4

=item after example 1

  package MakeError;

  use Venus::Module 'after';

  our $EVENTS = [];

  sub make_error {
    require Venus::Error;
    my $error = Venus::Error->new(@_);
    push @{$EVENTS}, 'orig';
    $error
  }

  after 'make_error', sub {
    push @{$EVENTS}, 'after';
  };

  sub EXPORT {
    # explicitly declare routines to be consumed
    ['make_error']
  }

  package main;

  MakeError->import;

  my $error = make_error 'Oops';

  # bless({message => 'Oops'}, 'Venus::Error')

=back

=cut

=head2 around

  around(string $name, coderef $code) (coderef)

The around function installs a method modifier that wraps around the original
method. The callback provided will recieve the original routine as its first
argument. This function is always exported unless a routine of the same name
already exists.

I<Since C<4.15>>

=over 4

=item around example 1

  package MakeError;

  use Venus::Module 'around';

  our $EVENTS = [];

  sub make_error {
    require Venus::Error;
    my $error = Venus::Error->new(@_);
    push @{$EVENTS}, 'orig';
    $error
  }

  around 'make_error', sub {
    my ($orig, @args) = @_;
    push @{$EVENTS}, 'before';
    my $result = $orig->(@args);
    push @{$EVENTS}, 'after';
    $result
  };

  sub EXPORT {
    # explicitly declare routines to be consumed
    ['make_error']
  }

  package main;

  MakeError->import;

  my $error = make_error 'Oops';

  # bless({message => 'Oops'}, 'Venus::Error')

=back

=cut

=head2 before

  before(string $name, coderef $code) (coderef)

The before function installs a method modifier that executes before the
original method, allowing you to perform actions before a method call. B<Note:>
The return value of the modifier routine is ignored; the wrapped method always
returns the value from the original method. Modifiers are executed in the order
they are stacked. This function is always exported unless a routine of the same
name already exists.

I<Since C<4.15>>

=over 4

=item before example 1

  package MakeError;

  use Venus::Module 'before';

  our $EVENTS = [];

  sub make_error {
    require Venus::Error;
    my $error = Venus::Error->new(@_);
    push @{$EVENTS}, 'orig';
    $error
  }

  before 'make_error', sub {
    push @{$EVENTS}, 'before';
  };

  sub EXPORT {
    # explicitly declare routines to be consumed
    ['make_error']
  }

  package main;

  MakeError->import;

  my $error = make_error 'Oops';

  # bless({message => 'Oops'}, 'Venus::Error')

=back

=cut

=head2 catch

  catch(coderef $block) (Venus::Error, any)

The catch function executes the code block trapping errors and returning the
caught exception in scalar context, and also returning the result as a second
argument in list context. This function isn't export unless requested.

I<Since C<4.15>>

=over 4

=item catch example 1

  package Example;

  use Venus::Module 'catch';

  sub attempt {
    catch {die};
  }

  package main;

  my $error = Example::attempt;

  $error;

  # "Died at ..."

=back

=cut

=head2 error

  error(maybe[hashref] $args) (Venus::Error)

The error function throws a L<Venus::Error> exception object using the
exception object arguments provided. This function isn't export unless
requested.

I<Since C<4.15>>

=over 4

=item error example 1

  package Example;

  use Venus::Module 'error';

  sub attempt {
    error;
  }

  package main;

  my $error = Example::attempt;

  # bless({...}, 'Venus::Error')

=back

=cut

=head2 false

  false() (boolean)

The false function returns a falsy boolean value which is designed to be
practically indistinguishable from the conventional numerical C<0> value. This
function is always exported unless a routine of the same name already exists.

I<Since C<4.15>>

=over 4

=item false example 1

  package Example;

  use Venus::Module;

  my $false = false;

  # 0

=back

=cut

=head2 handle

  handle(string $name, coderef $code) (coderef)

The handle function installs a method modifier that wraps a method, providing
low-level control. The callback provided will recieve the original routine as
its first argument (or C<undef> if the source routine doesn't exist). This
function is always exported unless a routine of the same name already exists.

I<Since C<4.15>>

=over 4

=item handle example 1

  package MakeError;

  use Venus::Module 'handle';

  our $EVENTS = [];

  handle 'make_error', sub {
    my ($orig, @args) = @_;
    push @{$EVENTS}, 'before';
    my $result = $orig->(@args) if $orig;
    push @{$EVENTS}, 'after';
    $result
  };

  sub EXPORT {
    # explicitly declare routines to be consumed
    ['make_error']
  }

  package main;

  MakeError->import;

  my $error = make_error 'Oops';

  # bless({message => 'Oops'}, 'Venus::Error')

=back

=over 4

=item handle example 2

  package MakeError;

  use Venus::Module 'handle';

  our $EVENTS = [];

  sub make_error {
    require Venus::Error;
    my $error = Venus::Error->new(@_);
    push @{$EVENTS}, 'orig';
    $error
  }

  handle 'make_error', sub {
    my ($orig, @args) = @_;
    push @{$EVENTS}, 'before';
    my $result = $orig->(@args) if $orig;
    push @{$EVENTS}, 'after';
    $result
  };

  sub EXPORT {
    # explicitly declare routines to be consumed
    ['make_error']
  }

  package main;

  MakeError->import;

  my $error = make_error 'Oops';

  # bless({message => 'Oops'}, 'Venus::Error')

=back

=cut

=head2 hook

  hook(string $type, string $name, coderef $code) (coderef)

The hook function installs a method modifier on a lifecycle hook method. The
first argument is the type of modifier desired, e.g., L</before>, L</after>,
L</around>, and the callback provided will recieve the original routine as its
first argument. This function is always exported unless a routine of the same
name already exists.

I<Since C<4.15>>

=over 4

=item hook example 1

  package MakeError;

  use Venus::Module 'hook';

  our $EVENTS = [];

  sub make_error {
    require Venus::Error;
    my $error = Venus::Error->new(@_);
    push @{$EVENTS}, 'orig';
    $error
  }

  hook 'around', 'use', sub {
    push @{$EVENTS}, 'use';
  };

  sub EXPORT {
    # explicitly declare routines to be consumed
    ['make_error']
  }

  package main;

  MakeError->import;

  my $error = make_error 'Oops';

  # bless({message => 'Oops'}, 'Venus::Error')

=back

=cut

=head2 mixin

  mixin(string $name) (string)

The mixin function registers and consumes mixins for the calling package. This
function is always exported unless a routine of the same name already exists.

I<Since C<4.15>>

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

  use Venus::Module;

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

  use Venus::Module;

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

I<Since C<4.15>>

=over 4

=item raise example 1

  package Example;

  use Venus::Module 'raise';

  sub attempt {
    raise 'Example::Error';
  }

  package main;

  my $error = Example::attempt;

  # bless({...}, 'Example::Error')

=back

=cut

=head2 role

  role(string $name) (string)

The role function registers and consumes roles for the calling package. This
function is always exported unless a routine of the same name already exists.

I<Since C<4.15>>

=over 4

=item role example 1

  package Ability;

  use Venus::Role;

  sub action {
    return;
  }

  package Example;

  use Venus::Module;

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

  use Venus::Module;

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

I<Since C<4.15>>

=over 4

=item test example 1

  package Actual;

  use Venus::Role;

  package Example;

  use Venus::Module;

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

  use Venus::Module;

  test 'Actual';

  # "Example"

=back

=cut

=head2 true

  true() (boolean)

The true function returns a truthy boolean value which is designed to be
practically indistinguishable from the conventional numerical C<1> value. This
function is always exported unless a routine of the same name already exists.

I<Since C<4.15>>

=over 4

=item true example 1

  package Example;

  use Venus::Module;

  my $true = true;

  # 1

=back

=over 4

=item true example 2

  package Example;

  use Venus::Module;

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

I<Since C<4.15>>

=over 4

=item with example 1

  package Understanding;

  use Venus::Role;

  sub knowledge {
    return;
  }

  package Example;

  use Venus::Module;

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

  use Venus::Module;

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