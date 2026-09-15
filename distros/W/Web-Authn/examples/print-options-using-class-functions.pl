#!/usr/bin/env perl
use strict;
use warnings;
use Web::Authn qw(
    generate_registration_options
    generate_authentication_options
    options_to_json
    generate_user_handle
    bytes_to_base64url
);

# Prints the JSON a browser would receive from /register/begin and /login/begin.
# No server, no database — useful to inspect the shape of the options.

my $rp_id   = $ENV{WEBAUTHN_RP_ID}   || 'localhost';
my $rp_name = $ENV{WEBAUTHN_RP_NAME} || 'Cookbook Example';
my $email   = $ENV{WEBAUTHN_USER}    || 'bob@example.com';

my $handle = generate_user_handle();

my $reg = generate_registration_options(
    rp_id               => $rp_id,
    rp_name             => $rp_name,
    user_name           => $email,
    user_id             => $handle,
    user_display_name   => 'Bob',
    attestation         => 'none',
    authenticator_selection => {
        resident_key      => 'preferred',
        user_verification => 'preferred',
    },
);

print "=== user.handle (base64url) ===\n", bytes_to_base64url($handle), "\n\n";
print "=== POST /webauthn/register/begin ===\n", options_to_json($reg), "\n\n";

my $auth = generate_authentication_options(
    rp_id             => $rp_id,
    user_verification => 'preferred',
);
print "=== POST /webauthn/login/begin (usernameless) ===\n", options_to_json($auth), "\n";
