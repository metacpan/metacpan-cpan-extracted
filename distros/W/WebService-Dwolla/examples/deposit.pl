#! /usr/bin/perl

use strict;
use warnings;

use WebService::Dwolla;
use Data::Dumper;

my $api = WebService::Dwolla->new(); 

# Set key, secret, and OAuth token from config file.
$api->set_api_config_from_file('/usr/local/etc/dwolla_api.conf');

# Example 1: Deposit money from a funding source into Dwolla account.

my $source_id = 'a4946ae2d2b7f1f880790f31a36887f5';
my $pin       = '1234';
my $amount    = '1.00';

my $deposit = $api->deposit($source_id,$pin,$amount);
if (!$deposit) {
    print Dumper($api->get_errors());
} else {
    print Dumper($deposit);
}
