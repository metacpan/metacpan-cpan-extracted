#! /usr/bin/perl

use strict;
use warnings;

use WebService::Dwolla; # Include Dwolla REST API Client
use Data::Dumper;       # Include this to help with debugging.

# Instantiate new client.
my $api = WebService::Dwolla->new(); 

# Set key, secret, and OAuth token from config file.
$api->set_api_config_from_file('/usr/local/etc/dwolla_api.conf');

# Example 1: Get user info for the asscociated OAuth token.

my $me = $api->me();
if (!$me) {
    print Dumper($api->get_errors());
} else {
    print Dumper($me);
}

# Example 2: Get account information for an account given a Dwolla Id.

my $acct1 = $api->get_user('812-546-3855');
if (!$acct1) {
    print Dumper($api->get_errors());
} else {
    print Dumper($acct1);
}

# Example 3: Get account information for an account given an email.
# NOTE: Got this from PHP API exmaples, but it doesn't seem to be implemented.

my $acct2 = $api->get_user('michael@dwolla.com');
if (!$acct2) {
    print Dumper($api->get_errors());
} else {
    print Dumper($acct2);
}

# Example 4: Get users nearby a given geolocation.

my $lat  = "40.708322";
my $long = "-74.0147477";

my $nearby = $api->users_nearby($lat,$long);
if (!$nearby) {
    print Dumper($api->get_errors());
} else {
    print Dumper($nearby);
}
