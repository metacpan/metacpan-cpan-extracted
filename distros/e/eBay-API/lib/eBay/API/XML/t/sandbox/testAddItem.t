#! /usr/bin/perl -s
use strict;
use warnings;

use Test::More qw (no_plan);
use Data::Dumper;

# test AddIem

use_ok('eBay::API::XML::DataType::ItemType');
use_ok('eBay::API::XML::DataType::CategoryType');
use_ok('eBay::API::XML::Call::AddItem');

use eBay::API::XML::DataType::Enum::CountryCodeType;
use eBay::API::XML::DataType::Enum::CurrencyCodeType;
use eBay::API::XML::DataType::Enum::ListingDurationCodeType;
use eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType;


my $sCountryCode  = eBay::API::XML::DataType::Enum::CountryCodeType::SG;
my $sCurrencyCode = eBay::API::XML::DataType::Enum::CurrencyCodeType::SGD;
my $sSiteId       = 216;
my $sUserName     = 'sgtest3';
my $sUserPassword = 'Password123';



my $pItem = eBay::API::XML::DataType::ItemType->new();
$pItem->setCountry($sCountryCode);
$pItem->setCurrency($sCurrencyCode);
$pItem->setDescription('NewSchema item description for sg.');
$pItem->setListingDuration(eBay::API::XML::DataType::Enum::ListingDurationCodeType::Days_7);
$pItem->setLocation('San Jose, CA');
$pItem->setPaymentMethods(
				[eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType::PersonalCheck]
						  );
$pItem->setQuantity(1);
$pItem->setRegionID(0);
$pItem->setStartPrice(1.0);
$pItem->setTitle('NewSchema item title for sg');

my $pCat = eBay::API::XML::DataType::CategoryType->new();
$pCat->setCategoryID(3352);   # 3352 - 'Film Cameras & Accessories' - category for sg
$pItem->setPrimaryCategory($pCat);

my $pCall = eBay::API::XML::Call::AddItem->new();

$pCall->setItem($pItem);

$pCall->setSiteID( $sSiteId );
$pCall->setUserName($sUserName);
$pCall->setUserPassword($sUserPassword );

$pCall->execute();

is($pCall->getAck(), 'Success', 'Successful response received.');

my $fees = $pCall->getResponseDataType()->getFees()->getFee();
ok($fees > 0, "Got fees");
foreach my $fee (@$fees) {
  print $fee->getName() . " " . $fee->getFee()->getValue() . "\n";
}

print Dumper( $pCall->getErrorsAndWarnings() );

my $sItemId = $pCall->getItemID()->getValue();
print "sItemId=|$sItemId|\n";
