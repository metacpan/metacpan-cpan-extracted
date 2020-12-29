package Zing::Entity;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Zing::Class';

our $VERSION = '0.22'; # VERSION

# ATTRIBUTES

has app => (
  is => 'ro',
  isa => 'App',
  new => 1,
);

fun new_app($self) {
  $self->env->app
}

has env => (
  is => 'ro',
  isa => 'Env',
  new => 1,
);

fun new_env($self) {
  require Zing::Env; Zing::Env->new;
}

# BUILDERS

fun BUILD($self, $args) {
  $self->{env} = $self->{app}->env if $self->{app} && !$self->{env};

  return $self;
}

1;

=encoding utf8

=head1 NAME

Zing::Entity - Environment-aware Base Class

=cut

=head1 ABSTRACT

Environment-aware Abstract Base Class

=cut

=head1 SYNOPSIS

  use Zing::Entity;

  my $entity = Zing::Entity->new;

  # $entity->app;
  # $entity->env;

=cut

=head1 DESCRIPTION

This package provides an environment-aware abstract base class for L<Zing>
classes that need to be environment-aware.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Zing::Class>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 app

  app(App)

This attribute is read-only, accepts C<(App)> values, and is optional.

=cut

=head2 env

  env(Env)

This attribute is read-only, accepts C<(Env)> values, and is optional.

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/zing/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/zing/wiki>

L<Project|https://github.com/iamalnewkirk/zing>

L<Initiatives|https://github.com/iamalnewkirk/zing/projects>

L<Milestones|https://github.com/iamalnewkirk/zing/milestones>

L<Contributing|https://github.com/iamalnewkirk/zing/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/zing/issues>

=cut
