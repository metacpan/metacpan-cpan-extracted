package Venus::Meta;

use 5.018;

use strict;
use warnings;

use Venus;

use base 'Venus::Core';

# METHODS

sub attr {
  my ($self, $name) = @_;

  return 0 if !$name;

  my $data = {map +($_,$_), @{$self->attrs}};

  return $data->{$name} ? true : false;
}

sub attrs {
  my ($self) = @_;

  if ($self->{attrs}) {
    return wantarray ? (@{$self->{attrs}}) : $self->{attrs};
  }

  my $name = $self->{name};
  my @attrs = attrs_resolver($name);

  for my $base (@{$self->bases}) {
    push @attrs, attrs_resolver($base);
  }

  for my $role (@{$self->roles}) {
    push @attrs, attrs_resolver($role);
  }

  my %seen;
  my $results = $self->{attrs} ||= [grep !$seen{$_}++, @attrs];

  return wantarray ? (@$results) : $results;
}

sub attrs_resolver {
  my ($name) = @_;

  no strict 'refs';
  no warnings 'once';

  if (${"${name}::META"} && $${"${name}::META"}{ATTR}) {
    return (sort {
      $${"${name}::META"}{ATTR}{$a}[0] <=> $${"${name}::META"}{ATTR}{$b}[0]
    } keys %{$${"${name}::META"}{ATTR}});
  }
  else {
    return ();
  }
}

sub base {
  my ($self, $name) = @_;

  return 0 if !$name;

  my $data = {map +($_,$_), @{$self->bases}};

  return $data->{$name} ? true : false;
}

sub bases {
  my ($self) = @_;

  if ($self->{bases}) {
    return wantarray ? (@{$self->{bases}}) : $self->{bases};
  }

  my $name = $self->{name};
  my @bases = bases_resolver($name);

  for my $base (@bases) {
    push @bases, bases_resolver($base);
  }

  my %seen;
  my $results = $self->{bases} ||= [grep !$seen{$_}++, @bases];

  return wantarray ? (@$results) : $results;
}

sub bases_resolver {
  my ($name) = @_;

  no strict 'refs';

  return (@{"${name}::ISA"});
}

sub data {
  my ($self) = @_;

  my $name = $self->{name};

  no strict 'refs';

  return ${"${name}::META"};
}

sub emit {
  my ($self, $hook, @args) = @_;

  my $name = $self->{name};

  $hook = uc $hook;

  return $name->$hook(@args);
}

sub find {
  my ($self, $type, $name) = @_;

  return if !$type;
  return if !$name;

  my $configs;

  for my $source (qw(roles bases mixins self)) {
    $configs = $self->search($source, $type, $name);
    last if @$configs;
  }

  return $configs ? $configs->[0] : undef;
}

sub local {
  my ($self, $type) = @_;

  return if !$type;

  my $name = $self->{name};

  no strict 'refs';

  return if !int grep $type eq $_, qw(attrs bases mixins roles subs);

  my $function = "${type}_resolver";

  my $results = [&{"${function}"}($name)];

  return wantarray ? (@$results) : $results;
}

sub mixin {
  my ($self, $name) = @_;

  return 0 if !$name;

  my $data = {map +($_,$_), @{$self->mixins}};

  return $data->{$name} ? true : false;
}

sub mixins {
  my ($self) = @_;

  if ($self->{mixins}) {
    return wantarray ? (@{$self->{mixins}}) : $self->{mixins};
  }

  my $name = $self->{name};
  my @mixins = mixins_resolver($name);

  for my $mixin (@mixins) {
    push @mixins, mixins_resolver($mixin);
  }

  for my $base (@{$self->bases}) {
    push @mixins, mixins_resolver($base);
  }

  my %seen;
  my $results = $self->{mixins} ||= [grep !$seen{$_}++, @mixins];

  return wantarray ? (@$results) : $results;
}

sub mixins_resolver {
  my ($name) = @_;

  no strict 'refs';

  if (${"${name}::META"} && $${"${name}::META"}{MIXIN}) {
    return (map +($_, mixins_resolver($_)), sort {
      $${"${name}::META"}{MIXIN}{$a}[0] <=> $${"${name}::META"}{MIXIN}{$b}[0]
    } keys %{$${"${name}::META"}{MIXIN}});
  }
  else {
    return ();
  }
}

