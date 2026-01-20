package Venus::Role::Coercible;

use 5.018;

use strict;
use warnings;

# IMPORTS

use Venus::Role 'with';

# BUILDERS

sub BUILD {
  my ($self, $data) = @_;

  $data = $self->coercion($data);

  for my $name (keys %$data) {
    $self->{$name} = $data->{$name};
  }

  return $self;
};

# METHODS

sub coercers {
  my ($self) = @_;

  return $self->can('coerce') ? $self->coerce : {};
}

sub coerce_args {
  my ($self, $data, $spec) = @_;

  for my $name (grep exists($data->{$_}), sort keys %$spec) {
    $data->{$name} = $self->coerce_onto(
      $data, $name, $spec->{$name}, $data->{$name},
    );
  }

  return $data;
}

sub coerce_attr {
  my ($self, $name, @args) = @_;

  return $self->{$name} if !@args;

  return $self->{$name} = $self->coercion({$name, $args[0]})->{$name};
}

sub coerce_into {
  my ($self, $class, $value) = @_;

  require Scalar::Util;
  require Venus::Space;

  $class = (my $space = Venus::Space->new($class))->load;

  my $name = lc $space->label;

  require Venus::Name;
  require Venus::What;

  my $aliases = {
    array => 'arrayref',
    code => 'coderef',
    hash => 'hashref',
    regexp => 'regexpref',
    scalar => 'scalarref',
  };

  my $type = lc Venus::Name->new(scalar Venus::What->new(value => $value)->identify)->label;

  $type = $aliases->{$type} || $type;

  my $method;

  if ($method = $self->can("coerce_into_${name}_from_${type}")) {
    return $self->$method($class, $value);
  }
  elsif ($method = $self->can("coerce_into_${name}")) {
    return $self->$method($class, $value);
  }
  if (Scalar::Util::blessed($value) && $value->isa($class)) {
    return $value;
  }
  else {
    return $class->new($value);
  }
}

sub coerce_onto {
  my ($self, $data, $name, $class, $value) = @_;

  require Venus::Space;

  $class = Venus::Space->new($class)->load;

  $value = $data->{$name} if $#_ < 4;

  require Venus::Name;
  require Venus::What;

  my $aliases = {
    array => 'arrayref',
    code => 'coderef',
    hash => 'hashref',
    regexp => 'regexpref',
    scalar => 'scalarref',
  };

  my $type = lc Venus::Name->new(scalar Venus::What->new(value => $value)->identify)->label;

  $type = $aliases->{$type} || $type;

  my $method;

  if ($method = $self->can("coerce_onto_${name}_from_${type}")) {
    return $data->{$name} = $self->$method(\&coerce_into, $class, $value);
  }
  elsif ($method = $self->can("coerce_onto_${name}")) {
    return $data->{$name} = $self->$method(\&coerce_into, $class, $value);
  }
  elsif ($method = $self->can("coerce_${name}")) {
    return $data->{$name} = $self->$method(\&coerce_into, $class, $value);
  }
  else {
    return $data->{$name} = $self->coerce_into($class, $value);
  }
}

sub coercion {
  my ($self, $data) = @_;

  my $spec = $self->coercers;

  return $data if !%$spec;

  return $self->coerce_args($data, $spec);
}

# EXPORTS

