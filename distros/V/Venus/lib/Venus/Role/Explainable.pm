package Venus::Role::Explainable;

use 5.018;

use strict;
use warnings;

use overload (
  '""' => 'explain',
  '~~' => 'explain',
);

use Moo::Role;

# REQUIRES

requires 'explain';

1;



=head1 NAME

Venus::Role::Explainable - Explainable Role

=cut

=head1 ABSTRACT

Explainable Role for Perl 5

=cut

=head1 SYNOPSIS

  package Example;

  use Venus::Class;

  has 'test';

  sub explain {
    "okay"
  }

  with 'Venus::Role::Explainable';

  package main;

  my $example = Example->new(test => 123);

  # $example->explain;

=cut

=head1 DESCRIPTION

This package modifies the consuming package and provides methods for making the
object stringifiable.

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 explain

  explain() (Any)

The explain method takes no arguments and returns the value to be used in
stringification operations.

I<Since C<0.01>>

=over 4

=item explain example 1

  package main;

  my $example = Example->new(test => 123);

  my $explain = $example->explain;

  # "okay"

=back

=cut

=head1 OPERATORS

This package overloads the following operators:

=cut

=over 4

=item operation: C<("")>

This package overloads the C<""> operator.

B<example 1>

  package main;

  my $example = Example->new(test => 123);

  my $string = "$example";

  # "okay"

=back

=over 4

=item operation: C<(~~)>

This package overloads the C<~~> operator.

B<example 1>

  package main;

  my $example = Example->new(test => 123);

  my $result = $example ~~ 'okay';

  # 1

=back