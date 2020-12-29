# NAME

Zing::Encoder::Jwt - JWT Serialization Abstraction

# ABSTRACT

JWT Data Serialization Abstraction

# SYNOPSIS

    use Zing::Encoder::Jwt;

    my $encoder = Zing::Encoder::Jwt->new(
      secret => '...',
    );

    # $encoder->encode({ status => 'okay' });

# DESCRIPTION

This package provides a [Crypt::JWT](https://metacpan.org/pod/Crypt::JWT) data serialization abstraction for use
with [Zing::Store](https://metacpan.org/pod/Zing::Store) stores. The JWT encoding algorithm can be set using the
`ZING_JWT_ALGO` environment variable or the _algo_ attribute, and defaults to
_HS256_. The JWT secret can be set using the `ZING_JWT_SECRET` environment
variable or the _secret_ attribute.

# LIBRARIES

This package uses type constraints from:

[Zing::Types](https://metacpan.org/pod/Zing::Types)

# METHODS

This package implements the following methods:

## decode

    decode(Str $data) : HashRef

The decode method decodes the data provided.

- decode example #1

        # given: synopsis

        $encoder->decode('eyJhbGciOiJIUzI1NiJ9.eyJzdGF0dXMiOiJva2F5In0.tXdQmMPi25VOJZaOySFS-hM2ofIxbyFBVTA7I-GI_lU');

## encode

    encode(HashRef $data) : Str

The encode method encodes the data provided.

- encode example #1

        # given: synopsis

        $encoder->encode({ status => 'okay' });

# AUTHOR

Al Newkirk, `awncorp@cpan.org`

# LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the ["license
file"](https://github.com/iamalnewkirk/zing-encoder-jwt/blob/master/LICENSE).

# PROJECT

[Wiki](https://github.com/iamalnewkirk/zing-encoder-jwt/wiki)

[Project](https://github.com/iamalnewkirk/zing-encoder-jwt)

[Initiatives](https://github.com/iamalnewkirk/zing-encoder-jwt/projects)

[Milestones](https://github.com/iamalnewkirk/zing-encoder-jwt/milestones)

[Contributing](https://github.com/iamalnewkirk/zing-encoder-jwt/blob/master/CONTRIBUTE.md)

[Issues](https://github.com/iamalnewkirk/zing-encoder-jwt/issues)
