#!/usr/bin/perl -w
#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2023 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#########################################################################
use Mojo::Base -strict;
use Test::More;

use WWW::Suffit::RSA;
use WWW::Suffit::JWT;

# HMAC
{
    my $secret = 'mysecret';
    my $payload = {
            foo => 'bar',
            baz => 'qux',
        };
    my $jwt = WWW::Suffit::JWT->new(
            secret 	=> $secret,
            payload => $payload,
        );

    # Encode token
    my $token = $jwt->encode->token;
    ok $token, 'Encodes JWTs (HMAC)' or diag $jwt->error;
    #note $token if $token;
    #note explain $jwt;

    # Decode token
    $jwt = WWW::Suffit::JWT->new(secret => $secret);
    my $decoded_payload = $jwt->decode($token)->payload;
    is_deeply $decoded_payload, $payload, "Decodes JWTs (HMAC)" or diag $jwt->error;
    #note explain $decoded_payload;

    # Wrong hmac secret
    $jwt = WWW::Suffit::JWT->new(secret => "bad");
    $decoded_payload = $jwt->decode($token)->payload;
    is $jwt->error, 'Failed HS validation', "Decodes JWTs (HMAC) with wrong hmac secret" or diag $jwt->error;

    # Empty hmac key
    $jwt = WWW::Suffit::JWT->new(secret => "");
    $decoded_payload = $jwt->decode($token)->payload;
    like $jwt->error, qr/Symmetric\skey\s\(secret\)\snot\sspecified$/,
        "Decodes JWTs (HMAC) with empty hmac secret" or diag $jwt->error;
}

# Generate RSA keys
my $rsa = WWW::Suffit::RSA->new(key_size => 512);
$rsa->keygen;
my $private_key = $rsa->private_key;
my $public_key = $rsa->public_key;
ok(length $private_key // '', 'Private RSA key');
ok(length $public_key // '', 'Public RSA key');

# RSA
{
    my $payload = {
            foo => 'bar',
            baz => 'qux',
        };
    my $jwt = WWW::Suffit::JWT->new(
            private_key => $private_key,
            public_key  => $public_key,
            payload     => $payload,
            algorithm   => 'RS256',
        );

    # Encode token
    my $token = $jwt->encode->token;
    ok $token, 'Encodes JWTs (RSA)' or diag $jwt->error;
    #note $token;
    #note explain $jwt;

    # Decode token
    $jwt = WWW::Suffit::JWT->new(
            public_key => $public_key,
        );
    my $decoded_payload = $jwt->decode($token)->payload;
    is_deeply $decoded_payload, $payload, "Decodes JWTs (RSA)" or diag $jwt->error;
    #note explain $decoded_payload;
}

# Decode (HMAC) with errors
{
    my $secret = 'mysecret';

    # Decode token
    my $jwt = WWW::Suffit::JWT->new(secret => $secret);
    my $decoded_payload = $jwt->decode("Bar")->payload;
    ok $jwt->error, "Incorrect token string" or diag explain $decoded_payload;
}

done_testing;

1;

__END__

prove -lv t/05-jwt.t
