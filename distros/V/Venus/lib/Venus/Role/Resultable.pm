package Venus::Role::Resultable;

use 5.018;

use strict;
use warnings;

# IMPORTS

use Venus::Role;

# METHODS

sub result {
  my ($self, $code, @args) = @_;

  require Venus::Result;

  my $result = Venus::Result->new;

  $result = $result->then(sub{$self->$code(@args)}) if $code;

  return $result;
}

# EXPORTS

sub EXPORT {
  ['result']
}

1;



=head1 NAME

Venus::Role::Resultable - Resultable Role

=cut

=head1 ABSTRACT

Resultable Role for Perl 5

=cut

=head1 SYNOPSIS

  package Example;

  use Venus::Class;

  with 'Venus::Role::Resultable';

  sub fail {
    die 'failed';
  }

  sub pass {
    return 'passed';
  }

  package main;

  my $example = Example->new;

  # $example->result('fail');

  # bless(..., "Venus::Result")

=cut

=head1 DESCRIPTION

This package modifies the consuming package and provides a mechanism for
returning dynamically dispatched subroutine calls as L<Venus::Result> objects.

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 result

  result(string | coderef $callback, any @args) (Venus::Result)

The result method dispatches to the named method or coderef provided and
returns a L<Venus::Result> object containing the error or return value
encountered.

I<Since C<4.15>>

=over 4

=item result example 1

  # given: synopsis;

  my $result = $example->result;

  # bless(..., "Venus::Result")

=back

=over 4

=item result example 2

  # given: synopsis;

  my $result = $example->result('pass');

  # bless(..., "Venus::Result")

=back

=over 4

=item result example 3

  # given: synopsis;

  my $result = $example->result('fail');

  # bless(..., "Venus::Result")

=back

=cut

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2022, Awncorp, C<awncorp@cpan.org>.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut