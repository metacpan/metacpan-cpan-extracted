package Venus::Meta;

use 5.018;

use strict;
use warnings;

use base 'Venus::Core';

# METHODS

sub attr {
  my ($self, $name) = @_;

  return 0 if !$name;

  my $data = {map +($_,$_), @{$self->attrs}};

  return $data->{$name} ? 1 : 0;
}

sub attrs {
  my ($self) = @_;

  my $name = $self->{name};
  my @attrs = attrs_resolver($name);

  for my $base (@{$self->bases}) {
    push @attrs, attrs_resolver($base);
  }

  for my $role (@{$self->roles}) {
    push @attrs, attrs_resolver($role);
  }

  my %seen;
  return $self->{attrs} ||= [grep !$seen{$_}++, @attrs];
}

sub attrs_resolver {
  my ($name) = @_;

  no strict 'refs';
  no warnings 'once';

  if (${"${name}::META"} && $${"${name}::META"}{ATTR}) {
    return (map +($_,attrs_resolver($_)), sort {
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

  return $data->{$name} ? 1 : 0;
}

sub bases {
  my ($self) = @_;

  my $name = $self->{name};
  my @bases = bases_resolver($name);

  for my $base (@bases) {
    push @bases, bases_resolver($base);
  }

  my %seen;
  return $self->{bases} ||= [grep !$seen{$_}++, @bases];
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

sub new {
  my ($self, @args) = @_;

  return $self->BLESS(@args);
}

sub role {
  my ($self, $name) = @_;

  return 0 if !$name;

  my $data = {map +($_,$_), @{$self->roles}};

  return $data->{$name} ? 1 : 0;
}

sub roles {
  my ($self) = @_;

  my $name = $self->{name};
  my @roles = roles_resolver($name);

  for my $role (@roles) {
    push @roles, roles_resolver($role);
  }

  for my $base (@{$self->bases}) {
    push @roles, roles_resolver($base);
  }

  my %seen;
  return $self->{roles} ||= [grep !$seen{$_}++, @roles];
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

sub sub {
  my ($self, $name) = @_;

  return 0 if !$name;

  my $data = {map +($_,$_), @{$self->subs}};

  return $data->{$name} ? 1 : 0;
}

sub subs {
  my ($self) = @_;

  my $name = $self->{name};
  my @subs = subs_resolver($name);

  for my $base (@{$self->bases}) {
    push @subs, subs_resolver($base);
  }

  my %seen;
  return $self->{subs} ||= [grep !$seen{$_}++, @subs];
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

  attr(Str $name) (Bool)

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

  attrs() (ArrayRef)

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

  base(Str $name) (Bool)

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

  bases() (ArrayRef)

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

  data() (HashRef)

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

=head2 new

  new(Any %args | HashRef $args) (Object)

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

  role(Str $name) (Bool)

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

  roles() (ArrayRef)

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

=head2 sub

  sub(Str $name) (Bool)

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

  subs() (ArrayRef)

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