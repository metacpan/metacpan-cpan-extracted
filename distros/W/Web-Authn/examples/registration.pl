#!/usr/bin/env perl
use strict;
use warnings;
use Web::Authn qw(
    generate_registration_options
    generate_authentication_options
    options_to_json
);

my $reg = generate_registration_options(
    rp_id               => 'example.com',
    rp_name             => 'Example Co',
    user_name           => 'bob',
    user_display_name   => 'Bob',
    attestation         => 'none',
    authenticator_selection => {
        resident_key      => 'preferred',
        user_verification => 'preferred',
    },
);
print "=== registration options ===\n", options_to_json($reg), "\n\n";

my $auth = generate_authentication_options(
    rp_id             => 'example.com',
    user_verification => 'preferred',
);
print "=== authentication options ===\n", options_to_json($auth), "\n";
