#! /usr/bin/perl

use strict;
use warnings;

use WebService::Dwolla; # Include Dwolla REST API Client
use Data::Dumper;     # Include this to help with debugging.

# Instantiate new client.
my $api = WebService::Dwolla->new(); 

# Set key, secret, and OAuth token from config file.
$api->set_api_config_from_file('/usr/local/etc/dwolla_api.conf');
$api->set_debug_mode(1);

# Example 1: Register new user.

my $email        = 'michael_phplibtest@dwolla.com';
my $password     = '0neGre4tP4ss';
my $pin          = '1234';
my $firstName    = 'Michael';
my $lastName     = 'Schonfeld';
my $address      = '902 Broadway Ave';
my $address2     = 'Fl 4';
my $city         = 'New York';
my $state        = 'NY';
my $zip          = '10010';
my $phone        = '8182670931';
my $dateOfBirth  = '08-01-1987';
my $acceptTerms  = 1;
my $type         = 'Personal';
my $organization = undef;
my $ein          = undef;

my $user = $api->register(
    $email,      
    $password,
    $pin,      
    $firstName,
    $lastName,
    $address,
    $address2,
    $city,
    $state,
    $zip,
    $phone,
    $dateOfBirth,
    $acceptTerms,
    $type,
    $organization
);

if (!$user) {
    print Dumper($api->get_errors());
} else {
    print Dumper($user);
}
