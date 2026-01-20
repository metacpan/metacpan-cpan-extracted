package Venus::Atom;

use 5.018;

use strict;
use warnings;

# IMPORTS

use Venus::Class 'base';

# INHERITS

base 'Venus::Sealed';

# OVERLOADS

use overload (
  '""' => sub{$_[0]->get // ''},
  '~~' => sub{$_[0]->get // ''},
  'eq' => sub{($_[0]->get // '') eq "$_[1]"},
  'ne' => sub{($_[0]->get // '') ne "$_[1]"},
  'qr' => sub{qr/@{[quotemeta($_[0])]}/},
  fallback => 1,
);

# METHODS

sub __get {
  my ($self, $init, $data) = @_;

  return $init->{value};
}

sub __set {
  my ($self, $init, $data, $value) = @_;

  if (ref $value || !defined $value || $value eq '') {
    return undef;
  }

  return $init->{value} = $value if !exists $init->{value};

  return $self->error_on_set->throw;
}

# ERRORS

sub error_on_set {
  my ($self) = @_;

  my $error = $self->error->sysinfo;

  $error->name('on.set');
  $error->message('Can\'t re-set atom value');
  $error->offset(1);
  $error->reset;

  return $error;
}

1;



=head1 NAME

Venus::Atom - Atom Class

=cut

=head1 ABSTRACT

Atom Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Atom;

  my $atom = Venus::Atom->new;

  # $atom->get;

  # undef

=cut

=head1 DESCRIPTION

This package provides a write-once object representing a constant value.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Sealed>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 get

  get() (any)

The get method can be used to get the underlying constant value set during
instantiation.

I<Since C<3.55>>

=over 4

=item get example 1

  # given: synopsis

  package main;

  my $get = $atom->get;

  # undef

=back

=over 4

=item get example 2

  # given: synopsis

  package main;

  $atom->set("hello");

  my $get = $atom->get;

  # "hello"

=back

=cut

=head2 new

  new(any @args) (Venus::Atom)

The new method constructs an instance of the package.

I<Since C<4.15>>

=over 4

=item new example 1

  package main;

  use Venus::Atom;

  my $new = Venus::Atom->new;

  # bless(..., "Venus::Atom")

=back

=over 4

=item new example 2

  package main;

  use Venus::Atom;

  my $new = Venus::Atom->new('Important');

  # bless(..., "Venus::Atom")

=back

=over 4

=item new example 3

  package main;

  use Venus::Atom;

  my $new = Venus::Atom->new(value => 'Important');

  # bless(..., "Venus::Atom")

=back

=cut

=head2 set

  set(any $data) (any)

The set method can be used to set the underlying constant value set during
instantiation or via this method. An atom can only be set once, either at
instantiation of via this method. Any attempt to re-set the atom will result in
an error.

I<Since C<3.55>>

=over 4

=item set example 1

  # given: synopsis

  package main;

  my $set = $atom->set("hello");

  # "hello"

=back

=over 4

=item B<may raise> L<Venus::Atom::Error> C<on.set>

  # given: synopsis

  package main;

  my $set = $atom->set("hello");

  $atom->set("hello");

  # Error! (on.set)

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

  my $result = "$atom";

  # ""

B<example 2>

  # given: synopsis;

  $atom->set("hello");

  my $result = "$atom";

  # "hello"

=back

=over 4

=item operation: C<(eq)>

This package overloads the C<eq> operator.

B<example 1>

  # given: synopsis;

  my $result = $atom eq "";

  # 1

B<example 2>

  # given: synopsis;

  $atom->set("hello");

  my $result = $atom eq "hello";

  # 1

=back

=over 4

=item operation: C<(ne)>

This package overloads the C<ne> operator.

B<example 1>

  # given: synopsis;

  my $result = $atom ne "";

  # 0

B<example 2>

  # given: synopsis;

  $atom->set("hello");

  my $result = $atom ne "";

  # 1

=back

=over 4

=item operation: C<(qr)>

This package overloads the C<qr> operator.

B<example 1>

  # given: synopsis;

  my $test = 'hello' =~ qr/$atom/;

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