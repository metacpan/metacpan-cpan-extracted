#! /usr/bin/perl -w
use strict;
use warnings;

use Test::More qw (no_plan);
use Data::Dumper;

use eBay::API::XML::Session;
use eBay::API::XML::Call::GeteBayOfficialTime;

my $api = eBay::API::XML::Session->new();

my $call = new eBay::API::XML::Call::GeteBayOfficialTime;
$api->addRequest($call);
my $call2 = new eBay::API::XML::Call::GeteBayOfficialTime;
$call2->setUserName('rlbunau');
$call2->setUserPassword('password');
$api->addRequest($call2);
$api->setSequentialExecution(1);
my $results = $api->execute();

my $i = 0;
foreach   (@$results) {
  #print $_->getResponseRawXml() . "\n";
  #print Dumper($_);
  is($_->getResponseAck(), 'Success', 'Successful response received.');
  $i++;
}
is($i, 2, "Got both requests back.");