sub new {
  my ($self, @args) = @_;

  return $self->BLESS(@args);
}

sub role {
  my ($self, $name) = @_;

  return 0 if !$name;

  my $data = {map +($_,$_), @{$self->roles}};

  return $data->{$name} ? true : false;
}

sub roles {
  my ($self) = @_;

  if ($self->{roles}) {
    return wantarray ? (@{$self->{roles}}) : $self->{roles};
  }

  my $name = $self->{name};
  my @roles = roles_resolver($name);

  for my $role (@roles) {
    push @roles, roles_resolver($role);
  }

  for my $base (@{$self->bases}) {
    push @roles, roles_resolver($base);
  }

  my %seen;
  my $results = $self->{roles} ||= [grep !$seen{$_}++, @roles];

  return wantarray ? (@$results) : $results;
}

sub roles_resolver {
  my ($name) = @_;

  no strict 'refs';
  no warnings 'once';

  if (${"${name}::META"} && $${"${name}::META"}{ROLE}) {
    return (map +($_, roles_resolver($_)), sort {
      $${"${name}::META"}{ROLE}{$a}[0] <=> $${"${name}::META"}{ROLE}{$b}[0]
    } keys %{$${"${name}::META"}{ROLE}});
  }
  else {
    return ();
  }
}

sub search {
  my ($self, $from, $type, $name) = @_;

  return if !$from;
  return if !$type;
  return if !$name;

  no strict 'refs';

  my @configs;
  my @sources;

  if (lc($from) eq 'bases') {
    @sources = bases_resolver($self->{name});
  }
  elsif (lc($from) eq 'roles') {
    @sources = roles_resolver($self->{name});
  }
  elsif (lc($from) eq 'mixins') {
    @sources = mixins_resolver($self->{name});
  }
  else {
    @sources = ($self->{name});
  }

  for my $source (@sources) {
    if (lc($type) eq 'sub') {
      if (*{"${source}::${name}"}{"CODE"}) {
        push @configs, [$source, [1, [*{"${source}::${name}"}{"CODE"}]]];
      }
    }
    else {
      if ($${"${source}::META"}{uc($type)}{$name}) {
        push @configs, [$source, $${"${source}::META"}{uc($type)}{$name}];
      }
    }
  }

  my $results = [@configs];

  return wantarray ? (@$results) : $results;
}

sub sub {
  my ($self, $name) = @_;

  return 0 if !$name;

  my $data = {map +($_,$_), @{$self->subs}};

  return $data->{$name} ? true : false;
}

sub subs {
  my ($self) = @_;

  if ($self->{subs}) {
    return wantarray ? (@{$self->{subs}}) : $self->{subs};
  }

  my $name = $self->{name};
  my @subs = subs_resolver($name);

  for my $base (@{$self->bases}) {
    push @subs, subs_resolver($base);
  }

  my %seen;
  my $results = $self->{subs} ||= [grep !$seen{$_}++, @subs];

  return wantarray ? (@$results) : $results;
}

sub subs_resolver {
  my ($name) = @_;

  no strict 'refs';

  return (
    grep *{"${name}::$_"}{"CODE"},
    grep /^[_a-zA-Z]\w*$/, keys %{"${name}::"}
  );
}

1;



=head1 NAME

Venus::Meta - Class Metadata

=cut

=head1 ABSTRACT

Class Metadata for Perl 5

=cut

=head1 SYNOPSIS

  package Person;

  use Venus::Class;

  attr 'fname';
  attr 'lname';

  package Identity;

  use Venus::Role;

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

  sub EXPORT {
    # explicitly declare routines to be consumed
    ['authenticate']
  }

  package Novice;

  use Venus::Mixin;

  sub points {
    100
  }

  package User;

  use Venus::Class 'attr', 'base', 'mixin', 'test', 'with';

  base 'Person';

  with 'Identity';

  mixin 'Novice';

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

  my $meta = $user->meta;

  # bless({name => 'User'}, 'Venus::Meta')

=cut

=head1 DESCRIPTION

This package provides configuration information for L<Venus> derived classes,
roles, and interfaces.

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 attr

  attr(string $name) (boolean)

The attr method returns true or false if the package referenced has the
attribute accessor named.

I<Since C<1.00>>

=over 4

=item attr example 1

  # given: synopsis

  package main;

  my $attr = $meta->attr('email');

  # 1

=back

=over 4

=item attr example 2

  # given: synopsis

  package main;

  my $attr = $meta->attr('username');

  # 0

=back

=cut

=head2 attrs

  attrs() (arrayref)

The attrs method returns all of the attributes composed into the package
referenced.

I<Since C<1.00>>

=over 4

=item attrs example 1

  # given: synopsis

  package main;

  my $attrs = $meta->attrs;

  # [
  #   'email',
  #   'fname',
  #   'id',
  #   'lname',
  #   'login',
  #   'password',
  # ]

=back

=cut

=head2 base

  base(string $name) (boolean)

The base method returns true or false if the package referenced has inherited
the package named.

I<Since C<1.00>>

=over 4

=item base example 1

  # given: synopsis

  package main;

  my $base = $meta->base('Person');

  # 1

=back

=over 4

=item base example 2

  # given: synopsis

  package main;

  my $base = $meta->base('Student');

  # 0

=back

=cut

=head2 bases

  bases() (arrayref)

The bases method returns returns all of the packages inherited by the package
referenced.

I<Since C<1.00>>

=over 4

=item bases example 1

  # given: synopsis

  package main;

  my $bases = $meta->bases;

  # [
  #   'Person',
  #   'Venus::Core::Class',
  #   'Venus::Core',
  # ]

=back

=cut

=head2 data

  data() (hashref)

The data method returns a data structure representing the shallow configuration
for the package referenced.

I<Since C<1.00>>

=over 4

=item data example 1

  # given: synopsis

  package main;

  my $data = $meta->data;

  # {
  #   'ATTR' => {
  #     'email' => [
  #       'email'
  #     ]
  #   },
  #   'BASE' => {
  #     'Person' => [
  #       'Person'
  #     ]
  #   },
  #   'ROLE' => {
  #     'Authenticable' => [
  #       'Authenticable'
  #     ],
  #     'Identity' => [
  #       'Identity'
  #     ]
  #   }
  # }

=back

=cut

=head2 emit

  emit(string $name, any @args) (any)

The emit method invokes the lifecycle hook specified on the underlying package
and returns the result.

I<Since C<2.91>>

=over 4

=item emit example 1

  # given: synopsis

  package main;

  my $result = $meta->emit('attr', 'mname');

  # "User"

=back

=cut

=head2 find

  find(string $type, string $name) (tuple[string,tuple[number,arrayref]])

The find method finds and returns the first configuration for the property type
specified. This method uses the L</search> method to search C<roles>, C<bases>,
C<mixins>, and the source package, in the order listed. The "property type" can
be any one of C<attr>, C<base>, C<mixin>, or C<role>.

I<Since C<1.02>>

=over 4

=item find example 1

  # given: synopsis

  package main;

  my $find = $meta->find;

  # ()

=back

=over 4

=item find example 2

  # given: synopsis

  package main;

  my $find = $meta->find('attr', 'id');

  # ['Identity', [ 1, ['id']]]

=back

=over 4

=item find example 3

  # given: synopsis

  package main;

  my $find = $meta->find('sub', 'valid');

  # ['User', [1, [sub {...}]]]

=back

=over 4

=item find example 4

  # given: synopsis

  package main;

  my $find = $meta->find('sub', 'authenticate');

  # ['Authenticable', [1, [sub {...}]]]

=back

=cut

=head2 local

  local(string $type) (arrayref)

The local method returns the names of properties defined in the package
directly (not inherited) for the property type specified. The C<$type> provided
can be either C<attrs>, C<bases>, C<roles>, or C<subs>.

I<Since C<1.02>>

=over 4

=item local example 1

  # given: synopsis

  package main;

  my $attrs = $meta->local('attrs');

  # ['email']

=back

=over 4

=item local example 2

  # given: synopsis

  package main;

  my $bases = $meta->local('bases');

  # ['Person', 'Venus::Core::Class']

=back

=over 4

=item local example 3

  # given: synopsis

  package main;

  my $roles = $meta->local('roles');

  # ['Identity', 'Authenticable']

=back

=over 4

