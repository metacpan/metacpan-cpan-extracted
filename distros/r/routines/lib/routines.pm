package routines;

use 5.014;

use strict;
use warnings;

our $VERSION = '0.02'; # VERSION

sub import {
  require Function::Parameters;

  Function::Parameters->import(
    settings(@_)
  )
}

sub settings {
  my ($class, @args) = @_;

  require registry;

  # reifier config
  my $caller = caller(1);
  my $registry = registry::access($caller);
  my $reifier = sub { $registry->lookup($_[0]) };
  my @config = $registry ? ($class, $reifier) : ($class);

  # keyword config
  my %settings;

  %settings = (func_settings(@config), %settings);
  %settings = (meth_settings(@config), %settings);
  %settings = (befr_settings(@config), %settings);
  %settings = (aftr_settings(@config), %settings);
  %settings = (arnd_settings(@config), %settings);
  %settings = (augm_settings(@config), %settings);
  %settings = (over_settings(@config), %settings);

  return {%settings};
}

sub func_settings {
  my ($class, $reifier) = @_;

  return (fun => {
    check_argument_count => 0, # for backwards compat :(
    check_argument_types => 1,
    default_arguments    => 1,
    defaults             => 'function',
    invocant             => 1,
    name                 => 'optional',
    named_parameters     => 1,
    runtime              => 1,
    types                => 1,

    # include reifier or fallback to function-based
    ($reifier ? (reify_type => $reifier) : ())
  });
}

sub meth_settings {
  my ($class, $reifier) = @_;

  return (method => {
    attributes           => ':method',
    check_argument_count => 0, # for backwards compat :(
    check_argument_types => 1,
    default_arguments    => 1,
    defaults             => 'method',
    invocant             => 1,
    name                 => 'optional',
    named_parameters     => 1,
    runtime              => 1,
    shift                => '$self',
    types                => 1,

    # include reifier or fallback to function-based
    ($reifier ? (reify_type => $reifier) : ())
  });
}

sub aftr_settings {
  my ($class, $reifier) = @_;

  return (after => {
    attributes           => ':method',
    check_argument_count => 0, # for backwards compat :(
    check_argument_types => 1,
    default_arguments    => 1,
    defaults             => 'method',
    install_sub          => 'after',
    invocant             => 1,
    name                 => 'required',
    named_parameters     => 1,
    runtime              => 1,
    shift                => '$self',
    types                => 1,

    # include reifier or fallback to function-based
    ($reifier ? (reify_type => $reifier) : ())
  });
}

sub befr_settings {
  my ($class, $reifier) = @_;

  return (before => {
    attributes           => ':method',
    check_argument_count => 0, # for backwards compat :(
    check_argument_types => 1,
    default_arguments    => 1,
    defaults             => 'method',
    install_sub          => 'before',
    invocant             => 1,
    name                 => 'required',
    named_parameters     => 1,
    runtime              => 1,
    shift                => '$self',
    types                => 1,

    # include reifier or fallback to function-based
    ($reifier ? (reify_type => $reifier) : ())
  });
}

sub arnd_settings {
  my ($class, $reifier) = @_;

  return (around => {
    attributes           => ':method',
    check_argument_count => 0, # for backwards compat :(
    check_argument_types => 1,
    default_arguments    => 1,
    defaults             => 'method',
    install_sub          => 'around',
    invocant             => 1,
    name                 => 'required',
    named_parameters     => 1,
    runtime              => 1,
    shift                => ['$orig', '$self'],
    types                => 1,

    # include reifier or fallback to function-based
    ($reifier ? (reify_type => $reifier) : ())
  });
}

sub augm_settings {
  my ($class, $reifier) = @_;

  return (augment => {
    attributes           => ':method',
    check_argument_count => 0, # for backwards compat :(
    check_argument_types => 1,
    default_arguments    => 1,
    defaults             => 'method',
    install_sub          => 'augment',
    invocant             => 1,
    name                 => 'required',
    named_parameters     => 1,
    runtime              => 1,
    shift                => '$self',
    types                => 1,

    # include reifier or fallback to function-based
    ($reifier ? (reify_type => $reifier) : ())
  });
}

sub over_settings {
  my ($class, $reifier) = @_;

  return (override => {
    attributes           => ':method',
    check_argument_count => 0, # for backwards compat :(
    check_argument_types => 1,
    default_arguments    => 1,
    defaults             => 'method',
    install_sub          => 'override',
    invocant             => 1,
    name                 => 'required',
    named_parameters     => 1,
    runtime              => 1,
    shift                => '$self',
    types                => 1,

    # include reifier or fallback to function-based
    ($reifier ? (reify_type => $reifier) : ())
  });
}

1;

=encoding utf8

=head1 NAME

routines

=cut

=head1 ABSTRACT

Typeable Method and Function Signatures

=cut

=head1 SYNOPSIS

  package main;

  use strict;
  use warnings;

  use routines;

  fun hello($name) {
    "hello, $name"
  }

  hello("world");

=cut

=head1 DESCRIPTION

This pragma is used to provide typeable method and function signtures to the
calling package, as well as C<before>, C<after>, C<around>, C<augment> and
C<override> method modifiers.

  package main;

  use strict;
  use warnings;

  use registry;
  use routines;

  fun hello(Str $name) {
    "hello, $name"
  }

  hello("world");

Additionally, when used in concert with the L<registry> pragma, this pragma will
check to determine whether a L<Type::Tiny> registry object is associated with
the calling package and if so will use it to reify type constraints and
resolve type expressions.

  package Example;

  use Moo;

  use registry;
  use routines;

  fun new($class) {
    bless {}, $class
  }

  method hello(Str $name) {
    "hello, $name"
  }

  around hello(Str $name) {
    $self->{name} = $name;

    $self->$orig($name);
  }

  1;

This functionality is based on L<Function::Parameters> and uses Perl's keyword
plugn API to provide new keywords. As mentioned previously, this pragma makes
the C<before>, C<after>, C<around>, C<augment>, and C<override> method
modifiers available to the calling package where that functionality is already
present in its generic subroutine callback form.

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/routines/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/routines/wiki>

L<Project|https://github.com/iamalnewkirk/routines>

L<Initiatives|https://github.com/iamalnewkirk/routines/projects>

L<Milestones|https://github.com/iamalnewkirk/routines/milestones>

L<Contributing|https://github.com/iamalnewkirk/routines/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/routines/issues>

=cut
