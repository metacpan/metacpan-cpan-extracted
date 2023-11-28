package Venus::Kind::Utility;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base', 'with';

base 'Venus::Kind';

with 'Venus::Role::Buildable';

# BUILDERS

sub build_arg {
  my ($self, $data) = @_;

  return {
    value => $data,
  };
}

1;



=head1 NAME

Venus::Kind::Utility - Utility Base Class

=cut

=head1 ABSTRACT

Utility Base Class for Perl 5

=cut

=head1 SYNOPSIS

  package Example;

  use Venus::Class;

  base 'Venus::Kind::Utility';

  package main;

  my $example = Example->new;

=cut

=head1 DESCRIPTION

This package provides identity and methods common across all L<Venus> utility
classes.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Kind>

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Venus::Role::Buildable>

=cut

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2022, Awncorp, C<awncorp@cpan.org>.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut