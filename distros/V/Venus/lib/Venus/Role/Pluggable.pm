package Venus::Role::Pluggable;

use 5.018;

use strict;
use warnings;

use Venus::Role 'with';

# AUDITS

sub AUDIT {
  my ($self, $from) = @_;

  if (!$from->does('Venus::Role::Proxyable')) {
    die "${self} requires ${from} to consume Venus::Role::Proxyable";
  }

  return $self;
}

# METHODS

sub build_proxy {
  my ($self, $package, $method, @args) = @_;

  require Venus::Space;

  my $space = Venus::Space->new($package)->child('plugin', $method);

  return undef if !$space->tryload;

  return sub {
    return $space->build->execute($self, @args);
  };
}

# EXPORTS

sub EXPORT {
  ['build_proxy']
}

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

  with 'Venus::Role::Proxyable';
  with 'Venus::Role::Pluggable';

  attr 'secret';

  package main;

  my $example = Example->new(secret => rand);

  # $example->password;

=cut

=head1 DESCRIPTION

This package provides a mechanism for dispatching to plugin classes.

=cut