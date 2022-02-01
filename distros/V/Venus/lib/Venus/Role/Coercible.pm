package Venus::Role::Coercible;

use 5.018;

use strict;
use warnings;

use Moo::Role;

with 'Venus::Role::Buildable';

# MODIFIERS

around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;

  return $class->coercion($class->$orig(@args));
};

# METHODS

sub coerce {
  my ($self) = @_;

  return ();
}

sub coercion {
  my ($self, $data) = @_;

  my @args = $self->coerce;

  return $data if !@args;

  my $rules = (@args > 1) ? {@args} : (ref($args[0]) eq 'HASH') ? $args[0] : {};

  return $data if !%$rules;

  require Scalar::Util;
  require Venus::Space;

  my $routine = sub {
    my ($self, $class, $value) = @_;

    if (Scalar::Util::blessed($value) && $value->isa($class)) {
      return $value;
    }
    else {
      return $class->new($value);
    }
  };

  my $space = "Venus::Space";

  for my $name (grep exists($data->{$_}), sort keys %$rules) {
    if (my $method = $self->can("coerce_${name}")) {
      $data->{$name} = $self->$method(
        $routine, $space->new($rules->{$name})->load, $data->{$name}
      );
    }
    else {
      $data->{$name} = $self->$routine(
        $space->new($rules->{$name})->load, $data->{$name}
      );
    }
  }

  return $data;
}

1;



=head1 NAME

Venus::Role::Coercible - Coercible Role

=cut

=head1 ABSTRACT

Coercible Role for Perl 5

=cut

=head1 SYNOPSIS

  package Person;

  use Venus::Class;

  with 'Venus::Role::Coercible';

  has 'name';

  has 'father';
  has 'mother';
  has 'siblings';

  sub coerce {
    {
      father => 'Person',
      mother => 'Person',
      name => 'Venus/String',
      siblings => 'Person',
    }
  }

  sub coerce_name {
    my ($self, $code, @args) = @_;

    return $self->$code(@args);
  }

  sub coerce_siblings {
    my ($self, $code, $class, $value) = @_;

    return [map $self->$code($class, $_), @$value];
  }

  package main;

  my $person = Person->new(
    name => 'me',
    father => {name => 'father'},
    mother => {name => 'mother'},
    siblings => [{name => 'brother'}, {name => 'sister'}],
  );

  # $person
  # bless({...}, 'Person')

  # $person->name
  # bless({...}, 'Venus::String')

  # $person->father
  # bless({...}, 'Person')

  # $person->mother
  # bless({...}, 'Person')

  # $person->siblings
  # [bless({...}, 'Person'), bless({...}, 'Person'), ...]

=cut

=head1 DESCRIPTION

This package modifies the consuming package and provides methods for hooking
into object construction and coercing arguments into objects and values.

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 coerce

  coerce() (HashRef)

The coerce method, if defined, is called during object construction, or by the
L</coercion> method, and returns key/value pairs where the keys map to class
attributes (or input parameters) and the values are L<Venus::Space> compatible
package names.

I<Since C<0.01>>

=over 4

=item coerce example 1

  package main;

  my $person = Person->new(
    name => 'me',
  );

  my $coerce = $person->coerce;

  # {
  #   father   => "Person",
  #   mother   => "Person",
  #   name     => "Venus/String",
  #   siblings => "Person",
  # }

=back

=cut

=head2 coercion

  coercion(HashRef $data) (HashRef)

The coercion method is called automatically during object construction but can
be called manually as well, and is passed a hashref to coerce and return.

I<Since C<0.01>>

=over 4

=item coercion example 1

  package main;

  my $person = Person->new;

  my $coercion = $person->coercion({
    name => 'me',
  });

  # $coercion
  # {...}

  # $coercion->{name}
  # bless({...}, 'Venus::String')

  # $coercion->{father}
  # undef

  # $coercion->{mother}
  # undef

  # $coercion->{siblings}
  # undef

=back

=over 4

=item coercion example 2

  package main;

  my $person = Person->new;

  my $coercion = $person->coercion({
    name => 'me',
    mother => {name => 'mother'},
    siblings => [{name => 'brother'}, {name => 'sister'}],
  });

  # $coercion
  # {...}

  # $coercion->{name}
  # bless({...}, 'Venus::String')

  # $coercion->{father}
  # undef

  # $coercion->{mother}
  # bless({...}, 'Person')

  # $coercion->{siblings}
  # [bless({...}, 'Person'), bless({...}, 'Person'), ...]

=back

=cut

=head1 AUTHORS

Cpanery, C<cpanery@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2021, Cpanery

Read the L<"license"|https://github.com/cpanery/venus/blob/master/LICENSE> file.

=cut