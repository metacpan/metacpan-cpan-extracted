package Zing::Cartridge;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Zing::Entity';

use File::Spec;

our $VERSION = '0.26'; # VERSION

# ATTRIBUTES

has appdir => (
  is => 'ro',
  isa => 'Str',
  new => 1,
);

fun new_appdir($self) {
  $self->env->appdir || $self->env->home || File::Spec->curdir
}

has appfile => (
  is => 'ro',
  isa => 'Str',
  new => 1,
);

fun new_appfile($self) {
  File::Spec->catfile($self->appdir, $self->name)
}

has libdir => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  new => 1,
);

fun new_libdir($self) {
  ['.']
}

has piddir => (
  is => 'ro',
  isa => 'Str',
  new => 1,
);

fun new_piddir($self) {
  $self->env->piddir || $self->env->home
}

has pidfile => (
  is => 'ro',
  isa => 'Str',
  new => 1,
);

fun new_pidfile($self) {
  File::Spec->catfile($self->piddir, "@{[$self->name]}.pid")
}

has name => (
  is => 'ro',
  isa => 'Str',
  opt => 1,
);

has scheme => (
  is => 'rw',
  isa => 'Scheme',
  new => 1,
);

fun new_scheme($self) {
  my %seen = map {$_, 1} @INC;
  for my $dir (@{$self->libdir}) {
    push @INC, $dir if !$seen{$dir}++;
  }
  local $@; eval {
    do $self->appfile
  }
}

# METHODS

method pid() {
  local $@; return eval {
    do $self->pidfile
  }
}

method install(Scheme $scheme = $self->scheme) {
  require Data::Dumper;

  no warnings 'once';

  local $Data::Dumper::Indent = 0;
  local $Data::Dumper::Purity = 0;
  local $Data::Dumper::Quotekeys = 0;
  local $Data::Dumper::Deepcopy = 1;
  local $Data::Dumper::Deparse = 1;
  local $Data::Dumper::Sortkeys = 1;
  local $Data::Dumper::Terse = 1;
  local $Data::Dumper::Useqq = 1;

  open(my $fh, '>', $self->appfile) or die "Can't create cartridge: $!";
  print $fh Data::Dumper::Dumper($scheme);
  close $fh;

  return $self;
}

1;

=encoding utf8

=head1 NAME

Zing::Cartridge - Executable Process File

=cut

=head1 ABSTRACT

Executable Process File Abstraction

=cut

=head1 SYNOPSIS

  use Zing::Cartridge;

  my $cartridge = Zing::Cartridge->new(name => 'myapp');

  # $cartridge->pid;

=cut

=head1 DESCRIPTION

This package provides an executable process file abstraction.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Zing::Entity>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 appdir

  appdir(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 appfile

  appfile(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 libdir

  libdir(ArrayRef[Str])

This attribute is read-only, accepts C<(ArrayRef[Str])> values, and is optional.

=cut

=head2 name

  name(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 piddir

  piddir(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 pidfile

  pidfile(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 scheme

  scheme(Scheme)

This attribute is read-only, accepts C<(Scheme)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 install

  install(Scheme $scheme) : Object

The install method creates an executable process file on disk for the scheme
provided.

=over 4

=item install example #1

  # given: synopsis

  $cartridge = $cartridge->install(['MyApp', [], 1]);

=back

=over 4

=item install example #2

  use Zing::Cartridge;

  my $cartridge = Zing::Cartridge->new(scheme => ['MyApp', [], 1]);

  $cartridge = $cartridge->install;

=back

=cut

=head2 pid

  pid() : Maybe[Int]

The pid method returns the process ID of the executed process (if any).

=over 4

=item pid example #1

  # given: synopsis

  my $pid = $cartridge->pid;

=back

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
