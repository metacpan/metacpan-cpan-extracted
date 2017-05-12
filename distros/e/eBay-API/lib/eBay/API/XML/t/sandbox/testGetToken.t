#! /usr/bin/perl -w
use strict;
use warnings;
use Test::More qw (no_plan);
use Data::Dumper;

print "Test GetToken call.\n";
use_ok('eBay::API::XML::Call::GetToken');
my $call = new eBay::API::XML::Call::GetToken;
#print "request: " . $call->getRequestRawXml() . "\n\n";
$call->execute();
#print $call->getResponseRawXml() . "\n\n";
is($call->getResponseAck(), 'Success', 'Successful response received.');

$call->setUserName('rlbunau');
$call->setUserPassword('password');
#print "request: " . $call->getRequestRawXml() . "\n\n";
$call->execute();
#print $call->getResponseRawXml() . "\n\n";
is($call->getResponseAck(), 'Success', 'Successful response received.');

