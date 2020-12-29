package Zing::Error;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;

extends 'Data::Object::Exception';

our $VERSION = '0.22'; # VERSION

1;

=encoding utf8

=head1 NAME

Zing::Error - Exception Class

=cut

=head1 ABSTRACT

Generic Exception Class

=cut

=head1 SYNOPSIS

  use Zing::Error;

  my $error = Zing::Error->new(
    message => 'Oops',
  );

  # die $error;

=cut

=head1 DESCRIPTION

This package provides a generic L<Zing> exception class.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Data::Object::Exception>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

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
