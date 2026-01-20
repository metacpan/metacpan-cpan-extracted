package Venus::Hook;

use 5.018;

use strict;
use warnings;

use Hash::Util::FieldHash;

no warnings 'once';

# HOOKS

# ARGS hook
sub ARGS {
  my ($self, @args) = @_;

  return (!@args)
    ? ($self->DATA)
    : ((@args == 1 && ref($args[0]) eq 'HASH')
    ? (do{my %args = %{$args[0]}; !CORE::keys(%args) ? $self->DATA : {%args}})
    : (@args % 2 ? {@args, undef} : {@args}));
}

# ATTR hook
sub ATTR {
  my ($self, $attr, @args) = @_;

  no strict 'refs';

  no warnings 'redefine';

  *{"@{[$self->NAME]}::$attr"} = sub {$_[0]->ITEM($attr, @_[1..$#_])}
    if !$self->can($attr);

  my $index = int(keys(%{$${"@{[$self->NAME]}::META"}{ATTR}})) + 1;

  $${"@{[$self->NAME]}::META"}{ATTR}{$attr} = [$index, [$attr, @args]];

  my $metacache = join '::', $self->NAME, $self->METACACHE;

  ${$metacache} = undef;

  return $self;
}

# AUDIT hook
sub AUDIT {
  my ($self) = @_;

  return $self;
}

# BASE hook
sub BASE {
  my ($self, $base, @args) = @_;

  no strict 'refs';

  if (!grep !/\A[^:]+::\z/, keys(%{"${base}::"})) {
    local $@; eval "require $base"; do{require Venus; Venus::fault($@)} if $@;
  }

  @{"@{[$self->NAME]}::ISA"} = (
    $base, (grep +($_ ne $base), @{"@{[$self->NAME]}::ISA"})
  );

  my $index = int(keys(%{$${"@{[$self->NAME]}::META"}{BASE}})) + 1;

  $${"@{[$self->NAME]}::META"}{BASE}{$base} = [$index, [$base, @args]];

  my $metacache = join '::', $self->NAME, $self->METACACHE;

  ${$metacache} = undef;

  return $self;
}

# BLESS hook
sub BLESS {
  my ($self, @args) = @_;

  my $name = $self->NAME;
  my $data = $self->DATA($self->ARGS($self->BUILDARGS(@args)));
  my $anew = bless($data, $name);

  no strict 'refs';

  $anew->BUILD($data);

  $anew->CONSTRUCT;

  return $anew if $name eq 'Venus::Meta';

  require Venus::Meta;

  my $metacache = join '::', $self->NAME, $self->METACACHE;

  ${$metacache} ||= Venus::Meta->new(name => $name);

  return $anew;
}

# BUILD hook
sub BUILD {
  my ($self) = @_;

  return $self;
}

# BUILD hook handler for class
sub BUILD_FOR_CLASS {
  my ($self, @data) = @_;

  no strict 'refs';

  my @roles = @{$self->META->roles};

  for my $action (grep defined, map *{"${_}::BUILD"}{"CODE"}, @roles) {
    $self->$action(@data);
  }

  return $self;
}

# BUILD hook handler for role
sub BUILD_FOR_ROLE {
  my ($self, @data) = @_;

  no strict 'refs';

  my @roles = @{$self->META->roles};

  for my $action (grep defined, map *{"${_}::BUILD"}{"CODE"}, @roles) {
    $self->$action(@data);
  }

  return $self;
}

# BUILD hook handler for mixin
sub BUILD_FOR_MIXIN {
  my ($self) = @_;

  return $self;
}

# BUILDARGS hook
sub BUILDARGS {
  my ($self, @args) = @_;

  return (@args);
}

# CONSTRUCT hook
sub CONSTRUCT {
  my ($self) = @_;

  return $self;
}

# CONSTRUCT hook handler for class
sub CONSTRUCT_FOR_CLASS {
  my ($self, @data) = @_;

  no strict 'refs';

  my @mixins = @{$self->META->mixins};

  for my $action (grep defined, map *{"${_}::CONSTRUCT"}{"CODE"}, @mixins) {
    $self->$action(@data);
  }

  my @roles = @{$self->META->roles};

  for my $action (grep defined, map *{"${_}::CONSTRUCT"}{"CODE"}, @roles) {
    $self->$action(@data);
  }

  return $self;
}

# CONSTRUCT hook handler for role
sub CONSTRUCT_FOR_ROLE {
}

# CONSTRUCT hook handler for mixin
sub CONSTRUCT_FOR_MIXIN {
}

# CLONE hook
sub CLONE {
  my ($self) = @_;

  require Scalar::Util;

  if (!Scalar::Util::blessed($self)) {
    require Venus;

    Venus::fault("Can't clone without an instance of \"${self}\"");
  }

  require Storable;

  no warnings 'once';

  local $Storable::Deparse = 1;

  local $Storable::Eval = 1;

  my $clone = Storable::dclone($self);

  my $store = $self->STORE;

  my $instance = $store->{$clone} = Storable::dclone($store->{$self} ||= {});

  return $clone;
}

# DATA hook
sub DATA {
  my ($self, $data) = @_;

  return $data || {};
}

# DECONSTRUCT hook
sub DECONSTRUCT {
  my ($self) = @_;

  return $self;
}

# DECONSTRUCT hook handler for class
sub DECONSTRUCT_FOR_CLASS {
  my ($self, @data) = @_;

  no strict 'refs';

  my @mixins = @{$self->META->mixins};

  for my $action (grep defined, map *{"${_}::DECONSTRUCT"}{"CODE"}, @mixins) {
    $self->$action(@data);
  }

  my @roles = @{$self->META->roles};

  for my $action (grep defined, map *{"${_}::DECONSTRUCT"}{"CODE"}, @roles) {
    $self->$action(@data);
  }

  return $self;
}

# DECONSTRUCT hook handler for role
sub DECONSTRUCT_FOR_ROLE {
}

# DECONSTRUCT hook handler for mixin
sub DECONSTRUCT_FOR_MIXIN {
}

# DESTROY hook
sub DESTROY {
  my ($self) = @_;

  $self->DECONSTRUCT;

  return $self;
}

# DESTROY hook handler for class
sub DESTROY_FOR_CLASS {
  my ($self, @data) = @_;

  no strict 'refs';

  my @mixins = @{$self->META->mixins};

  for my $action (grep defined, map *{"${_}::DESTROY"}{"CODE"}, @mixins) {
    $self->$action(@data);
  }

  my @roles = @{$self->META->roles};

  for my $action (grep defined, map *{"${_}::DESTROY"}{"CODE"}, @roles) {
    $self->$action(@data);
  }

  return $self;
}

# DESTROY hook handler for role
sub DESTROY_FOR_ROLE {
  my ($self, @data) = @_;

  no strict 'refs';

  my @mixins = @{$self->META->mixins};

  for my $action (grep defined, map *{"${_}::DESTROY"}{"CODE"}, @mixins) {
    $self->$action(@data);
  }

  my @roles = @{$self->META->roles};

  for my $action (grep defined, map *{"${_}::DESTROY"}{"CODE"}, @roles) {
    $self->$action(@data);
  }

  return $self;
}

# DESTROY hook handler for mixin
sub DESTROY_FOR_MIXIN {
  my ($self) = @_;

  return;
}

# DOES hook
sub DOES {
  my ($self, $role) = @_;

  return if !$role;

  return $self->META->role($role);
}

# EXPORT hook
sub EXPORT {
  my ($self, $into) = @_;

  no strict;
  no warnings 'once';

  return [@{"${self}::EXPORT"}];
}

# EXPORT hook handler for class
sub EXPORT_FOR_CLASS {
  my ($self, $into) = @_;

  no strict;
  no warnings 'once';

  return [@{"${self}::EXPORT"}];
}

# EXPORT hook handler for role
sub EXPORT_FOR_ROLE {
  my ($self, $into) = @_;

  no strict;
  no warnings 'once';

  return [@{"${self}::EXPORT"}];
}

# EXPORT hook handler for mixin
sub EXPORT_FOR_MIXIN {
  my ($self, $into) = @_;

  no strict;
  no warnings 'once';

  return [@{"${self}::EXPORT"}];
}

# FROM hook
sub FROM {
  my ($self, $base) = @_;

  $self->BASE($base);

  $base->AUDIT($self->NAME) if $base->can('AUDIT');

  no warnings 'redefine';

  $base->IMPORT($self->NAME);

  return $self;
}

# GET hook
sub GET {
  my ($self, $name) = @_;

  return $self->{$name};
}

# IMPORT hook
sub IMPORT {
  my ($self, $into) = @_;

  no strict 'refs';
  no warnings 'redefine';

  for my $name (@{$self->EXPORT($into)}) {
    *{"${into}::${name}"} = \&{"@{[$self->NAME]}::${name}"};
  }

  return $self;
}

# IMPORT hook handler for class
sub IMPORT_FOR_CLASS {
  my ($self, $into) = @_;

  no strict 'refs';
  no warnings 'redefine';

  for my $name (@{$self->EXPORT($into)}) {
    *{"${into}::${name}"} = \&{"@{[$self->NAME]}::${name}"};
  }

  return $self;
}

# IMPORT hook handler for role
sub IMPORT_FOR_ROLE {
  my ($self, $into) = @_;

  no strict 'refs';
  no warnings 'redefine';

  for my $name (grep !*{"${into}::${_}"}{"CODE"}, @{$self->EXPORT($into)}) {
    *{"${into}::${name}"} = \&{"@{[$self->NAME]}::${name}"};
  }

  return $self;
}

# IMPORT hook handler for mixin
sub IMPORT_FOR_MIXIN {
  my ($self, $into) = @_;

  no strict 'refs';
  no warnings 'redefine';

  for my $name (@{$self->EXPORT($into)}) {
    *{"${into}::${name}"} = \&{"@{[$self->NAME]}::${name}"};
  }

  return $self;
}

# ITEM hook
sub ITEM {
  my ($self, $name, @args) = @_;

  return $name ? (@args ? $self->SET($name, $args[0]) : $self->GET($name)) : undef;
}

# META hook
sub META {
  my ($self) = @_;

  no strict 'refs';

  require Venus::Meta;

  my $metacache = join '::', my $name = $self->NAME, $self->METACACHE;

  return ${$metacache} ||= Venus::Meta->new(name => $name);
}

# METACACHE cache name (for META hook)
sub METACACHE {
  my ($self) = @_;

  return 'METACACHE';
}

# MIXIN hook
sub MIXIN {
  my ($self, $mixin, @args) = @_;

  no strict 'refs';

  if (!grep !/\A[^:]+::\z/, keys(%{"${mixin}::"})) {
    local $@; eval "require $mixin"; do{require Venus; Venus::fault($@)} if $@;
  }

  no warnings 'redefine';

  $mixin->IMPORT($self->NAME);

  no strict 'refs';

  my $index = int(keys(%{$${"@{[$self->NAME]}::META"}{MIXIN}})) + 1;

  $${"@{[$self->NAME]}::META"}{MIXIN}{$mixin} = [$index, [$mixin, @args]];

  my $metacache = join '::', $self->NAME, $self->METACACHE;

  ${$metacache} = undef;

  return $self;
}

# MASK hook
sub MASK {
  my ($self, $mask, @args) = @_;

  no strict 'refs';

  no warnings 'redefine';

  my $store = $self->STORE;

  *{"@{[$self->NAME]}::$mask"} = sub {
    my ($self, @args) = @_;

    my $caller = caller;

    require Scalar::Util;

    if (!Scalar::Util::blessed($self)) {
      require Venus;

      Venus::fault(
        "Can't get/set private variable \"${mask}\" without an instance of \"${self}\""
      );
    }

    my $class = ref $self;

    if ($caller ne $class && !$class->isa($caller)) {
      my $authorized = 0;

      no strict 'refs';
      no warnings 'once';

      if (${"${caller}::META"} && $${"${caller}::META"}{MASK}{$mask}) {
        require Venus::Meta;

        my $meta = Venus::Meta->new(name => $class);

        if ($meta->role($caller) || $meta->mixin($caller)) {
          $authorized = 1;
        }
      }

      if (!$authorized) {
        require Venus;

        Venus::fault(
          "Can't get/set private variable \"${mask}\" outside the class or subclass of \"${class}\""
        );
      }
    }

    no warnings 'once';

    my $variable = $store->{$self} ||= {};

    return @args ? ($variable->{$mask} = $args[0]) : $variable->{$mask};
  }
  if !$self->can($mask);

  my $index = int(keys(%{$${"@{[$self->NAME]}::META"}{MASK}})) + 1;

  $${"@{[$self->NAME]}::META"}{MASK}{$mask} = [$index, [$mask, @args]];

  my $metacache = join '::', $self->NAME, $self->METACACHE;

  ${$metacache} = undef;

  return $self;
}

# NAME hook
sub NAME {
  my ($self) = @_;

  return ref $self || $self;
}

# ROLE hook
sub ROLE {
  my ($self, $role, @args) = @_;

  no strict 'refs';

  if (!grep !/\A[^:]+::\z/, keys(%{"${role}::"})) {
    local $@; eval "require $role"; do{require Venus; Venus::fault($@)} if $@;
  }

  no warnings 'redefine';

  $role->IMPORT($self->NAME);

  no strict 'refs';

  my $index = int(keys(%{$${"@{[$self->NAME]}::META"}{ROLE}})) + 1;

  $${"@{[$self->NAME]}::META"}{ROLE}{$role} = [$index, [$role, @args]];

  my $metacache = join '::', $self->NAME, $self->METACACHE;

  ${$metacache} = undef;

  return $self;
}

# SET hook
sub SET {
  my ($self, $name, $data) = @_;

  return $self->{$name} = $data;
}

# STORE for private data (for MASK hook)
sub STORE {
  my ($self) = @_;

  no strict 'refs';

  no warnings 'once';

  state $cache = {};

  my $caller = caller;

  if (!$cache->{$self->NAME}) {
    my $name = 'STORE';

    for my $class ($self->NAME, $self->META->bases) {
      if (ref ${"${class}::${name}"}) {
        $cache->{$self->NAME} = ${"${class}::${name}"};
        last;
      }
    }

    if (!$cache->{$self->NAME}) {
      Hash::Util::FieldHash::fieldhash(my %data);

      $cache->{$self->NAME} = ${"@{[$self->NAME]}::${name}"} = \%data;
    }
  }

  return $cache->{$self->NAME} if $caller eq __PACKAGE__;

  require Scalar::Util;

  if (!Scalar::Util::blessed($self)) {
    require Venus;
    Venus::fault(
      "Can't access STORE from \"${caller}\""
    );
  }

  my $class = ref $self;

  return $cache->{$self->NAME} if $caller eq $class || $class->isa($caller);

  require Venus::Meta;

  my $meta = Venus::Meta->new(name => $class);

  if ($meta->role($caller) || $meta->mixin($caller)) {
    return $cache->{$self->NAME};
  }

  require Venus;

  Venus::fault(
    "Can't access STORE outside the class or subclass of \"${class}\""
  );
}

# SUBS hook
sub SUBS {
  my ($self) = @_;

  no strict 'refs';

  return [
    sort grep *{"@{[$self->NAME]}::$_"}{"CODE"},
    grep /^[_a-zA-Z]\w*$/, keys %{"@{[$self->NAME]}::"}
  ];
}

# TEST hook
sub TEST {
  my ($self, $role) = @_;

  $self->ROLE($role);

  $role->AUDIT($self->NAME) if $role->can('AUDIT');

  return $self;
}

# UNIMPORT hook
sub UNIMPORT {
  my ($self, $into, @args) = @_;

  return $self;
}

# USE hook
sub USE {
  my ($self, $into, @args) = @_;

  return $self;
}

1;


=head1 NAME

Venus::Hook - Venus Lifecycle Hooks

=cut

=head1 ABSTRACT

Lifecycle Hooks for Perl 5

=cut

=head1 SYNOPSIS

  package User;

  use base 'Venus::Core';

  # Define attributes
  User->ATTR('name');
  User->ATTR('email');

  # Post-construction initialization
  sub BUILD {
    my ($self) = @_;
    $self->{created} = time;
    return $self;
  }

  # Pre-destruction cleanup
  sub DECONSTRUCT {
    my ($self) = @_;
    $self->log("User destroyed");
    return $self;
  }

  package main;

  my $user = User->BLESS(name => 'Elliot', email => 'e@example.com');

  # bless({name => 'Elliot', email => 'e@example.com', created => ...}, 'User')

=cut

=head1 DESCRIPTION

This document provides a comprehensive reference for all lifecycle hooks
available in the Venus OOP framework. Venus provides a rich set of hooks that
allow you to customize class building, object construction, and object
destruction behavior.

Venus lifecycle hooks are special methods that are automatically invoked at
specific points during class building, object construction, and object
destruction. These hooks provide extension points for customizing behavior
without modifying core Venus code. Hooks are conventionally named in UPPERCASE
to distinguish them from regular methods.

=cut

=head1 SUPER

B<When overriding lifecycle hooks in a subclass, you should almost always call
the parent implementation using C<SUPER>>, or risk breaking the framework in
unexpected ways.

The Venus framework relies on proper hook execution throughout the inheritance
chain. Failing to call the parent implementation can break functionality in
subtle ways, including:

=over 4

=item * Breaking role/mixin composition and their lifecycle hooks

=item * Skipping critical initialization or cleanup code from parent classes

=item * Bypassing framework-level validations and setup

=item * Causing memory leaks by not cleaning up instance data properly

=back

=head2 Required

When overriding any of the following hooks, you should call C<SUPER> unless you
have a very specific reason not to:

  ARGS, ATTR, AUDIT, BASE, BLESS, BUILD, BUILDARGS, CONSTRUCT, CLONE,
  DECONSTRUCT, DESTROY, DOES, EXPORT, FROM, GET, IMPORT, ITEM, META,
  MIXIN, MASK, NAME, ROLE, SET, SUBS, TEST, UNIMPORT, USE

=head2 Correct Pattern

B<Always call the parent implementation first, then add your custom logic:>

  package Child;

  use base 'Parent';

  sub BUILD {
    my ($self, $data) = @_;

    # CRITICAL: Call parent implementation first
    $self->SUPER::BUILD($data);

    # Then add your custom logic
    $self->{child_field} = 'value';

    return $self;
  }

=head2 Incorrect Pattern

B<DO NOT skip the SUPER call:>

  # WRONG - This breaks the framework!
  sub BUILD {
    my ($self, $data) = @_;

    # Missing: $self->SUPER::BUILD($data);

    $self->{child_field} = 'value';  # Parent's BUILD never runs!

    return $self;
  }

=head2 When You Might Skip SUPER

There are very rare cases where you might intentionally skip calling SUPER:

=over 4

=item * You are B<replacing> the parent's behavior entirely (use with extreme caution)

=item * You are implementing a base hook that has no parent (e.g., in Venus::Core itself)

=item * You are implementing certain introspection hooks like C<DATA> that are meant to be completely overridden

=back

B<Rule of thumb:> If you're unsure whether to call SUPER, B<call it>. It's almost
always the right choice.

=cut

=head1 HOOKS

This package provides the following hooks:

=cut

=head2 Object Construction Hooks

These hooks control how objects are constructed and initialized.

=over 4

=item args

  ARGS(any @args) (hashref)

The ARGS hook accepts constructor arguments and returns a blessable data
structure. It is called during object construction, before blessing.

I<Since C<1.00>>

=over 4

=item args example 1

  package List;

  use base 'Venus::Core';

  sub ARGS {
    my ($self, @args) = @_;

    return @args
      ? ((@args == 1 && ref $args[0] eq 'ARRAY') ? @args : [@args])
      : $self->DATA;
  }

  package main;

  my $list = List->BLESS(1..4);

  # bless([1..4], 'List')

=back

=cut

=item bless

  BLESS(any @args) (object)

The BLESS hook is the main object construction hook that creates and returns an
instance. It is called when you call the constructor (or C<BLESS> directly).
The default behavior is equivalent to calling C<BUILD(bless(ARGS(BUILDARGS(@args)
|| DATA), $class))>.

I<Since C<1.00>>

=over 4

=item bless example 1

  package User;

  use base 'Venus::Core';

  package main;

  my $user = User->BLESS(name => 'Elliot');

  # bless({name => 'Elliot'}, 'User')

=back

=cut

=item buildargs

  BUILDARGS(any @args) (any @args | hashref $data)

The BUILDARGS hook pre-processes constructor arguments before they are converted
to a data structure. It is called before C<ARGS>, and receives raw constructor
arguments.

I<Since C<1.00>>

=over 4

=item buildargs example 1

  package User;

  use base 'Venus::Core';

  sub BUILDARGS {
    my ($self, @args) = @_;

    # Convert single string arg to hashref
    my $data = @args == 1 && !ref $args[0] ? {name => $args[0]} : {};

    return $data;
  }

  package main;

  my $user = User->BLESS('Elliot');

  # bless({name => 'Elliot'}, 'User')

=back

=cut

=item build

  BUILD(hashref $data) (object)

The BUILD hook is a post-construction initialization hook. It receives the
blessed object and can modify it. It is called after the object is blessed,
before it's returned to the caller. While the return value is ignored by
C<BLESS>, it should return C<$self> for chaining.

B<Note:> When inheriting, you should call the parent's BUILD using
C<$self-E<gt>SUPER::BUILD($data)>.

I<Since C<1.00>>

=over 4

=item build example 1

  package User;

  use base 'Venus::Core';

  sub BUILD {
    my ($self) = @_;

    $self->{name} = 'Mr. Robot';

    return $self;
  }

  package main;

  my $user = User->BLESS(name => 'Elliot');

  # bless({name => 'Mr. Robot'}, 'User')

=back

=over 4

=item build example 2

  package Elliot;

  use base 'User';

  sub BUILD {
    my ($self, $data) = @_;

    $self->SUPER::BUILD($data);

    $self->{name} = 'Elliot';

    return $self;
  }

  package main;

  my $user = Elliot->BLESS;

  # bless({name => 'Elliot'}, 'Elliot')

=back

=cut

=item construct

  CONSTRUCT() (any)

The CONSTRUCT hook is an additional post-construction hook for instance
preparation, separate from the build process. It is called automatically after
C<BLESS>, without arguments. The return value is not used in subsequent
processing.

I<Since C<4.15>>

=over 4

=item construct example 1

  package User;

  use base 'Venus::Core';

  sub CONSTRUCT {
    my ($self) = @_;

    $self->{ready} = 1;

    return $self;
  }

  package main;

  my $user = User->BLESS(name => 'Elliot');

  # bless({name => 'Elliot', ready => 1}, 'User')

=back

=cut

=item data

  DATA() (Ref)

The DATA hook returns the default data structure to bless when no arguments are
provided. It is called during object construction when no arguments are given.
The default implementation returns an empty hashref C<{}>.

I<Since C<1.00>>

=over 4

=item data example 1

  package Example;

  use base 'Venus::Core';

  sub DATA {
    return [];  # Use arrayref instead of hashref
  }

  package main;

  my $example = Example->BLESS;

  # bless([], 'Example')

=back

=cut

=item clone

  CLONE() (object)

The CLONE hook creates a deep clone of the invocant. It is called when you call
C<clone> or C<CLONE>. It must be called on an object instance (not a class).
Private data (from C<MASK>) is not included in the clone.

I<Since C<4.15>>

=over 4

=item clone example 1

  package User;

  use base 'Venus::Core';

  User->MASK('password');

  sub get_password {
    my ($self) = @_;
    $self->password;
  }

  sub set_password {
    my ($self) = @_;
    $self->password('secret');
  }

  package main;

  my $user = User->BLESS(name => 'Elliot');
  $user->set_password;

  my $clone = $user->CLONE;

  # bless({name => 'Elliot'}, 'User')
  # Note: Private data (password) is not cloned

=back

=cut

=back

=head2 Object Destruction Hooks

These hooks are invoked when objects are being destroyed.

=over 4

=item deconstruct

  DECONSTRUCT() (any)

The DECONSTRUCT hook is a pre-destruction cleanup hook for releasing resources
before the object is destroyed. It is called just before C<DESTROY>. The return
value is not used in subsequent processing.

I<Since C<4.15>>

=over 4

=item deconstruct example 1

  package User;

  use base 'Venus::Core';

  our $CALLS = 0;
  our $USERS = 0;

  sub CONSTRUCT {
    return $CALLS = $USERS += 1;
  }

  sub DECONSTRUCT {
    return $USERS--;
  }

  package main;

  my $user = User->BLESS('Elliot');
  # $User::USERS is now 1

  undef $user;
  # $User::USERS is now 0

=back

=cut

=item destroy

  DESTROY() (any)

The DESTROY hook is the object destruction lifecycle hook. It is called when the
last reference to the object goes away.

I<Since C<1.00>>

=over 4

=item destroy example 1

  package User;

  use base 'Venus::Core';

  our $TRIES = 0;

  sub BUILD {
    return $TRIES++;
  }

  sub DESTROY {
    return $TRIES--;
  }

  package main;

  my $user = User->BLESS(name => 'Elliot');
  undef $user;
  # $User::TRIES is now 0

=back

=cut

=back

=head2 Class Building Hooks

These hooks are used during class definition to set up the class structure.

=over 4

=item attr

  ATTR(string $name, any @args) (string | object)

The ATTR hook installs attribute accessors in the calling package. It is called
during class building when you call C<attr> or C<ATTR>. It creates getter/setter
methods for the named attribute.

I<Since C<1.00>>

=over 4

=item attr example 1

  package User;

  use base 'Venus::Core';

  User->ATTR('name');
  User->ATTR('role');

  package main;

  my $user = User->BLESS(role => 'Engineer');

  $user->name;           # ""
  $user->name('Elliot'); # "Elliot"
  $user->role;           # "Engineer"
  $user->role('Hacker'); # "Hacker"

=back

=cut

=item base

  BASE(string $name) (string | object)

The BASE hook registers one or more base classes for the calling package. It is
called during class building. B<Note:> Unlike C<FROM>, this does NOT invoke the
C<AUDIT> hook.

I<Since C<1.00>>

=over 4

=item base example 1

  package Entity;

  sub work {
    return;
  }

  package User;

  use base 'Venus::Core';

  User->BASE('Entity');

  package main;

  my $user = User->BLESS;
  # $user->can('work') is true

=back

=cut

=item mask

  MASK(string $name, any @args) (string | object)

The MASK hook installs private instance data accessors that can only be accessed
within the class or its subclasses. It is called during class building. It
creates accessors that raise an exception if accessed outside the class
hierarchy.

I<Since C<4.15>>

=over 4

=item mask example 1

  package User;

  use base 'Venus::Core';

  User->MASK('password');

  sub get_password {
    my ($self) = @_;
    $self->password;  # OK: called from within class
  }

  sub set_password {
    my ($self, $value) = @_;
    $self->password($value);  # OK: called from within class
  }

  package main;

  my $user = User->BLESS(name => 'Elliot');
  $user->set_password('secret');  # Works

  # $user->password;  # Exception! Can't access private variable

=back

=cut

=back

=head2 Composition Hooks

These hooks handle role and mixin composition.

=over 4

=item role

  ROLE(string $name) (string | object)

The ROLE hook consumes a role into the calling package. It is called during
class building via the C<role> function.

B<Behavior:>

=over 4

=item * Methods are copied from the role to the consumer

=item * Methods are NOT copied if they already exist in the consumer

=item * First method wins in naming collisions

=item * Automatically invokes the role's C<IMPORT> hook

=item * Does NOT invoke the role's C<AUDIT> hook

=back

I<Since C<1.00>>

=over 4

=item role example 1

  package Admin;

  use base 'Venus::Core';

  package User;

  use base 'Venus::Core';

  User->ROLE('Admin');

  package main;

  User->DOES('Admin');  # 1

=back

=cut

=item mixin

  MIXIN(string $name) (string | object)

The MIXIN hook consumes a mixin into the calling package. It is called during
class building via the C<mixin> function.

B<Behavior:>

=over 4

=item * Methods are ALWAYS copied, even if they already exist (override)

=item * Last mixin wins in naming collisions

=item * Automatically invokes the mixin's C<IMPORT> hook

=item * More aggressive than roles

=back

I<Since C<1.02>>

=over 4

=item mixin example 1

  package Action;

  use base 'Venus::Core';

  package User;

  use base 'Venus::Core';

  User->MIXIN('Action');

  package main;

  User->DOES('Action');  # 0 (mixins don't register as roles)

=back

=cut

=item test

  TEST(string $name) (string | object)

The TEST hook consumes a role and invokes its C<AUDIT> hook for interface
validation. It is called during class building via the C<test> or C<with>
function.

B<Behavior:>

=over 4

=item * Same as C<ROLE> but also invokes C<AUDIT> hook

=item * Allows roles to act as interfaces

=back

I<Since C<1.00>>

=over 4

=item test example 1

  package Admin;

  use base 'Venus::Core';

  package IsAdmin;

  use base 'Venus::Core';

  sub shutdown {
    return;
  }

  sub AUDIT {
    my ($self, $from) = @_;
    die "${from} is not a super-user" if !$from->DOES('Admin');
  }

  sub EXPORT {
    ['shutdown']
  }

  package User;

  use base 'Venus::Core';

  User->ROLE('Admin');
  User->TEST('IsAdmin');  # Will validate User->DOES('Admin')

  package main;

  my $user = User->BLESS;  # OK

=back

=cut

=item from

  FROM(string $name) (string | object)

The FROM hook registers a base class and invokes its C<AUDIT> and C<IMPORT>
hooks. It is called during class building via the C<from> function.

B<Behavior:>

=over 4

=item * Registers inheritance

=item * Automatically invokes C<AUDIT> hook for validation

=item * Automatically invokes C<IMPORT> hook

=back

I<Since C<1.00>>

=over 4

=item from example 1

  package Entity;

  use base 'Venus::Core';

  sub AUDIT {
    my ($self, $from) = @_;
    die "Missing startup" if !$from->can('startup');
    die "Missing shutdown" if !$from->can('shutdown');
  }

  package User;

  use base 'Venus::Core';

  User->ATTR('startup');
  User->ATTR('shutdown');

  User->FROM('Entity');  # Will validate interface

  package main;

  my $user = User->BLESS;  # OK

=back

=cut

=back

=head2 Interface and Validation Hooks

=over 4

=item audit

  AUDIT(string $role) (string | object)

The AUDIT hook is an interface validation callback executed when a role is
consumed via C<TEST> or C<FROM>. It is called when the consumer invokes C<TEST>
or C<FROM> hooks. It receives the role itself and the consuming class name, and
should die/throw if the interface contract is not satisfied.

I<Since C<1.00>>

=over 4

=item audit example 1

  package HasType;

  use base 'Venus::Core';

  sub AUDIT {
    my ($self, $from) = @_;
    die 'Consumer missing "type" attribute' if !$from->can('type');
  }

  package User;

  use base 'Venus::Core';

  User->ATTR('type');
  User->TEST('HasType');  # OK: User has 'type'

  package Admin;

  use base 'Venus::Core';

  # Admin->TEST('HasType');  # Would die: Admin missing 'type'

=back

=cut

=back

=head2 Import/Export Hooks

These hooks control what gets exported when roles/mixins are composed.

=over 4

=item export

  EXPORT(any @args) (arrayref)

The EXPORT hook returns an arrayref of routine names to be automatically
imported by consumers. It is called when a class is used via C<use>, or whenever
C<import> is called, or during role/mixin composition via C<ROLE>, C<TEST>, or
C<MIXIN> hooks. Only methods listed in EXPORT are copied to the consumer.
B<Note:> By default, if no C<EXPORT> routine is declared, and if a package
variable exists named `@EXPORT`, the package variable is used as the list of
routines to be automatically exported.

I<Since C<1.00>>

=over 4

=item export example 1

  package Admin;

  use base 'Venus::Core';

  sub shutdown {
    return;
  }

  sub restart {
    return;
  }

  sub EXPORT {
    ['shutdown']  # Only shutdown will be exported
  }

  package User;

  use base 'Venus::Core';

  User->ROLE('Admin');

  package main;

  my $user = User->BLESS;
  # $user->can('shutdown') is true
  # $user->can('restart') is false

=back

=cut

=item import

  IMPORT(string $into, any @args) (string | object)

The IMPORT hook dispatches the C<EXPORT> hook when roles/mixins are consumed. It
is called when a class is used via C<use>, or whenever C<import> is called, or
during role/mixin composition via C<ROLE>, C<TEST>, or C<MIXIN> hooks. Override
this hook to track or customize the import process.

I<Since C<1.00>>

=over 4

=item import example 1

  package Admin;

  use base 'Venus::Core';

  our $USES = 0;

  sub shutdown {
    return;
  }

  sub EXPORT {
    ['shutdown']
  }

  sub IMPORT {
    my ($self, $into) = @_;

    $self->SUPER::IMPORT($into);

    $USES++;

    return $self;
  }

  package User;

  use base 'Venus::Core';

  User->ROLE('Admin');

  package main;

  # $Admin::USES is now 1

=back

=cut

=item use

  USE(string $into, any @args) (any)

The USE hook is invoked when the Perl C<use> declaration is used. It is called
during compilation when you C<use> a package.

I<Since C<2.91>>

=over 4

=item use example 1

  package User;

  use base 'Venus::Core';

  package main;

  User->USE;  # 'User'

=back

=cut

=item unimport

  UNIMPORT(string $into, any @args) (any)

The UNIMPORT hook is invoked when the Perl C<no> declaration is used. It is
called when you C<no> a package.

I<Since C<2.91>>

=over 4

=item unimport example 1

  package User;

  use base 'Venus::Core';

  package main;

  User->UNIMPORT;  # 'User'

=back

=cut

=back

=head2 Instance Data Hooks

These hooks control how instance data (attributes) are accessed and modified.

=over 4

=item get

  GET(string $name) (any)

The GET hook is responsible for getting instance attribute values. By default,
all attribute getters dispatch to this method. Override this hook to implement
custom getter logic for all attributes.

I<Since C<2.91>>

=over 4

=item get example 1

  package User;

  use base 'Venus::Core';

  User->ATTR('name');

  package main;

  my $user = User->BLESS(title => 'Engineer');

  my $value = $user->GET('title');  # "Engineer"

=back

=cut

=item set

  SET(string $name, any @args) (any)

The SET hook is responsible for setting instance attribute values. By default,
all attribute setters dispatch to this method. Override this hook to implement
custom setter logic for all attributes.

I<Since C<2.91>>

=over 4

=item set example 1

  package User;

  use base 'Venus::Core';

  User->ATTR('name');

  package main;

  my $user = User->BLESS(title => 'Engineer');

  $user->SET('title', 'Manager');  # "Manager"

=back

=cut

=item item

  ITEM(string $name, any @args) (string | object)

The ITEM hook is responsible for both getting and setting instance attributes. By
default, all attribute accessors dispatch to this method. Without extra args, it
acts as a getter; with args, it acts as a setter.

I<Since C<1.11>>

=over 4

=item item example 1

  package User;

  use base 'Venus::Core';

  User->ATTR('name');

  package main;

  my $user = User->BLESS;

  $user->ITEM('name', 'unknown');  # "unknown" (set)
  $user->ITEM('name');             # "unknown" (get)

=back

=cut

=back

=head2 Introspection Hooks

These hooks provide information about the package/object structure.

=over 4

=item meta

  META() (Venus::Meta)

The META hook returns a L<Venus::Meta> object describing the package
configuration. It is called when you call C<meta> or C<META> on a class or
instance.

I<Since C<1.00>>

=over 4

=item meta example 1

  package User;

  use base 'Venus::Core';

  package main;

  my $meta = User->META;
  # bless({name => 'User'}, 'Venus::Meta')

  # Query the meta object
  $meta->attrs;   # List attributes
  $meta->bases;   # List base classes
  $meta->roles;   # List consumed roles
  $meta->subs;    # List methods

=back

=cut

=item name

  NAME() (string)

The NAME hook returns the name of the package. It is called whenever the package
name is accessed via C<NAME>.

I<Since C<1.00>>

=over 4

=item name example 1

  package User;

  use base 'Venus::Core';

  package main;

  my $name = User->NAME;           # "User"
  my $user = User->BLESS;
  my $instance_name = $user->NAME; # "User"

=back

=cut

=item does

  DOES(string $name) (boolean)

The DOES hook returns true if the invocant consumed the specified role or mixin.
It is called on-demand, typically to check role composition.

I<Since C<1.00>>

=over 4

=item does example 1

  package Admin;

  use base 'Venus::Core';

  package User;

  use base 'Venus::Core';

  User->ROLE('Admin');

  package main;

  User->DOES('Admin');  # 1
  User->DOES('Owner');  # 0

=back

=cut

=item subs

  SUBS() (arrayref)

The SUBS hook returns the routines defined on the package and consumed from
roles (excluding inherited methods). It is called on-demand, typically for
introspection of available methods, whenever C<SUBS> is accessed.

I<Since C<1.00>>

=over 4

=item subs example 1

  package Example;

  use base 'Venus::Core';

  sub custom_method {
    return;
  }

  package main;

  my $subs = Example->SUBS;
  # [...list of method names...]

=back

=cut

=back

=head2 Hook Execution Order

Understanding the order in which hooks are executed is crucial for proper
initialization.

=head3 Class Building Phase

=over 4

=item 1. C<BASE> / C<FROM> - Register base classes

C<FROM> also triggers: C<AUDIT> (from parent), C<IMPORT> (from parent)

=item 2. C<ATTR> / C<MASK> - Define attributes

=item 3. C<ROLE> / C<TEST> / C<MIXIN> - Compose roles/mixins

C<ROLE> triggers: C<IMPORT> (from role)

C<TEST> triggers: C<AUDIT> (from role), C<IMPORT> (from role)

C<MIXIN> triggers: C<IMPORT> (from mixin)

=back

=head3 Object Construction Phase

=over 4

=item 1. C<BUILDARGS> - Pre-process constructor arguments

=item 2. C<ARGS> - Convert arguments to blessable data structure

=item 3. C<DATA> - Provide default data structure (if no args)

=item 4. C<bless> - Perl's built-in blessing

=item 5. C<BUILD> - Post-construction initialization

=item 6. C<CONSTRUCT> - Additional post-construction setup

=item 7. Return object to caller

=back

=head3 Object Destruction Phase

=over 4

=item 1. C<DECONSTRUCT> - Pre-destruction cleanup

=item 2. C<DESTROY> - Final destruction

=back

=head3 Role/Mixin Composition Phase

When a role/mixin is consumed:

=over 4

=item 1. Consumer calls C<ROLE> / C<TEST> / C<MIXIN>

=item 2. If TEST or FROM: C<AUDIT> is called on the role/parent

=item 3. C<IMPORT> is called on the role/mixin

=item 4. C<EXPORT> is called to determine what to copy

=item 5. Methods are copied according to composition rules

=back

=head2 Best Practices

=head3 1. Always Return $self in BUILD

  sub BUILD {
    my ($self) = @_;
    # ... initialization ...
    return $self;  # Always return $self
  }

=head3 2. Call SUPER in Inherited BUILD

  sub BUILD {
    my ($self, $data) = @_;
    $self->SUPER::BUILD($data);  # Call parent's BUILD
    # ... your initialization ...
    return $self;
  }

=head3 3. Explicitly Declare EXPORT

  sub EXPORT {
    # Be explicit about what you export
    ['method1', 'method2']
  }

=head3 4. Use AUDIT for Interface Enforcement

  sub AUDIT {
    my ($self, $from) = @_;
    die "Missing required method 'foo'" if !$from->can('foo');
    die "Missing required method 'bar'" if !$from->can('bar');
  }

=head3 5. Use MASK for Encapsulation

  # Instead of documenting "don't use this attribute"
  # Use MASK to enforce it programmatically
  User->MASK('internal_cache');

=head3 6. Keep BUILDARGS Simple

  sub BUILDARGS {
    my ($self, @args) = @_;
    # Simple transformations only
    # Complex logic goes in BUILD
    return @args == 1 && !ref $args[0] ? {id => $args[0]} : {@args};
  }

=cut

=head1 SUMMARY

Venus provides a comprehensive set of lifecycle hooks organized into several
categories:

=over 4

=item * B<Construction>: ARGS, BLESS, BUILDARGS, BUILD, CONSTRUCT, DATA, CLONE

=item * B<Destruction>: DECONSTRUCT, DESTROY

=item * B<Class Building>: ATTR, BASE, MASK

=item * B<Composition>: ROLE, MIXIN, TEST, FROM

=item * B<Validation>: AUDIT

=item * B<Import/Export>: EXPORT, IMPORT, USE, UNIMPORT

=item * B<Instance Data>: GET, SET, ITEM, STORE

=item * B<Introspection>: META, METACACHE, NAME, DOES, SUBS

=back

These hooks provide fine-grained control over every aspect of object-oriented
programming in Venus, from class construction to object lifecycle management.

=cut

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2022, Awncorp, C<awncorp@cpan.org>.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut
