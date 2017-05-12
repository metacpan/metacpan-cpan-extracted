#! /usr/bin/perl

use strict;
use warnings;

use WebService::Dwolla; # Include Dwolla REST API Client
use Data::Dumper;       # Include this to help with debugging.

# Instantiate new client.
my $api = WebService::Dwolla->new(); 

# Set key, secret, and OAuth token from config file.
$api->set_api_config_from_file('/usr/local/etc/dwolla_api.conf');

# Example 1: Get balance for user with the asscociated OAuth token.

my $balance = $api->balance();
my $errors  = $api->get_errors();

# Because the balance can be zero and return value can be zero due to failure
# we must check the error array as well.

if (!$balance && scalar(@{$errors}) > 0) {
    print Dumper($errors);
} else {
    print $balance . "\n";
}
