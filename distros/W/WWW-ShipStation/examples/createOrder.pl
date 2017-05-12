#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use WWW::ShipStation;
use Data::Dumper;

die "Please set ENV SHIPSTATION_USER and SHIPSTATION_PASS"
    unless $ENV{SHIPSTATION_USER} and $ENV{SHIPSTATION_PASS};

my $ws = WWW::ShipStation->new(
    user => $ENV{SHIPSTATION_USER},
    pass => $ENV{SHIPSTATION_PASS}
);
my $order = $ws->createOrder({
  "orderNumber" => "TEST-ORDER-API-DOCS-" . $$,
  "orderKey" => "TEST-ORDER-API-DOCS-" . $$,
  "orderDate" => "2015-06-29T08:46:27.0000000",
  "paymentDate" => "2015-06-29T08:46:27.0000000",
  "orderStatus" => "awaiting_shipment",
  "customerUsername" => 'headhoncho@whitehouse.gov',
  "customerEmail" => 'headhoncho@whitehouse.gov',
  "billTo" => {
    "name" => "The President",
    "company" => undef,
    "street1" => undef,
    "street2" => undef,
    "street3" => undef,
    "city" => undef,
    "state" => undef,
    "postalCode" => undef,
    "country" => undef,
    "phone" => undef,
    "residential" => undef
  },
  "shipTo" => {
    "name" => "The President",
    "company" => "US Govt",
    "street1" => "1600 Pennsylvania Ave",
    "street2" => "Oval Office",
    "street3" => undef,
    "city" => "Washington",
    "state" => "DC",
    "postalCode" => "20500",
    "country" => "US",
    "phone" => "555-555-5555",
    "residential" => 1
  },
  "items" => [
    {
      "lineItemKey" => "vd08-MSLbtx",
      "sku" => "ABC123",
      "name" => "Test item #1",
      "imageUrl" => undef,
      "weight" => {
        "value" => 24,
        "units" => "ounces"
      },
      "quantity" => 2,
      "unitPrice" => 99.99,
      "warehouseLocation" => "Aisle 1, Bin 7",
      "options" => [
        {
          "name" => "Size",
          "value" => "Large"
        }
      ],
      "adjustment" => 0
    },
    {
      "lineItemKey" => undef,
      "sku" => "DISCOUNT CODE",
      "name" => "10% OFF",
      "imageUrl" => undef,
      "weight" => {
        "value" => 0,
        "units" => "ounces"
      },
      "quantity" => 1,
      "unitPrice" => -20.55,
      "warehouseLocation" => undef,
      "options" => [],
      "adjustment" => 1
    }
  ],
  "amountPaid" => 218.73,
  "taxAmount" => 5,
  "shippingAmount" => 10,
  "customerNotes" => "Thanks for ordering!",
  "internalNotes" => "Customer called and would like to upgrade shipping",
  "gift" => 1,
  "giftMessage" => "Thank you!",
  "paymentMethod" => "Credit Card",
  "requestedShippingService" => "Priority Mail",
  "carrierCode" => "fedex",
  "serviceCode" => "fedex_2day",
  "packageCode" => "package",
  "confirmation" => "delivery",
  "shipDate" => "2015-07-02",
  "weight" => {
    "value" => 25,
    "units" => "ounces"
  },
  "dimensions" => {
    "units" => "inches",
    "length" => 7,
    "width" => 5,
    "height" => 6
  },
  "insuranceOptions" => {
    "provider" => "carrier",
    "insureShipment" => 1,
    "insuredValue" => 200
  },
  "internationalOptions" => {
    "contents" => undef,
        "customsItems" => undef
  },
  "advancedOptions" => {
    "warehouseId" => 0,
    "nonMachinable" => 0,
    "saturdayDelivery" => 0,
    "containsAlcohol" => 0,
    "storeId" => 0,
    "customField1" => "Custom data",
    "customField2" => "Per UI settings, this information",
    "customField3" => "can appear on some carrier's shipping labels",
    "source" => "Webstore"
  }
});
print Dumper(\$order);

1;