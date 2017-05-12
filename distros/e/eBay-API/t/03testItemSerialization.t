#!/usr/bin/perl

################################################################################
# File: .................. 03testItemSerialization.t
# Location: .............. <user_defined_location>/eBay-API/t
# Original Author: ....... Milenko Milanovic
# Last Modified By: ...... Jeff Nokes
# Last Modified: ......... 07/13/2006 @ 12:10
#
# Description:
# Simple test installation script that will attempt to perform object
# serializtion, deserialization on two instances, and compare their structures.
#
# Notes:
# (1)  Before `make install' is performed this script should be runnable
#      with `make test'. After `make install' it should work as
#      `perl 03testItemSerialization.t'
#
################################################################################





BEGIN {


# Debug use only
#diag("03.begin - \$::REQUIRED_MODS = $::REQUIRED_MODS");


# Required Includes
# ------------------------------------------------------------------------------
  use strict;
  use warnings;
  use Test::More tests => 9;      # 9 distinct tests.



  SKIP: {

    # Check for the existence of any dependencies on other modules/classes.
      eval {
         require Data::Dumper;
         require eBay::API;
         require eBay::API::XML::DataType::ItemType;
         require eBay::API::XML::DataType::ShippingServiceOptionsType;
         require eBay::API::XML::DataType::AmountType;
         require eBay::API::XML::DataType::Enum::CountryCodeType;
         require eBay::API::XML::DataType::Enum::CurrencyCodeType;
         require eBay::API::XML::DataType::Enum::ShippingServiceCodeType;
         require eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType;
         require eBay::API::XML::DataType::Enum::ListingDurationCodeType;
      };

      # If there was an error given by the eval above, then the user must have
      # skipped the auto-generation phase, or there is some other module
      # dependency that is breaking things, thus we should skip this test.
        if ($@) {
           skip(
              "SKIP 1:  Most likely dependency on another module not found:  [ $@ ]\n\n",
              8
           );
        }# end if
        else {
           $::REQUIRED_MODS=1;
        }


    # If we got this far, we must be OK to do the test, test required includes.
      use Data::Dumper;

    # Tests 1-8
      use_ok('eBay::API::XML::DataType::ItemType');
      use_ok('eBay::API::XML::DataType::ShippingServiceOptionsType');
      use_ok('eBay::API::XML::DataType::AmountType');
      use_ok('eBay::API::XML::DataType::Enum::CountryCodeType');
      use_ok('eBay::API::XML::DataType::Enum::CurrencyCodeType');
      use_ok('eBay::API::XML::DataType::Enum::ShippingServiceCodeType');
      use_ok('eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType');
      use_ok('eBay::API::XML::DataType::Enum::ListingDurationCodeType');

  } # end SKIP block

} # end BEGIN block


# Debug use only
#diag("03.middle - \$::REQUIRED_MODS = $::REQUIRED_MODS");


  SKIP: {

    # If there was an error given by the eval above, then the user must have
    # skipped the auto-generation phase, or there is some other module
    # dependency that is breaking things, thus we should skip this test.
      if (!$::REQUIRED_MODS) {
         skip(
            "SKIP 2:  Requred modules were not found to run the next test, skipping.\n\n",
            1
         );
      }# end if

    # Local Variables
      my $pItem;
      my $xml;
      my $pNewItem;



    # Test 9 - Compare the two Item object data structures.

      # Get an Item object, with properties set.
        $pItem = getItem();

      # Serialize the Item object.
        $xml = $pItem->serialize('item');

      # Deserialize the Item object.
        $pItem->deserialize('sRawXmlString' => $xml);

      # Instantiate a new item object manually.
        $pNewItem = eBay::API::XML::DataType::ItemType->new();

      # Deserialize the first Item object XML, into the new Item object.
        $pNewItem->deserialize('sRawXmlString' => $xml);

      # Test 9 - Compare the two Item object data structures.
        is_deeply($pItem, $pNewItem, 'item serialization/deserilization');


  }# end SKIP block


# Debug use only
#diag("03.end - \$::REQUIRED_MODS = $::REQUIRED_MODS");





# Subroutine Definitions
# ------------------------------------------------------------------------------

# getItem
#
# Description:  Simple subroutine to instantiate an ItemType object, and
#               set some of the properties.
#
# Arguments:    None
#
# Returns:      upon success:  Object of type Item
#               upon failure:  Can't really get this

sub getItem {

    my $pItem = eBay::API::XML::DataType::ItemType->new();

    my $pItemID = eBay::API::XML::DataType::ItemIDType->new();
    $pItemID->setValue(1000000);

    my $pBuyItNowPrice = eBay::API::XML::DataType::AmountType->new();
    $pBuyItNowPrice->setValue(99.0);

    $pItem->setBuyItNowPrice($pBuyItNowPrice);
    $pItem->setCountry(eBay::API::XML::DataType::Enum::CountryCodeType::US);
    $pItem->setCurrency(eBay::API::XML::DataType::Enum::CurrencyCodeType::USD);
    $pItem->setDescription('NewSchema item description.');
    $pItem->setListingDuration(
                eBay::API::XML::DataType::Enum::ListingDurationCodeType::Days_7
            );
    $pItem->setLocation('San Jose, CA');

    my @inPaymentMethods = (
          eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType::PaymentSeeDescription,
          eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType::MOCC,
          eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType::COD,
       );

    $pItem->setPaymentMethods(@inPaymentMethods);

    my $pPrimaryCategory = eBay::API::XML::DataType::CategoryType->new();
    $pPrimaryCategory->setCategoryID(357);

    $pItem->setPrimaryCategory($pPrimaryCategory);

    my $pShippingDetailsType = getShippingDetailsType();
    $pItem->setShippingDetails($pShippingDetailsType);

    return $pItem;

}# end getItem()





# getItem
#
# Description:  Simple subroutine to instantiate an ShippingDetailsType object, and
#               set some of the properties.
#
# Arguments:    None
#
# Returns:      upon success:  Object of ShippingDetailsType
#               upon failure:  Can't really get this

sub getShippingDetailsType{

   my $ShippingDetailsType = eBay::API::XML::DataType::ShippingDetailsType->new();

   # set shipping service options
     my @aShippingServiceOptions = ();
     my $pShippingServiceOptionsType = undef;

   # shipping service 3
     $pShippingServiceOptionsType = eBay::API::XML::DataType::ShippingServiceOptionsType->new();
     $pShippingServiceOptionsType->setShippingServicePriority(1);
     $pShippingServiceOptionsType->setShippingService(
        eBay::API::XML::DataType::Enum::ShippingServiceCodeType::USPSParcel
     );
     $pShippingServiceOptionsType->setShippingServiceCost(10);

   push @aShippingServiceOptions, $pShippingServiceOptionsType;
   
   $ShippingDetailsType->setShippingServiceOptions(@aShippingServiceOptions);

   return $ShippingDetailsType;

}# end getShippingDetailsType()
