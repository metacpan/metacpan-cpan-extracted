package Venus::Role::Pluggable;

use 5.018;

use strict;
use warnings;

use Venus::Role 'fault';

# AUDITS

sub AUDIT {
  my ($self, $from) = @_;

  if (!$from->does('Venus::Role::Proxyable')) {
    fault "${self} requires ${from} to consume Venus::Role::Proxyable";
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
    if ($space->package->can('construct')) {
      my $class = $space->load;

      return $class->construct($self, @args)->execute;
    }
    else {
      my $class = $space->load;

      return $class->new->execute($self, @args);
    }
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

  package Example::Plugin::Username;

  use Venus::Class;

  use Digest::SHA ();

  sub execute {
    my ($self, $example) = @_;

    return Digest::SHA::sha1_hex($example->login);
  }

  package Example::Plugin::Password;

  use Venus::Class;

  use Digest::SHA ();

  attr 'value';

  sub construct {
    my ($class, $example) = @_;

    return $class->new(value => $example->secret);
  }

  sub execute {
    my ($self) = @_;

    return Digest::SHA::sha1_hex($self->value);
  }

  package Example;

  use Venus::Class;

  with 'Venus::Role::Proxyable';
  with 'Venus::Role::Pluggable';

  attr 'login';
  attr 'secret';

  package main;

  my $example = Example->new(login => 'admin', secret => 'p@ssw0rd');

  # $example->username;
  # $example->password;

=cut

=head1 DESCRIPTION

This package provides a mechanism for dispatching to plugin classes.

=cut

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2022, Awncorp, C<awncorp@cpan.org>.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut