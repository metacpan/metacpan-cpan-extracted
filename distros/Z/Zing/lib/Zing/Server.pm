package Zing::Server;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

use Socket;
use Sys::Hostname;

our $VERSION = '0.12'; # VERSION

# ATTRIBUTES

has 'name' => (
  is => 'ro',
  isa => 'Str',
  new => 1,
);

state $local = $ENV{ZING_HOST} || '0.0.0.0';

fun new_name($self) {
  state $host = gethostbyname(hostname || 'localhost') if !$ENV{ZING_HOST};
  $host ? inet_ntoa($host) : $local
}

1;

=encoding utf8

=head1 NAME

Zing::Server - Server Information

=cut

=head1 ABSTRACT

Process Server Information

=cut

=head1 SYNOPSIS

  use Zing::Server;

  my $server = Zing::Server->new;

=cut

=head1 DESCRIPTION

This package provides represents a server within a network and cluster.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 name

  name(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/zing/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/zing/wiki>

L<Project|https://github.com/iamalnewkirk/zing>

L<Initiatives|https://github.com/iamalnewkirk/zing/projects>

L<Milestones|https://github.com/iamalnewkirk/zing/milestones>

L<Contributing|https://github.com/iamalnewkirk/zing/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/zing/issues>

=cut
