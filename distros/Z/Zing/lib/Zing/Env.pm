package Zing::Env;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

use Cwd ();
use Sys::Hostname ();

our $VERSION = '0.25'; # VERSION

# ATTRIBUTES

has app => (
  is => 'ro',
  isa => 'App',
  new => 1,
);

fun new_app($self) {
  require Zing::App; Zing::App->new(env => $self);
}

has appdir => (
  is => 'ro',
  isa => 'Maybe[Str]',
  new => 1,
);

fun new_appdir($self) {
  $ENV{ZING_APPDIR};
}

has config => (
  is => 'ro',
  isa => 'HashRef[ArrayRef]',
  new => 1,
);

fun new_config($self) {
  my $config = {};
  for my $KEY (grep /ZING_CONFIG_/, keys %ENV) {
    $config->{lc($KEY =~ s/ZING_CONFIG_//r)} = [
      map +($$_[0], $#{$$_[1]} ? $$_[1] : $$_[1][0]),
      map [$$_[0], [split /\|/, $$_[1]]],
      map [split /=/], split /,\s*/,
      $ENV{$KEY} || ''
    ];
  }
  $config;
}

has debug => (
  is => 'ro',
  isa => 'Maybe[Bool]',
  new => 1,
);

fun new_debug($self) {
  $ENV{ZING_DEBUG}
}

has encoder => (
  is => 'ro',
  isa => 'Maybe[Str]',
  new => 1,
);

fun new_encoder($self) {
  $ENV{ZING_ENCODER} || 'Zing::Encoder::Dump'
}

has handle => (
  is => 'ro',
  isa => 'Maybe[Str]',
  new => 1,
);

fun new_handle($self) {
  $ENV{ZING_HANDLE} || $ENV{ZING_NS}
}

has home => (
  is => 'ro',
  isa => 'Maybe[Str]',
  new => 1,
);

fun new_home($self) {
  $ENV{ZING_HOME} || Cwd::getcwd
}

has host => (
  is => 'ro',
  isa => 'Maybe[Str]',
  new => 1,
);

fun new_host($self) {
  $ENV{ZING_HOST} || Sys::Hostname::hostname
}

has piddir => (
  is => 'ro',
  isa => 'Maybe[Str]',
  new => 1,
);

fun new_piddir($self) {
  $ENV{ZING_PIDDIR}
}

has store => (
  is => 'ro',
  isa => 'Maybe[Str]',
  new => 1,
);

fun new_store($self) {
  $ENV{ZING_STORE} || 'Zing::Store::Hash'
}

has target => (
  is => 'ro',
  isa => 'Maybe[Name]',
  new => 1,
);

fun new_target($self) {
  $ENV{ZING_TARGET}
}

has system => (
  is => 'ro',
  isa => 'Name',
  new => 1,
);

fun new_system($self) {
  'zing'
}

1;

=encoding utf8

=head1 NAME

Zing::Env - Zing Environment

=cut

=head1 ABSTRACT

Zing Environment Abstraction

=cut

=head1 SYNOPSIS

  use Zing::Env;

  my $env = Zing::Env->new;

=cut

=head1 DESCRIPTION

This package provides a L<Zing> environment abstraction to be used by
L<Zing::App> and other environment-aware objects.

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

=head2 appdir

  appdir(Maybe[Str])

This attribute is read-only, accepts C<(Maybe[Str])> values, and is optional.

=cut

=head2 config

  config(HashRef[ArrayRef])

This attribute is read-only, accepts C<(HashRef[ArrayRef])> values, and is optional.

=cut

=head2 debug

  debug(Maybe[Bool])

This attribute is read-only, accepts C<(Maybe[Bool])> values, and is optional.

=cut

=head2 encoder

  encoder(Maybe[Str])

This attribute is read-only, accepts C<(Maybe[Str])> values, and is optional.

=cut

=head2 handle

  handle(Maybe[Str])

This attribute is read-only, accepts C<(Maybe[Str])> values, and is optional.

=cut

=head2 home

  home(Maybe[Str])

This attribute is read-only, accepts C<(Maybe[Str])> values, and is optional.

=cut

=head2 host

  host(Maybe[Str])

This attribute is read-only, accepts C<(Maybe[Str])> values, and is optional.

=cut

=head2 piddir

  piddir(Maybe[Str])

This attribute is read-only, accepts C<(Maybe[Str])> values, and is optional.

=cut

=head2 store

  store(Maybe[Str])

This attribute is read-only, accepts C<(Maybe[Str])> values, and is optional.

=cut

=head2 system

  system(Name)

This attribute is read-only, accepts C<(Name)> values, and is optional.

=cut

=head2 target

  target(Maybe[Name])

This attribute is read-only, accepts C<(Maybe[Name])> values, and is optional.

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
