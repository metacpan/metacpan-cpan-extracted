#! /usr/bin/perl -w
use strict;
use warnings;
use Test::More qw (no_plan);
use Data::Dumper;

use Scalar::Util 'blessed';

print "Test GetItem call.\n";
use_ok('eBay::API::XML::Call::GeteBayDetails');

use eBay::API::XML::DataType::Enum::AckCodeType;
use eBay::API::XML::DataType::Enum::DetailNameCodeType;

my $sItemId = 4076537994;
my $sSiteId = 203;

my $pCall = eBay::API::XML::Call::GeteBayDetails->new();

    # 1. set site id
$pCall->setSiteID($sSiteId);

    # 2. retrieve only specified detail information.
my @aDetailNames = (
        eBay::API::XML::DataType::Enum::DetailNameCodeType::ShippingServiceDetails
                   );
$pCall->setDetailName(\@aDetailNames);


    # 4. execute the call
$pCall->execute();

is($pCall->getResponseAck(), 'Success', 'Successful response received.');
#print $pCall->getResponseRawXml();

my $raShippingServiceDetailsType = $pCall->getShippingServiceDetails();
my $sExpectedNumShippingServicesIndia = 10;
ok ( $sExpectedNumShippingServicesIndia == 
        (scalar @$raShippingServiceDetailsType), 'number of shipping services in India' );
#print Dumper( $raShippingServiceDetailsType);

