#! /usr/bin/perl

use strict;
use warnings;

use WebService::Dwolla;
use Data::Dumper;

my $api = WebService::Dwolla->new(); 

# Set key, secret, and OAuth token from config file.
$api->set_api_config_from_file('/usr/local/etc/dwolla_api.conf');

# Example 1: Get all funding sources

my $funding_sources = $api->funding_sources();
if (!$funding_sources) {
    print Dumper($api->get_errors());
} else {
    print Dumper($funding_sources);
}

# Example 2: Get by funding source by id.

my $source_id = 'a4946ae2d2b7f1f880790f31a36887f5';

my $fs = $api->funding_source($source_id);
if (!$fs) {
    print Dumper($api->get_errors());
} else {
    print Dumper($fs);
}

# Example 3: Add a funding source.

my $acctnum = '123456';
my $trnnum  = '123456789';
my $type    = 'Checking';
my $name    = 'My Checking';

my $add = $api->add_funding_source($acctnum,$trnnum,$type,$name);
if (!$add) {
    print Dumper($api->get_errors());
} else {
    print Dumper($add);
}

# Example 4: Verify a funding source.

my $d1 = '0.01';
my $d2 = '0.02';
my $id = 'a4946ae2d2b7f1f880790f31a36887f5';

my $verify = $api->verify_funding_source($id,$d1,$d2);
if (!$verify) {
    print Dumper($api->get_errors());
} else {
    print Dumper($verify);
}

