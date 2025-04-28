#!/usr/bin/perl
use lib qw(../lib);
use strict;
use warnings;
use Benchmark qw(cmpthese);
use MIME::Base64;
use MIME::Base64::Perl;
use gb64 qw(enc_b64 dec_b64);  # Jouw geoptimaliseerde versie

# Testdata
my $small = "Hello";
my $medium = "Hello World" x 100;
my $large = "Hello World" x 10000;
my $enc_small = enc_b64($small);
my $enc_medium = enc_b64($medium);
my $enc_large = enc_b64($large);

print "Encode Benchmark gb64 verses MIME::Base64 verses MIME::Base64::Perl\n";
# Benchmark encoderen
cmpthese(-5, {
    'gb64_enc_small' => sub { enc_b64($small) },
    'gb64_enc_medium' => sub { enc_b64($medium) },
    'gb64_enc_large' => sub { enc_b64($large) },
    'mime_enc_small' => sub { MIME::Base64::encode_base64($small, '') },
    'mime_enc_medium' => sub { MIME::Base64::encode_base64($medium, '') },
    'mime_enc_large' => sub { MIME::Base64::encode_base64($large, '') },
    'perl_enc_small' => sub { MIME::Base64::Perl::encode_base64($small, '') },
    'perl_enc_medium' => sub { MIME::Base64::Perl::encode_base64($medium, '') },
    'perl_enc_large' => sub { MIME::Base64::Perl::encode_base64($large, '') },
});

print "Decode Benchmark gb64 verses MIME::Base64 verses MIME::Base64::Perl\n";
cmpthese(-5, {
    'gb64_dec_small' => sub { dec_b64($enc_small) },
    'gb64_dec_medium' => sub { dec_b64($enc_medium) },
    'gb64_dec_large' => sub { dec_b64($enc_large) },
    'mime_dec_small' => sub { MIME::Base64::decode_base64($enc_small) },
    'mime_dec_medium' => sub { MIME::Base64::decode_base64($enc_medium) },
    'mime_dec_large' => sub { MIME::Base64::decode_base64($enc_large) },
    'perl_dec_small' => sub { MIME::Base64::Perl::decode_base64($enc_small) },
    'perl_dec_medium' => sub { MIME::Base64::Perl::decode_base64($enc_medium) },
    'perl_dec_large' => sub { MIME::Base64::Perl::decode_base64($enc_large) },
});

