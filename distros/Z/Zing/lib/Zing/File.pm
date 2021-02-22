package Zing::File;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;

extends 'Exporter';

our @EXPORT_OK = 'scheme';

our $VERSION = '0.27'; # VERSION

# FUNCTIONS

fun scheme(Scheme | ArrayRef[Scheme | ArrayRef] $expr) {
  if (ref $expr->[0]) {
    return ['Zing::Ringer', [schemes => [map scheme($_), @$expr]], 1];
  }
  else {
    return ['Zing::Watcher', [on_scheme => sub { $expr }], 1];
  }
}

# METHODS

method interpret(Scheme | ArrayRef[Scheme | ArrayRef] $expr) {
  return scheme($expr);
}

1;



=encoding utf8

=head1 NAME

Zing::File - Supervision Tree Generator

=cut

=head1 ABSTRACT

Zing Supervision Tree Generator

=cut

=head1 SYNOPSIS

  use Zing::File;

  my $file = Zing::File->new;

  # $file->interpret([['MyApp::Client', [], 2], ['MyApp::Server', [], 1]])

=cut

=head1 DESCRIPTION

This package provides a mechnism for generating executable supervision trees.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 FUNCTIONS

This package implements the following functions:

=cut

=head2 scheme

  scheme(Scheme | ArrayRef[Scheme | ArrayRef] $expr) : Scheme

The scheme function converts the expression provided, which itself is either a
scheme or a list of schemes (which can be nested), to a scheme representing a
supervision tree with L<Zing::Ringer> and L<Zing::Watcher> processes.

=over 4

=item scheme example #1

  use Zing::File 'scheme';

  scheme([['MyApp::Client', [], 2], ['MyApp::Server', [], 1]]);

=back

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 interpret

  interpret(Scheme | ArrayRef[Scheme | ArrayRef] $expr) : Scheme

The interpret method passes the expression provided to the L</scheme> function
to generate a scheme.

=over 4

=item interpret example #1

  # given: synopsis

  $file->interpret([['MyApp::Client', [], 2], ['MyApp::Server', [], 1]]);

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
