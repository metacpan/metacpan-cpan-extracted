# About

Because sometimes I just need an OpenSSL wrapper for Perl that can be fatpacked.

This module is still under development.

# Installation

```
$ cpanm Tiny::OpenSSL
```

# Synopsis

Ensure the `openssl` command is in your `$PATH`.

```
use Tiny::OpenSSL::Key;
use Tiny::OpenSSL::Subject;
use Tiny::OpenSSL::CertificateSigningRequest;

my $key = Tiny::OpenSSL::Key->new(
    file     => 'ca.key',
    password => 'foo',
    bits     => 4096
  );

$key->create;

my $subject = Tiny::OpenSSL::Subject->new(
    commonname          => 'My Certificate',
    organizational_unit => 'Example Company',
    organization        => 'Example Department',
    locality            => 'Austin',
    state               => 'TX',
    country             => 'US'
);

my $csr = Tiny::OpenSSL::CertificateSigningRequest->new(
    file    => 'mycert.csr',
    key     => $key,
    subject => $subject
);

$csr->create;

```


[![Build Status](https://travis-ci.org/jfwilkus/Tiny-OpenSSL.svg)](https://travis-ci.org/jfwilkus/Tiny-OpenSSL)


