#! /usr/bin/perl -w

use strict;
use warnings;

use Test::More qw (no_plan);
use Data::Dumper;

print "Test GetMyeBaySelling call\n";
use_ok('eBay::API::XML::Call::GetMyeBaySelling');
use_ok('eBay::API::XML::DataType::Enum::DetailLevelCodeType');
use eBay::API::XML::DataType::Enum::DetailLevelCodeType;
use eBay::API::XML::DataType::Enum::AckCodeType;

my $pCall = eBay::API::XML::Call::GetMyeBaySelling->new();

   # 1. detail level
   
my $raDetailLevel = [
         eBay::API::XML::DataType::Enum::DetailLevelCodeType::ReturnAll
                    ];
$pCall->setDetailLevel( $raDetailLevel );

#print "request: " . $pCall->getRequestRawXml() . "\n";
$pCall->setUserName('sgtest1');
$pCall->setUserPassword('Password123');

$pCall->execute();

my $sStatus = $pCall->getResponseAck();
my $sSuccessCode = eBay::API::XML::DataType::Enum::AckCodeType::Success;
is($sStatus, $sSuccessCode, 'Successful response received.');
#print $pCall->getResponseRawXml() . "\n";

if ($sStatus ne $sSuccessCode) {
	my $raErrors = $pCall->getErrorsAndWarnings();
	print Dumper( $raErrors );
}
