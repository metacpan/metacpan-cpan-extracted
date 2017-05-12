#! /usr/bin/perl

use strict;
use warnings;

use WebService::Dwolla; # Include Dwolla REST API Client
use Data::Dumper;       # Include this to help with debugging.

# Instantiate new client.
my $api = WebService::Dwolla->new(); 

# Set key, secret, and OAuth token from config file.
$api->set_api_config_from_file('/usr/local/etc/dwolla_api.conf');
$api->set_debug_mode(1);

# Example 1: Send money.
my $pin = '1234';
my $transaction_id = $api->send($pin,'812-713-9234','1.00','Test from Perl API');

if (!$transaction_id) {
    print Dumper($api->get_errors());
} else {
    print Dumper($transaction_id);
}
