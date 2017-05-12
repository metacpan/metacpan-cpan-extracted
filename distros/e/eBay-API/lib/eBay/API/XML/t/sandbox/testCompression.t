#! /usr/bin/perl -w
use strict;
use warnings;
use Test::More qw (no_plan);
use Data::Dumper;

print "Test gzip compressed call.\n";
use_ok('eBay::API::XML::Call::GetToken');
my $call = new eBay::API::XML::Call::GetToken;
$call->setCompression(1);
print "request: " . $call->getHttpRequestAsString() . "\n\n";
$call->execute();
print $call->getResponseRawXml() . "\n\n";
is($call->getResponseAck(), 'Success', 'Successful response received.');


