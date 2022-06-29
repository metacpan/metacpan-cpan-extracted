package Venus::Kind::Utility;

use 5.018;

use strict;
use warnings;

use Moo;

extends 'Venus::Kind';

with 'Venus::Role::Buildable';

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

  extends 'Venus::Kind::Utility';

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