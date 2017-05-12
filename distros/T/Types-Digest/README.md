[![Build Status](https://travis-ci.org/JaSei/Types-Digest.svg?branch=master)](https://travis-ci.org/JaSei/Types-Digest)
# NAME

Types::Digest - digests types for Moose and Moo

# SYNOPSIS

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

     

# DESCRIPTION

This module provides common digests types for Moose, Moo, etc.

# SUBTYPES

## Md5

[MD5](https://en.wikipedia.org/wiki/MD5)

## Sha1

[SHA-1](https://en.wikipedia.org/wiki/SHA-1)

## Sha224

[SHA-2](https://en.wikipedia.org/wiki/SHA-2)

## Sha256

[SHA-2](https://en.wikipedia.org/wiki/SHA-2)

## Sha384

[SHA-2](https://en.wikipedia.org/wiki/SHA-2)

## Sha512

[SHA-2](https://en.wikipedia.org/wiki/SHA-2)

# SEE ALSO

this module is inspired by [MooseX::Types::Digest](https://metacpan.org/pod/MooseX::Types::Digest)

# LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Jan Seidl <seidl@avast.com>
