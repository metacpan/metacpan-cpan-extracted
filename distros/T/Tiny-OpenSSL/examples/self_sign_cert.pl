#!/usr/bin/env perl -w

# Creates an RSA key and a self signed certificate.

use Smart::Comments;

use Tiny::OpenSSL::Key;
use Tiny::OpenSSL::Subject;
use Tiny::OpenSSL::Certificate;
use Tiny::OpenSSL::CertificateSigningRequest;
use Path::Tiny;

my $key = Tiny::OpenSSL::Key->new( file => path('mykey.key') );
$key->create;

### $key

my $subject = Tiny::OpenSSL::Subject->new(
    commonname          => 'test certificate',
    organizational_unit => 'Example Company',
    organization        => 'Example Department',
    locality            => 'Austin',
    state               => 'TX',
    country             => 'US'
);

### $subject

my $cert = Tiny::OpenSSL::Certificate->new(
    file    => path('mycert.crt'),
    subject => $subject,
    key     => $key
);

### $cert

my $csr = Tiny::OpenSSL::CertificateSigningRequest->new(
    file    => path('mycert.csr'),
    key     => $key,
    subject => $subject
);

### $csr

$csr->create;

$cert->self_sign($csr);