=item local example 4

  # given: synopsis

  package main;

  my $subs = $meta->local('subs');

  # [
  #   'attr',
  #   'authenticate',
  #   'base',
  #   'email',
  #   'false',
  #   'id',
  #   'login',
  #   'password',
  #   'test',
  #   'true',
  #   'valid',
  #   'with',
  # ]

=back

=cut

=head2 mixin

  mixin(string $name) (boolean)

The mixin method returns true or false if the package referenced has consumed
the mixin named.

I<Since C<1.02>>

=over 4

=item mixin example 1

  # given: synopsis

  package main;

  my $mixin = $meta->mixin('Novice');

  # 1

=back

=over 4

=item mixin example 2

  # given: synopsis

  package main;

  my $mixin = $meta->mixin('Intermediate');

  # 0

=back

=cut

=head2 mixins

  mixins() (arrayref)

The mixins method returns all of the mixins composed into the package
referenced.

I<Since C<1.02>>

=over 4

=item mixins example 1

  # given: synopsis

  package main;

  my $mixins = $meta->mixins;

  # [
  #   'Novice',
  # ]

=back

=cut

=head2 new

  new(any %args | hashref $args) (object)

The new method returns a new instance of this package.

I<Since C<1.00>>

=over 4

=item new example 1

  # given: synopsis

  package main;

  $meta = Venus::Meta->new(name => 'User');

  # bless({name => 'User'}, 'Venus::Meta')

=back

=over 4

=item new example 2

  # given: synopsis

  package main;

  $meta = Venus::Meta->new({name => 'User'});

  # bless({name => 'User'}, 'Venus::Meta')

=back

=cut

=head2 role

  role(string $name) (boolean)

The role method returns true or false if the package referenced has consumed
the role named.

I<Since C<1.00>>

=over 4

=item role example 1

  # given: synopsis

  package main;

  my $role = $meta->role('Identity');

  # 1

=back

=over 4

=item role example 2

  # given: synopsis

  package main;

  my $role = $meta->role('Builder');

  # 0

=back

=cut

=head2 roles

  roles() (arrayref)

The roles method returns all of the roles composed into the package referenced.

I<Since C<1.00>>

=over 4

=item roles example 1

  # given: synopsis

  package main;

  my $roles = $meta->roles;

  # [
  #   'Identity',
  #   'Authenticable'
  # ]

=back

=cut

=head2 search

  search(string $from, string $type, string $name) (within[arrayref, tuple[string,tuple[number,arrayref]]])

The search method searches the source specified and returns the configurations
for the property type specified. The source can be any one of C<bases>,
C<roles>, C<mixins>, or C<self> for the source package. The "property type" can
be any one of C<attr>, C<base>, C<mixin>, or C<role>.

I<Since C<1.02>>

=over 4

=item search example 1

  # given: synopsis

  package main;

  my $search = $meta->search;

  # ()

=back

=over 4

=item search example 2

  # given: synopsis

  package main;

  my $search = $meta->search('roles', 'attr', 'id');

  # [['Identity', [ 1, ['id']]]]

=back

=over 4

=item search example 3

  # given: synopsis

  package main;

  my $search = $meta->search('self', 'sub', 'valid');

  # [['User', [1, [sub {...}]]]]

=back

=over 4

=item search example 4

  # given: synopsis

  package main;

  my $search = $meta->search('self', 'sub', 'authenticate');

  # [['User', [1, [sub {...}]]]]

=back

=cut

=head2 sub

  sub(string $name) (boolean)

The sub method returns true or false if the package referenced has the
subroutine named on the package directly, or any of its superclasses.

I<Since C<1.00>>

=over 4

=item sub example 1

  # given: synopsis

  package main;

  my $sub = $meta->sub('authenticate');

  # 1

=back

=over 4

=item sub example 2

  # given: synopsis

  package main;

  my $sub = $meta->sub('authorize');

  # 0

=back

=cut

=head2 subs

  subs() (arrayref)

The subs method returns all of the subroutines composed into the package
referenced.

I<Since C<1.00>>

=over 4

=item subs example 1

  # given: synopsis

  package main;

  my $subs = $meta->subs;

  # [
  #   'attr', ...,
  #   'base',
  #   'email',
  #   'false',
  #   'fname', ...,
  #   'id',
  #   'lname',
  #   'login',
  #   'new', ...,
  #   'role',
  #   'test',
  #   'true',
  #   'with', ...,
  # ]

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