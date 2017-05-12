package Types::Digest;
use strict;
use warnings;

our $VERSION = '0.1.2';

use Type::Library -base, -declare => qw(Md5 Sha1 Sha224 Sha256 Sha384 Sha512);
use Types::Standard qw(Str);
use Type::Utils;

=head1 NAME

Types::Digest - digests types for Moose and Moo

=head1 SYNOPSIS

    package Foo;
     
    use Moose;
    use Types::Digest qw/Md5 Sha256/;
     
    has md5 => (
      is  => 'ro',
      isa => Md5,
    );

    has sha256 => (
      is  => 'ro',
      isa => Sha256,
    );

     
=head1 DESCRIPTION

This module provides common digests types for Moose, Moo, etc.

=head1 SUBTYPES

=head2 Md5

L<MD5|https://en.wikipedia.org/wiki/MD5>

=head2 Sha1

L<SHA-1|https://en.wikipedia.org/wiki/SHA-1>

=head2 Sha224

L<SHA-2|https://en.wikipedia.org/wiki/SHA-2>

=head2 Sha256

L<SHA-2|https://en.wikipedia.org/wiki/SHA-2>

=head2 Sha384

L<SHA-2|https://en.wikipedia.org/wiki/SHA-2>

=head2 Sha512

L<SHA-2|https://en.wikipedia.org/wiki/SHA-2>

=cut

_declare_digest('Md5', 32);
_declare_digest('Sha1', 40);
_declare_digest('Sha224', 56);
_declare_digest('Sha256', 64);
_declare_digest('Sha384', 96);
_declare_digest('Sha512', 128);

sub _declare_digest {
    my ($name, $len) = @_;

    declare $name,
        as Str, where { /[a-f0-9]{$len}/i },
        message { "Must be $len chars, and contain only [0-9a-fA-F]" };
}

=head1 SEE ALSO

this module is inspired by L<MooseX::Types::Digest>

=head1 LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jan Seidl E<lt>seidl@avast.comE<gt>

=cut

1;
