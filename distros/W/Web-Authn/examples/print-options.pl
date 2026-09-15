#!/usr/bin/env perl
use strict;
use warnings;
use Web::Authn;

# Prints the JSON a browser would receive from /register/begin and /login/begin.
# No server, no database — useful to inspect the shape of the options.

my $rp_id   = $ENV{WEBAUTHN_RP_ID}   || 'localhost';
my $rp_name = $ENV{WEBAUTHN_RP_NAME} || 'Cookbook Example';
my $email   = $ENV{WEBAUTHN_USER}    || 'bob@example.com';

my $authn = Web::Authn->new(
    rp_id           => $rp_id,
    rp_name         => $rp_name,
    expected_origin => $ENV{WEBAUTHN_ORIGIN} || 'http://localhost:5000',
);

my $handle = $authn->generate_user_handle;

my $reg = $authn->generate_registration_options(
    user_name           => $email,
    user_id             => $handle,
    user_display_name   => 'Bob',
    attestation         => 'none',
    authenticator_selection => {
        resident_key      => 'preferred',
        user_verification => 'preferred',
    },
) or die( $authn->error );

print "=== user.handle (base64url) ===\n", $authn->bytes_to_base64url( $handle ), "\n\n";
print "=== POST /webauthn/register/begin ===\n", $authn->options_to_json( $reg ), "\n\n";

my $auth = $authn->generate_authentication_options(
    user_verification => 'preferred',
) or die( $authn->error );
print "=== POST /webauthn/login/begin (usernameless) ===\n", $authn->options_to_json( $auth ), "\n";
