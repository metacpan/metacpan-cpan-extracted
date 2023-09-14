package Venus::Role::Rejectable;

use 5.018;

use strict;
use warnings;

use Venus::Role 'with';

# BUILDERS

sub BUILD {
  my ($self) = @_;

  my %attrs = map +($_, $_), $self->META->attrs;
  my @unknowns = sort grep !exists($attrs{$_}), keys %$self;
  delete $self->{$_} for @unknowns;

  return $self;
}

1;



=head1 NAME

Venus::Role::Rejectable - Rejectable Role

=cut

=head1 ABSTRACT

Rejectable Role for Perl 5

=cut

=head1 SYNOPSIS

  package ExampleAccept;

  use Venus::Class 'attr';

  attr 'name';

  package ExampleReject;

  use Venus::Class 'attr', 'with';

  with 'Venus::Role::Rejectable';

  attr 'name';

  package main;

  my $example = ExampleReject->new(name => 'example', test => 12345);

  # bless({name => 'example'}, "Example")

=cut

=head1 DESCRIPTION

This package provides a mechanism for rejecting unexpected constructor arguments.

=cut

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2000, Awncorp, C<awncorp@cpan.org>.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut