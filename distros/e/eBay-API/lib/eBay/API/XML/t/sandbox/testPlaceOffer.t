#! /usr/bin/perl -w
use strict;
use warnings;
use Test::More qw (no_plan);
use Data::Dumper;

print "Test PlaceOffer call.\n";
use_ok('eBay::API::XML::Call::PlaceOffer');
use_ok('eBay::API::XML::DataType::ItemIDType');
use_ok('eBay::API::XML::DataType::AmountType');
use_ok('eBay::API::XML::DataType::OfferType');

use eBay::API::XML::DataType::Enum::BidActionCodeType;

my $sItemId = 4015192117;
my $sAPIMaxBid = 11.00;
my $isBin = 0;

    # 1. instantiate PlaceOffer call
my $pCallPlaceOffer = eBay::API::XML::Call::PlaceOffer->new();
$pCallPlaceOffer->getSiteID(216);

	# 2. set itemId
my $pItemIDType = eBay::API::XML::DataType::ItemIDType->new();
$pItemIDType->setValue($sItemId);
$pCallPlaceOffer->setItemID($pItemIDType);

    # 3. set offer
my $pOfferType = eBay::API::XML::DataType::OfferType->new();

    # 3.1. set quantity
$pOfferType->setQuantity(1);

    # 3.2. set bid amount
my $pMaxBid = eBay::API::XML::DataType::AmountType->new();
$pMaxBid->setValue($sAPIMaxBid);
$pOfferType->setMaxBid($pMaxBid);

    # 3.3. set  offer type
    
my $sActionType =  $isBin ? 
                eBay::API::XML::DataType::Enum::BidActionCodeType::Purchase
              : eBay::API::XML::DataType::Enum::BidActionCodeType::Bid ;
$pOfferType->setAction($sActionType);

    # 3.4. finally set the offer
$pCallPlaceOffer->setOffer($pOfferType);

$pCallPlaceOffer->setUserName('sgtest3');
$pCallPlaceOffer->setUserPassword('Password123');
    
$pCallPlaceOffer->execute();
#my $sAck = $pCallPlaceOffer->getResponseAck();
#isnt( $sAck, eBay::API::XML::DataType::Enum::AckCodeType::Success
#            , 'Call failed - which was expected!');

my $raErrors = $pCallPlaceOffer->getErrorsAndWarnings();
#print Dumper($raErrors);

my $sResponseRawXml = $pCallPlaceOffer->getResponseRawXml();

my $sSiteID = $pCallPlaceOffer->getSiteID();
print "sSiteID=|$sSiteID|\n";

print Dumper( $pCallPlaceOffer->getErrorsAndWarnings() );

