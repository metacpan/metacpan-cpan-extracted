#! /usr/bin/perl -w
use strict;
use warnings;

use Test::More qw (no_plan);
use Data::Dumper;

use eBay::API::XML::Session;
use eBay::API::XML::Call::GeteBayOfficialTime;
use_ok('eBay::CallRetry');

my $api = eBay::API::XML::Session->new();
my $testretry = eBay::CallRetry::createTestCallRetry();
$api->setCallRetry($testretry);
my $call = new eBay::API::XML::Call::GeteBayOfficialTime;
$call->setApiUrl('http://www.ebay.comx/');
$api->addRequest($call);
my $call2 = new eBay::API::XML::Call::GeteBayOfficialTime;
$api->addRequest($call2);
my $results = $api->execute();

my $i = 0;
my $success = 0;
my $failed = 0;
foreach   (@$results) {
  if (defined $_->getResponseAck() &&   $_->getResponseAck() eq 'Success') {
    $success = 1;
  } else {
    $failed = 1;
  }
    
  $i++;
}
is($i, 2, "Two calls returned.");
is($success, 1, "Expect one success.");
is($failed, 1, "Expect one failed.");
