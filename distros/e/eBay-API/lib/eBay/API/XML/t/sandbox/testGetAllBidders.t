#! /usr/bin/perl -w
use strict;
use warnings;
use Test::More qw (no_plan);
use Data::Dumper;

print "Test GetAllBidders call.\n";
use_ok('eBay::API::XML::Call::GetAllBidders');
use eBay::API::XML::DataType::Enum::GetAllBiddersModeCodeType;
my $call = new eBay::API::XML::Call::GetAllBidders;
$call->setItemID(4100711938);
my $typecode = eBay::API::XML::DataType::Enum::GetAllBiddersModeCodeType::ViewAll;
$call->setCallMode($typecode);
#print "request: " . $call->getRequestRawXml() . "\n";
$call->execute();

#print $call->getResponseRawXml() . "\n";
is($call->getResponseAck(), 'Success', 'Successful response received.');
my @bidarray = @{$call->getBidArray()->getOffer()};
my $i = 0;
foreach (@bidarray) {
$i++;
#  print Dumper($_);
  print $_->getSiteCurrency() . "\n";
  print $_->getUser()->getUserID() . "\n";
  print $_->getUser()->getRegistrationDate() . "\n";
}
ok($i>0, 'Item has bids.');
