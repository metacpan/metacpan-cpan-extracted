#! /usr/bin/perl -w

use strict;
use warnings;

use Test::More qw (no_plan);
use Data::Dumper;

print "Test GetMyeBayBuying call\n";
print "    Do not use GetMyeBay since it is going to be depricated soon!\n";
use_ok('eBay::API::XML::Call::GetMyeBayBuying');
use_ok('eBay::API::XML::DataType::ItemListCustomizationType');
use_ok('eBay::API::XML::DataType::Enum::DetailLevelCodeType');
use eBay::API::XML::DataType::Enum::DetailLevelCodeType;

my $pCall = eBay::API::XML::Call::GetMyeBayBuying->new();


   # 1. detail level
   
my $raDetailLevel = [
         eBay::API::XML::DataType::Enum::DetailLevelCodeType::ReturnAll
                    ];
$pCall->setDetailLevel( $raDetailLevel );


   # 2. watch list
my $pWatchList = eBay::API::XML::DataType::ItemListCustomizationType->new();
$pWatchList->setInclude(1);
$pCall->setWatchList( $pWatchList );   

#print "request: " . $pCall->getRequestRawXml() . "\n";
$pCall->execute();

is($pCall->getResponseAck(), 'Success', 'Successful response received.');
#print $pCall->getResponseRawXml() . "\n";

