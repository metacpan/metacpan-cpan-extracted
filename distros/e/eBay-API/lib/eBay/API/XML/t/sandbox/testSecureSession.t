#! /usr/bin/perl -w
use strict;
use warnings;

use Test::More qw (no_plan);
use Data::Dumper;

use_ok('eBay::API::XML::Session');
my $api = new eBay::API::XML::Session;
use_ok('eBay::API::XML::Call::GeteBayOfficialTime');
my $call = new eBay::API::XML::Call::GeteBayOfficialTime;
$api->addRequest($call);
my $results = $api->execute();

print Dumper($call->getResponseRawXml());
