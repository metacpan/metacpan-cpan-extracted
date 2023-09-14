package Venus::Role::Proxyable;

use 5.018;

use strict;
use warnings;

use Venus::Role 'with';

# METHODS

sub AUTOLOAD {
  require Venus::Error;

  my ($package, $method) = our $AUTOLOAD =~ m[^(.+)::(.+)$];

  my $build = $package->can('BUILDPROXY');

  my $error = qq(Can't locate object method "$method" via package "$package");

  Venus::Error->throw($error) unless $build && ref($build) eq 'CODE';

  my $proxy = $build->($package, $method, @_);

  Venus::Error->throw($error) unless $proxy && ref($proxy) eq 'CODE';

  goto &$proxy;
}

sub BUILDPROXY {
  require Venus::Error;

  my ($package, $method, $self, @args) = @_;

  my $build = $self->can('build_proxy');

  return $build->($self, $package, $method, @args) if $build;

  my $error = qq(Can't locate object method "build_proxy" via package "$package");

  Venus::Error->throw($error);
}

# EXPORTS

sub EXPORT {
  ['AUTOLOAD', 'BUILDPROXY']
}

1;



=head1 NAME

Venus::Role::Proxyable - Proxyable Role

=cut

=head1 ABSTRACT

Proxyable Role for Perl 5

=cut

=head1 SYNOPSIS

  package Example;

  use Venus::Class;

  with 'Venus::Role::Proxyable';

  attr 'test';

  sub build_proxy {
    my ($self, $package, $method, @args) = @_;
    return sub { [$self, $package, $method, @args] } if $method eq 'anything';
    return undef;
  }

  package main;

  my $example = Example->new(test => time);

  # $example->anything(1..4);

=cut

=head1 DESCRIPTION

This package provides a hook into method dispatch resoluton via a wrapper
around the C<AUTOLOAD> routine which processes calls to routines which don't
exist.

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 build_proxy

  build_proxy(string $package, string $method, any @args) (coderef | undef)

The build_proxy method should return a code reference to fulfill the method
dispatching request, or undef to result in a method not found error.

I<Since C<0.01>>

=over 4

=item build_proxy example 1

  package main;

  my $example = Example->new(test => 123);

  my $build_proxy = $example->build_proxy('Example', 'everything', 1..4);

  # undef

=back

=over 4

=item build_proxy example 2

  package main;

  my $example = Example->new(test => 123);

  my $build_proxy = $example->build_proxy('Example', 'anything', 1..4);

  # sub { ... }

=back

=cut

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2000, Awncorp, C<awncorp@cpan.org>.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut