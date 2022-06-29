package Venus::Role::Pluggable;

use 5.018;

use strict;
use warnings;

use Moo::Role;

with 'Venus::Role::Proxyable';

# BUILDERS

sub build_proxy {
  return undef;
}

# MODIFIERS

around build_proxy => sub {
  my ($orig, $self, $package, $method, @args) = @_;

  require Venus::Space;

  my $space = Venus::Space->new($package)->child('plugin', $method);

  return $self->$orig($package, $method, @args) if !$space->tryload;

  return sub {
    return $space->build->execute($self, @args);
  };
};

1;



=head1 NAME

Venus::Role::Pluggable - Pluggable Role

=cut

=head1 ABSTRACT

Pluggable Role for Perl 5

=cut

=head1 SYNOPSIS

  package Example::Plugin::Password;

  use Venus::Class;

  use Digest::SHA ();

  sub execute {
    my ($self, $example) = @_;

    return Digest::SHA::sha1_hex($example->secret);
  }

  package Example;

  use Venus::Class;

  with 'Venus::Role::Pluggable';

  has 'secret';

  package main;

  my $example = Example->new(secret => rand);

  # $example->password;

=cut

=head1 DESCRIPTION

This package provides a mechanism for dispatching to plugin classes.

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Venus::Role::Proxyable>

=cut