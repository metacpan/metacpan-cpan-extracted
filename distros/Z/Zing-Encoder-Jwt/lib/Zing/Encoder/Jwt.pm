package Zing::Encoder::Jwt;

use 5.014;

use strict;
use warnings;

use registry 'Zing::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Zing::Encoder';

use Crypt::JWT ();

our $VERSION = '0.01'; # VERSION

# ATTRIBUTES

has algo => (
  is => 'ro',
  isa => 'Str',
  new => 1,
);

fun new_algo($self) {
  $ENV{ZING_JWT_ALGO} || 'HS256'
}

has secret => (
  is => 'ro',
  isa => 'Str',
  new => 1,
);

fun new_secret($self) {
  $ENV{ZING_JWT_SECRET}
}

# METHODS

method decode(Str $data) {
  return Crypt::JWT::decode_jwt(
    key => $self->secret,
    token => $data,
  );
}

method encode(HashRef $data) {
  return Crypt::JWT::encode_jwt(
    alg => $self->algo,
    key => $self->secret,
    payload => $data,
  );
}

1;

=encoding utf8

=head1 NAME

Zing::Encoder::Jwt - JWT Serialization Abstraction

=cut

=head1 ABSTRACT

JWT Data Serialization Abstraction

=cut

=head1 SYNOPSIS

  use Zing::Encoder::Jwt;

  my $encoder = Zing::Encoder::Jwt->new(
    secret => '...',
  );

  # $encoder->encode({ status => 'okay' });

=cut

=head1 DESCRIPTION

This package provides a L<Crypt::JWT> data serialization abstraction for use
with L<Zing::Store> stores. The JWT encoding algorithm can be set using the
C<ZING_JWT_ALGO> environment variable or the I<algo> attribute, and defaults to
I<HS256>. The JWT secret can be set using the C<ZING_JWT_SECRET> environment
variable or the I<secret> attribute.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Zing::Types>

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 decode

  decode(Str $data) : HashRef

The decode method decodes the data provided.

=over 4

=item decode example #1

  # given: synopsis

  $encoder->decode('eyJhbGciOiJIUzI1NiJ9.eyJzdGF0dXMiOiJva2F5In0.tXdQmMPi25VOJZaOySFS-hM2ofIxbyFBVTA7I-GI_lU');

=back

=cut

=head2 encode

  encode(HashRef $data) : Str

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
file"|https://github.com/iamalnewkirk/zing-encoder-jwt/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/zing-encoder-jwt/wiki>

L<Project|https://github.com/iamalnewkirk/zing-encoder-jwt>

L<Initiatives|https://github.com/iamalnewkirk/zing-encoder-jwt/projects>

L<Milestones|https://github.com/iamalnewkirk/zing-encoder-jwt/milestones>

L<Contributing|https://github.com/iamalnewkirk/zing-encoder-jwt/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/zing-encoder-jwt/issues>

=cut