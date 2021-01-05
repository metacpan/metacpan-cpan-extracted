package Zing::Encoder;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;

our $VERSION = '0.26'; # VERSION

# METHODS

method decode(HashRef $data) {
  return $data;
}

method encode(HashRef $data) {
  return $data;
}

1;

=encoding utf8

=head1 NAME

Zing::Encoder - Serialization Abstraction

=cut

=head1 ABSTRACT

Data Serialization Abstraction

=cut

=head1 SYNOPSIS

  use Zing::Encoder;

  my $encoder = Zing::Encoder->new;

  # $encoder->encode({ status => 'okay' });

=cut

=head1 DESCRIPTION

This package provides a data serialization abstraction for use with
L<Zing::Store> stores.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 decode

  decode(HashRef $data) : HashRef

The decode method decodes the data provided.

=over 4

=item decode example #1

  # given: synopsis

  $encoder->decode({ status => 'okay' });

=back

=cut

=head2 encode

  encode(HashRef $data) : HashRef

The encode method encodes the data provided.

=over 4

=item encode example #1

  # given: synopsis

  $encoder->encode({ status => 'okay' });

=back

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
