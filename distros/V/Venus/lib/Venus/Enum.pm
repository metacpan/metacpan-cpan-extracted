package Venus::Enum;

use 5.018;

use strict;
use warnings;

# IMPORTS

use Venus::Class 'base';

# INHERITS

base 'Venus::Sealed';

# OVERLOADS

use overload (
  '""' => sub{$_[0]->value // ''},
  '~~' => sub{$_[0]->value // ''},
  'eq' => sub{($_[0]->value // '') eq "$_[1]"},
  'ne' => sub{($_[0]->value // '') ne "$_[1]"},
  'qr' => sub{qr/@{[quotemeta($_[0])]}/},
  fallback => 1,
);

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
    $data = {value => $data};
  }

  my $value = $data->{value};

  if (!ref $value) {
    $value = {}
  }

  if (ref $value eq 'ARRAY') {
    $value = {map +(s/\W//gr, $_), @{$value}};
  }
  else {
    $value = {map +(s/\W//gr, $value->{$_}), keys %{$value}};
  }

  $data->{value} = {
    names => $value,
    codes => {reverse %{$value}},
  };

  return $self->SUPER::build_args($data);
}

# METHODS

sub __get {
  my ($self, $init, $data, $name) = @_;

  return undef if !$name;

  my $class = ref $self || $self;

  my $enum = $class->new(value => $init->{value}->{names});

  $enum->{set} = 1;

  $enum->set($name);

  delete $enum->{set};

  return $enum;
}

sub __set {
  my ($self, $init, $data, $name) = @_;

  return undef if !$name;

  return $self if !exists $self->{set};

  my $names = $init->{value}->{names};

  return $self if !exists $names->{$name};

  $data->{named} //= $name;

  return $self;
}

sub __has {
  my ($self, $init, $data, $match) = @_;

  return false if !$match;

  my $names = $init->{value}->{names};

  return true if $names->{$match};

  my $codes = $init->{value}->{codes};

  return true if $codes->{$match};

  return false;
}

sub __is {
  my ($self, $init, $data, $match) = @_;

  return false if !$match;

  my $name = $self->name;

  return true if $name eq $match;

  my $value = $self->value;

  return true if $value eq $match;

  return false;
}

sub __name {
  my ($self, $init, $data) = @_;

  return $data->{named};
}

sub __names {
  my ($self, $init, $data) = @_;

  my $names = $init->{value}->{names};

  my $list = [sort keys %{$names}];

  return wantarray ? (@{$list}) : $list;
}

sub __items {
  my ($self, $init, $data) = @_;

  my $names = $init->{value}->{names};

  my $list = [map [$_, $names->{$_}], $self->list];

  return wantarray ? (@{$list}) : $list;
}

sub __list {
  my ($self, $init, $data) = @_;

  my $codes = $init->{value}->{codes};

  my $list = [map $codes->{$_}, sort keys %{$codes}];

  return wantarray ? (@{$list}) : $list;
}

sub __value {
  my ($self, $init, $data) = @_;

  my $value = $data->{named};

  return undef if !defined $value;

  return $init->{value}->{names}->{$value};
}

sub __values {
  my ($self, $init, $data) = @_;

  my $codes = $init->{value}->{codes};

  my $list = [sort keys %{$codes}];

  return wantarray ? (@{$list}) : $list;
}

1;



=head1 NAME

Venus::Enum - Enum Class

=cut

=head1 ABSTRACT

Enum Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Enum;

  my $enum = Venus::Enum->new(['n', 's', 'e', 'w']);

  # my $north = $enum->get('n');

  # "n"

=cut

=head1 DESCRIPTION

This package provides an interface for working with enumerations.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Sealed>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 get

  get(string $name) (Venus::Enum)

The get method returns a new object representing the enum member specified.

I<Since C<3.55>>

=over 4

=item get example 1

  # given: synopsis

  package main;

  my $get = $enum->get('n');

  # bless(..., "Venus::Enum")

  # $get->value

  # "n"

=back

=over 4

=item get example 2

  # given: synopsis

  package main;

  my $get = $enum->get('s');

  # bless(..., "Venus::Enum")

  # $get->value

  # "s"

=back

=cut

=head2 has

  has(string $name) (boolean)

The has method returns true if the member name or value exists in the enum,
otherwise returns false.

I<Since C<3.55>>

=over 4

=item has example 1

  # given: synopsis

  package main;

  my $has = $enum->has('n');

  # true

=back

=over 4

=item has example 2

  # given: synopsis

  package main;

  my $has = $enum->has('z');

  # false

=back

=cut

=head2 is

  is(string $name) (boolean)

The is method returns true if the member name or value specified matches the
member selected in the enum, otherwise returns false.

I<Since C<3.55>>

=over 4

=item is example 1

  # given: synopsis

  package main;

  my $is = $enum->get('n')->is('n');

  # true

=back

=over 4

=item is example 2

  # given: synopsis

  package main;

  my $is = $enum->get('s')->is('n');

  # false

=back

=cut

=head2 items

  items() (tuple[string, string])

The items method returns an arrayref of arrayrefs containing the name and value
pairs for the enumerations. Returns a list in list context.

I<Since C<3.55>>

=over 4

=item items example 1

  # given: synopsis

  package main;

  my $items = $enum->items;

  # [["e", "e"], ["n", "n"], ["s", "s"], ["w", "w"]]

=back

=over 4

=item items example 2

  # given: synopsis

  package main;

  my @items = $enum->items;

  # (["e", "e"], ["n", "n"], ["s", "s"], ["w", "w"])

=back

=cut

=head2 list

  list() (within[arrayref, string])

The list method returns an arrayref containing the values for the enumerations.
Returns a list in list context.

I<Since C<3.55>>

=over 4

=item list example 1

  # given: synopsis

  package main;

  my $list = $enum->list;

  # ["e", "n", "s", "w"]

=back

=over 4

=item list example 2

  # given: synopsis

  package main;

  my @list = $enum->list;

  # ("e", "n", "s", "w")

=back

=cut

=head2 name

  name() (maybe[string])

The name method returns the name of the member selected or returns undefined.

I<Since C<3.55>>

=over 4

=item name example 1

  # given: synopsis

  package main;

  my $name = $enum->name;

  # undef

=back

=over 4

=item name example 2

  # given: synopsis

  package main;

  my $n = $enum->get('n');

  my $name = $n->name;

  # "n"

=back

=cut

=head2 names

  names() (within[arrayref, string])

The names method returns an arrayref containing the names for the enumerations.
Returns a list in list context.

I<Since C<3.55>>

=over 4

=item names example 1

  # given: synopsis

  package main;

  my $names = $enum->names;

  # ["e", "n", "s", "w"]

=back

=over 4

=item names example 2

  # given: synopsis

  package main;

  my @names = $enum->names;

  # ("e", "n", "s", "w")

=back

=cut

=head2 new

  new(any @args) (Venus::Enum)

The new method constructs an instance of the package.

I<Since C<4.15>>

=over 4

=item new example 1

  package main;

  use Venus::Enum;

  my $new = Venus::Enum->new;

  # bless(..., "Venus::Enum")

=back

=over 4

=item new example 2

  package main;

  use Venus::Enum;

  my $new = Venus::Enum->new(['n', 's', 'e', 'w']);

  # bless(..., "Venus::Enum")

=back

=over 4

=item new example 3

  package main;

  use Venus::Enum;

  my $new = Venus::Enum->new(value => ['n', 's', 'e', 'w']);

  # bless(..., "Venus::Enum")

=back

=cut

=head2 value

  value() (maybe[string])

The value method returns the value of the member selected or returns undefined.

I<Since C<3.55>>

=over 4

=item value example 1

  # given: synopsis

  package main;

  my $value = $enum->value;

  # undef

=back

=over 4

=item value example 2

  # given: synopsis

  package main;

  my $n = $enum->get('n');

  my $value = $n->value;

  # "n"

=back

=cut

=head2 values

  values() (within[arrayref, string])

The values method returns an arrayref containing the values for the
enumerations. Returns a list in list context.

I<Since C<3.55>>

=over 4

=item values example 1

  # given: synopsis

  package main;

  my $values = $enum->values;

  # ["e", "n", "s", "w"]

=back

=over 4

=item values example 2

  # given: synopsis

  package main;

  my @values = $enum->values;

  # ("e", "n", "s", "w")

=back

=cut

=head1 OPERATORS

This package overloads the following operators:

=cut

=over 4

=item operation: C<("")>

This package overloads the C<""> operator.

B<example 1>

  # given: synopsis;

  my $result = "$enum";

  # ""

B<example 2>

  # given: synopsis;

  my $n = $enum->get("n");

  my $result = "$n";

  # "n"

=back

=over 4

=item operation: C<(eq)>

This package overloads the C<eq> operator.

B<example 1>

  # given: synopsis;

  my $result = $enum eq "";

  # 1

B<example 2>

  # given: synopsis;

  my $s = $enum->get("s");

  my $result = $s eq "s";

  # 1

=back

=over 4

=item operation: C<(ne)>

This package overloads the C<ne> operator.

B<example 1>

  # given: synopsis;

  my $result = $enum ne "";

  # 0

B<example 2>

  # given: synopsis;

  my $n = $enum->get("n");

  my $result = $n ne "";

  # 1

=back

=over 4

=item operation: C<(qr)>

This package overloads the C<qr> operator.

B<example 1>

  # given: synopsis;

  my $n = $enum->get('n');

  my $test = 'north' =~ qr/$n/;

  # 1

=back

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2022, Awncorp, C<awncorp@cpan.org>.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut