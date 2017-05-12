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

# Example 1: Retrieve a list of pending money requests.

my $requests = $api->requests();

if (!$requests) {
    print Dumper($api->get_errors());
} else {
    print Dumper($requests);
}

# Example 2: Send a money request.

my $request_id = $api->request('812-713-9234','1.00');

if (!$request_id) {
    print Dumper($api->get_errors());
} else {
    print "Request id: $request_id\n";
}

sleep(4);

# Example 3: Send request info given an Id..

my $req = $api->request_by_id($request_id);

if (!$req) {
    print Dumper($api->get_errors());
} else {
    print Dumper($req);
}

sleep(4);

# Example 4: Cancel a money request.
my $requests2 = $api->cancel_request($request_id);

if (!$requests2) {
    print Dumper($api->get_errors());
} else {
    print Dumper($requests2);
}

# Example 5: Fulfill a money request.
my $pin = '0000';
my $requests3 = $api->fulfill_request($request_id,$pin);

if (!$requests3) {
    print Dumper($api->get_errors());
} else {
    print Dumper($requests3);
}
