#! /usr/bin/perl -w
use strict;
use warnings;

use Test::More qw (no_plan);
use Data::Dumper;

use eBay::API::XML::Session;
use eBay::API::XML::Call::GeteBayOfficialTime;

print "testSessionErrors.t \n";
my $api = eBay::API::XML::Session->new();

my $call = new eBay::API::XML::Call::GeteBayOfficialTime;
$api->addRequest($call);
my $call2 = new eBay::API::XML::Call::GeteBayOfficialTime;
$call2->setApiUrl("http:://www.ebay.comx");
$call2->setUserName('rlbunau');
$call2->setUserPassword('password');
$api->addRequest($call2);
$api->setSequentialExecution(1);
my $results = $api->execute();

is($call->getResponseAck(), 'Success', 'First call succeeds.');
ok(! $call2->getResponseAck(), 'Second call fails.');
ok($call2->hasErrors, 'Second call has errors registered.');
ok($api->getError(), 'Session has error recorded.');
print "\n" . $call2->getErrors()->[0]->getShortMessage() . "\n";
