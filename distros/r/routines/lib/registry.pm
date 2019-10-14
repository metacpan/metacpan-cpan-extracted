package registry;

use 5.014;

use strict;
use warnings;

use base 'Exporter';

our $VERSION = '0.02'; # VERSION

our @EXPORT = '$registry';

state %registries;

sub access {
  my ($class) = @_;

  $class ||= 'main';

  return $registries{$class};
}

sub lookup {
  my ($expr, $class) = @_;

  my $registry = access($class) or return;

  return $registry->lookup($expr);
}

sub import {
  my ($package, $library) = @_;

  my $caller = caller(0);

  require Type::Registry;

  my $object = $registries{$caller} ||= Type::Registry->for_class($caller);

  $library ||= 'Types::Standard';

  $object->add_types($library);

  return $package->export_to_level(1, $package);
}

our $registry = __PACKAGE__->can('access');

1;

=encoding utf8

=head1 NAME

registry

=cut

=head1 ABSTRACT

Register Type Libraries with Namespaces

=cut

=head1 SYNOPSIS

  package main;

  use strict;
  use warnings;
  use registry;

  $registry;

  # $registry->('main')
  # 'main' Type::Registry object

  # or ...
  # return registry object based on caller
  # registry::access('main')

  # and ...
  # resolve type expressions based on caller
  # registry::lookup('ClassName')

=cut

=head1 DESCRIPTION

This pragma is used to associate the calling package with L<Type::Tiny> type
libraries. A C<$registry> variable is made available to the caller to be used
to access registry objects. The variable is a callback (i.e. coderef) which
should be called with a single argument, the namespace whose registry object
you want, otherwise the argument defaults to C<main>.

  package main;

  use strict;
  use warnings;

  use registry 'Types::Standard';
  use registry 'Types::Common::Numeric';
  use registry 'Types::Common::String';

  $registry;

  # resolve type expression using exported variable
  # my $constraint = $registry->('main')->lookup('StrLength[10]')

  # resolve type expression using registry function
  # my $constraint = registry::lookup('StrLength[10]', 'main')

You can configure the calling package to be associated with multiple distinct
type libraries. The exported C<$registry> object can be used to reify type
constraints and resolve type expressions.

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
