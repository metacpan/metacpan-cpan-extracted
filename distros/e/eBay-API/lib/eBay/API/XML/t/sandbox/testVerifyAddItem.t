#! /usr/bin/perl -s
use strict;
use warnings;

use Test::More qw (no_plan);
use Data::Dumper;


# test VerifyAddIem

use_ok('eBay::API::XML::DataType::ItemType');
use_ok('eBay::API::XML::DataType::CategoryType');
use_ok('eBay::API::XML::Call::VerifyAddItem');

my $pItem = eBay::API::XML::DataType::ItemType->new();
can_ok($pItem, 'setCountry');
can_ok($pItem, 'setCurrency');
can_ok($pItem, 'setDescription');
can_ok($pItem, 'setListingDuration');
can_ok($pItem, 'setLocation');
can_ok($pItem, 'setPaymentMethods');
$pItem->setCountry('US');
$pItem->setCurrency('USD');
$pItem->setDescription('NewSchema item description.');
$pItem->setListingDuration('Days_1');
$pItem->setLocation('San Jose, CA');
$pItem->setPaymentMethods('PaymentSeeDescription');
$pItem->setQuantity(1);
$pItem->setRegionID(0);
$pItem->setStartPrice(1.0);
$pItem->setTitle('NewSchema item title');

my $pCat = eBay::API::XML::DataType::CategoryType->new();
$pCat->setCategoryID(357);
$pItem->setPrimaryCategory($pCat);

my $pCall = eBay::API::XML::Call::VerifyAddItem->new();

$pCall->setItem($pItem);
$pCall->execute();

is($pCall->getResponseAck(), 'Success', 'Successful response received.');

my $fees = $pCall->getResponseDataType()->getFees()->getFee();
ok($fees > 0, "Got fees");
foreach my $fee (@$fees) {
  print $fee->getName() . " " . $fee->getFee()->getValue() . "\n";
}




