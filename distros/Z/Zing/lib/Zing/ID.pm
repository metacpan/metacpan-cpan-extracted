package Zing::ID;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

use Sys::Hostname ();

use overload (
  '""'     => 'string',
  fallback => 1
);

our $VERSION = '0.27'; # VERSION

# ATTRIBUTES

has host => (
  is => 'ro',
  isa => 'Str',
  init_arg => undef,
  new => 1,
);

fun new_host($self) {
  Sys::Hostname::hostname
}

has iota => (
  is => 'ro',
  isa => 'Int',
  init_arg => undef,
  new => 1,
);

my ($i, $t, $x) = (0, time);

fun new_iota($self) {
  $x = sprintf('%04d', ($i = ($t == time ? $i + 1 : 1)));
  $t = time; # reset
  $x
}

has pid => (
  is => 'ro',
  isa => 'Int',
  init_arg => undef,
  new => 1,
);

fun new_pid($self) {
  $$
}

has salt => (
  is => 'ro',
  isa => 'Str',
  new => 1,
);

fun new_salt($self) {
  rand
}

has time => (
  is => 'ro',
  isa => 'Int',
  init_arg => undef,
  new => 1,
);

fun new_time($self) {
  time
}

# METHODS

method string() {
  require Digest::SHA; return Digest::SHA::sha1_hex(
    join('-', map $self->$_, qw(host pid time iota salt))
  );
}

1;



=encoding utf8

=head1 NAME

Zing::ID - Conditionally Unique Identifier

=cut

=head1 ABSTRACT

Conditionally Unique Identifier

=cut

=head1 SYNOPSIS

  use Zing::ID;

  my $id = Zing::ID->new;

  # "$id"

=cut

=head1 DESCRIPTION

This package provides a globally unique identifier.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 host

  host(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 iota

  iota(Int)

This attribute is read-only, accepts C<(Int)> values, and is optional.

=cut

=head2 pid

  pid(Int)

This attribute is read-only, accepts C<(Int)> values, and is optional.

=cut

=head2 salt

  salt(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 time

  time(Int)

This attribute is read-only, accepts C<(Int)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 string

  string() : Str

The string method serializes the object properties and generates a globally
unique identifier.

=over 4

=item string example #1

  # given: synopsis

  $id->string;

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/cpanery/zing/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/cpanery/zing/wiki>

L<Project|https://github.com/cpanery/zing>

L<Initiatives|https://github.com/cpanery/zing/projects>

L<Milestones|https://github.com/cpanery/zing/milestones>

L<Contributing|https://github.com/cpanery/zing/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/cpanery/zing/issues>

=cut