sub EXPORT {
  [
    'coerce_args',
    'coerce_attr',
    'coerce_into',
    'coerce_onto',
    'coercers',
    'coercion',
  ]
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

  attr 'name';
  attr 'father';
  attr 'mother';
  attr 'siblings';

  sub coercers {
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

=head2 coerce_args

  coerce_args(hashref $data, hashref $spec) (hashref)

The coerce_args method replaces values in the data provided with objects
corresponding to the specification provided. The specification should contains
key/value pairs where the keys map to class attributes (or input parameters)
and the values are L<Venus::Space> compatible package names.

I<Since C<0.07>>

=over 4

=item coerce_args example 1

  package main;

  my $person = Person->new;

  my $data = $person->coerce_args(
    {
      father => { name => 'father' }
    },
    {
      father => 'Person',
    },
  );

  # {
  #   father   => bless({...}, 'Person'),
  # }

=back

=cut

=head2 coerce_attr

  coerce_attr(string $name, any $value) (any)

The coerce_attr method is a surrogate accessor and gets and/or sets an instance
attribute based on the coercion rules, returning the coerced value.

I<Since C<1.23>>

=over 4

=item coerce_attr example 1

  # given: synopsis

  package main;

  $person = Person->new(
    name => 'me',
  );

  my $coerce_name = $person->coerce_attr('name');

  # bless({value => "me"}, "Venus::String")

=back

=over 4

=item coerce_attr example 2

  # given: synopsis

  package main;

  $person = Person->new(
    name => 'me',
  );

  my $coerce_name = $person->coerce_attr('name', 'myself');

  # bless({value => "myself"}, "Venus::String")

=back

=cut

=head2 coerce_into

  coerce_into(string $class, any $value) (object)

The coerce_into method attempts to coerce the value provided into an object of
the specified class. If the value is already an object of that class, it is
returned as-is. Otherwise, the method tries to find a suitable coercion method
to convert the value based on its type. If no specific coercion method is
found, it defaults to constructing a new instance of the target class using the
provided value.

This method supports dynamic coercion by dispatching to a method on the
invocant (if present) named in the format C<coerce_into_${class}_from_${type}>
or C<coerce_into_${class}>, where C<$class> is the name of the desired object
class, and C<$type> is the data type of the value provided. If neither method
is found, it defaults to checking if the value is already of the target type or
creating a new instance of the target class.

The class name used in the method name will be formatted as a lowercase string
having underscores in place of any double-semi-colons.

For example: Example::Package will be C<example_package> making the method name
C<coerce_into_example_package>.

The following are the possible values for data types that can be used in the
method name:

=over 4

=item * arrayref

=item * boolean

=item * coderef

=item * float

=item * hashref

=item * number

=item * object

=item * regexp

=item * scalarref

=item * string

=item * undef

=back

For example: Coercing a string into the Example::Package would warrant the
method name C<coerce_into_example_package_from_string>.

I<Since C<0.07>>

=over 4

=item coerce_into example 1

  package main;

  my $person = Person->new;

  my $friend = $person->coerce_into('Person', {
    name => 'friend',
  });

  # bless({...}, 'Person')

=back

=over 4

=item coerce_into example 2

  package Player;

  use Venus::Class;

  with 'Venus::Role::Coercible';

  attr 'name';

  sub coerce_into_person {
    my ($self, $class, $value) = @_;

    return $class->new({name => $value || 'friend'});
  }

  package main;

  my $player = Player->new;

  my $person = $player->coerce_into('Person');

  # bless({...}, 'Person')

=back

=over 4

=item coerce_into example 3

  package Player;

  use Venus::Class;

  with 'Venus::Role::Coercible';

  attr 'name';

  sub coerce_into_person_from_string {
    my ($self, $class, $value) = @_;

    return $class->new({name => $value});
  }

  package main;

  my $player = Player->new;

  my $person = $player->coerce_into('Person', 'friend');

  # bless({...}, 'Person')

=back

=cut

=head2 coerce_onto

  coerce_onto(hashref $data, string $name, string $class, any $value) (object)

The coerce_onto method attempts to build and assign an object based on the
class name and value provided, as the value corresponding to the name
specified, in the data provided. If the C<$value> is omitted, the value
corresponding to the name in the C<$data> will be used.

The coerce_onto method attempts to coerce the value provided into an object of
the specified class, and add it as an item in the data structure provided. If
the value is already an object of that class, it is returned as-is. Otherwise,
the method tries to find a suitable coercion method to convert the value based
on its type. If no specific coercion method is found, it defaults to
constructing a new instance of the target class using the provided value.

This method supports dynamic coercion by dispatching to a method on the
invocant (if present) named in the format C<coerce_onto_${class}_from_${type}>
or C<coerce_onto_${class}> or C<coerce_${class}>, where C<$class> is the name
of the desired object class, and C<$type> is the data type of the value
provided. If neither method is found, it defaults to checking if the value is
already of the target type or creating a new instance of the target class.

The class name used in the method name will be formatted as a lowercase string
having underscores in place of any double-semi-colons.

For example: Example::Package will be C<example_package> making the method name
C<coerce_into_example_package>.

The following are the possible values for data types that can be used in the
method name:

=over 4

=item * arrayref

=item * boolean

=item * coderef

=item * float

=item * hashref

=item * number

=item * object

=item * regexp

=item * scalarref

=item * string

=item * undef

=back

For example: Coercing a string into the Example::Package would warrant the
method name C<coerce_onto_example_package_from_string>.

I<Since C<0.07>>

=over 4

=item coerce_onto example 1

  package main;

  my $person = Person->new;

  my $data = { friend => { name => 'friend' } };

  my $friend = $person->coerce_onto($data, 'friend', 'Person');

  # bless({...}, 'Person'),

  # $data was updated
  #
  # {
  #   friend => bless({...}, 'Person'),
  # }

=back

=over 4

=item coerce_onto example 2

  package Player;

  use Venus::Class;

  with 'Venus::Role::Coercible';

  attr 'name';
  attr 'teammates';

  sub coercers {
    {
      teammates => 'Person',
    }
  }

  sub coerce_into_person {
    my ($self, $class, $value) = @_;

    return $class->new($value);
  }

  sub coerce_into_venus_string {
    my ($self, $class, $value) = @_;

    return $class->new($value);
  }

  sub coerce_teammates {
    my ($self, $code, $class, $value) = @_;

    return [map $self->$code($class, $_), @$value];
  }

  package main;

  my $player = Player->new;

  my $data = { teammates => [{ name => 'player2' }, { name => 'player3' }] };

  my $teammates = $player->coerce_onto($data, 'teammates', 'Person');

  # [bless({...}, 'Person'), bless({...}, 'Person')]

  # $data was updated
  #
  # {
  #   teammates => [bless({...}, 'Person'), bless({...}, 'Person')],
  # }

=back

=over 4

=item coerce_onto example 3

  package Player;

  use Venus::Class;

  with 'Venus::Role::Coercible';

  attr 'name';
  attr 'teammates';

  sub coercers {
    {
      teammates => 'Person',
    }
  }

  sub coerce_into_person_from_string {
    my ($self, $class, $value) = @_;

    return $class->new({name => $value});
  }

  sub coerce_onto_teammates_from_arrayref {
    my ($self, $code, $class, $value) = @_;

    return [map $self->$code($class, $_), @$value];
  }

  package main;

  my $player = Player->new;

  my $data = { teammates => ['player2', 'player3'] };

  my $teammates = $player->coerce_onto($data, 'teammates', 'Person');

  # [bless({...}, 'Person'), bless({...}, 'Person')]

  # $data was updated
  #
  # {
  #   teammates => [bless({...}, 'Person'), bless({...}, 'Person')],
  # }

=back

=over 4

=item coerce_onto example 4

  package Player;

  use Venus::Class;

  with 'Venus::Role::Coercible';

  attr 'name';
  attr 'teammates';

  sub coercers {
    {
      teammates => 'Person',
    }
  }

  sub coerce_onto_teammates_from_hashref {
    my ($self, $code, $class, $value) = @_;

    return [$self->$code($class, $value)];
  }

  package main;

  my $player = Player->new;

  my $data = { teammates => {name => 'player2'} };

  my $teammates = $player->coerce_onto($data, 'teammates', 'Person');

  # [bless({...}, 'Person'), bless({...}, 'Person')]

  # $data was updated
  #
  # {
  #   teammates => [bless({...}, 'Person'), bless({...}, 'Person')],
  # }

=back

=cut

=head2 coercers

  coercers() (hashref)

The coercers method, if defined, is called during object construction, or by the
L</coercion> method, and returns key/value pairs where the keys map to class
attributes (or input parameters) and the values are L<Venus::Space> compatible
package names.

I<Since C<0.02>>

=over 4

=item coercers example 1

  package main;

  my $person = Person->new(
    name => 'me',
  );

  my $coercers = $person->coercers;

  # {
  #   father   => "Person",
  #   mother   => "Person",
  #   name     => "Venus/String",
  #   siblings => "Person",
  # }

=back

=cut

=head2 coercion

  coercion(hashref $data) (hashref)

The coercion method is called automatically during object construction but can
be called manually as well, and is passed a hashref to coerce and return.

I<Since C<0.02>>

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

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2022, Awncorp, C<awncorp@cpan.org>.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut