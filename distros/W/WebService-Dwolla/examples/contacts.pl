#! /usr/bin/perl

use strict;
use warnings;

use WebService::Dwolla; # Include Dwolla REST API Client
use Data::Dumper;       # Include this to help with debugging.

# Instantiate new client.
my $api = WebService::Dwolla->new(); 

# Set key, secret, and OAuth token from config file.
$api->set_api_config_from_file('/usr/local/etc/dwolla_api.conf');

# Example 1: Fetch last 10 contacts from the account associated with the
# provided OAuth token.

my $contacts1 = $api->contacts();

if (!$contacts1) {
    print Dumper($api->get_errors());
} else {
    print Dumper($contacts1);
}

# Example 2: Search through the contacts of the account associated with the
# provided OAuth token.

my $contacts2 = $api->contacts('Ben');

if (!$contacts2) {
    print Dumper($api->get_errors());
} else {
    print Dumper($contacts2);
}

# Example 3: Get contacts nearby a given geolocation.

my $lat  = "40.708322";
my $long = "-74.0147477";

my $nearby = $api->nearby_contacts($lat,$long);
if (!$nearby) {
    print Dumper($api->get_errors());
} else {
    print Dumper($nearby);
}
