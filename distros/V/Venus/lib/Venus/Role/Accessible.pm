package Venus::Role::Accessible;

use 5.018;

use strict;
use warnings;

use Venus::Role 'fault';

# AUDITS

sub AUDIT {
  my ($self, $from) = @_;

  if (!$from->isa('Venus::Core')) {
    fault "${self} requires ${from} to derive from Venus::Core";
  }

  return $self;
}

# METHODS

sub access {
  my ($self, $name, @args) = @_;

  return if !$name;

  return $self->$name(@args);
}

sub assign {
  my ($self, $name, $code, @args) = @_;

  return if !$name;
  return if !$code;

  return $self->access($name, $self->$code(@args));
}

# EXPORTS

sub EXPORT {
  ['access', 'assign']
}

1;



=head1 NAME

Venus::Role::Accessible - Accessible Role

=cut

=head1 ABSTRACT

Accessible Role for Perl 5

=cut

=head1 SYNOPSIS

  package Example;

  use Venus::Class;

  with 'Venus::Role::Accessible';

  attr 'value';

  sub downcase {
    lc $_[0]->value
  }

  sub upcase {
    uc $_[0]->value
  }

  package main;

  my $example = Example->new(value => 'hello, there');

  # $example->value;

=cut

=head1 DESCRIPTION

This package modifies the consuming package and provides the C<access> method
for getting and setting attributes.

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 access

  access(Str $name, Any $value) (Any)

The access method gets or sets the class attribute specified.

I<Since C<1.23>>

=over 4

=item access example 1

  # given: synopsis

  package main;

  my $access = $example->access;

  # undef

=back

=over 4

=item access example 2

  # given: synopsis

  package main;

  my $access = $example->access('value');

  # "hello, there"

=back

=over 4

=item access example 3

  # given: synopsis

  package main;

  my $access = $example->access('value', 'something');

  # "something"

=back

=over 4

=item access example 4

  # given: synopsis

  package main;

  my $instance = $example;

  # bless({}, "Example")

  $example->access('value', 'something');

  # "something"

  $instance = $example;

  # bless({value => "something"}, "Example")

=back

=cut

=head2 assign

  assign(Str $name, Str | CodeRef $code, Any @args) (Any)

The assign method dispatches the method call or executes the callback, sets the
class attribute specified to the result, and returns the result.

I<Since C<1.23>>

=over 4

=item assign example 1

  # given: synopsis

  package main;

  my $assign = $example->assign('value', 'downcase');

  # "hello, there"

=back

=over 4

=item assign example 2

  # given: synopsis

  package main;

  my $assign = $example->assign('value', 'upcase');

  # "HELLO, THERE"

=back

=over 4

=item assign example 3

  # given: synopsis

  package main;

  my $instance = $example;

  # bless({value => "hello, there"}, "Example")

  my $assign = $example->assign('value', 'downcase');

  # "hello, there"

  $instance = $example;

  # bless({value => "hello, there"}, "Example")

=back

=cut