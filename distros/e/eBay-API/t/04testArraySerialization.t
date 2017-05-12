#!/usr/bin/perl

################################################################################
# File: .................. 04testArraySerialization.t
# Location: .............. <user_defined_location>/eBay-API/t
# Original Author: ....... Milenko Milanovic
# Last Modified By: ...... Jeff Nokes
# Last Modified: ......... 07/13/2006 @ 12:10
#
# Description:
# Simple test installation script that will attempt to perform object
# serializtion, deserialization on array datatype instances, and compare
# their structures.
#
################################################################################





BEGIN {


# Debug use only
#diag("04.begin - \$::REQUIRED_MODS = $::REQUIRED_MODS");


# Required Includes
# ------------------------------------------------------------------------------
  use strict;
  use warnings;
  use Test::More tests => 6;      # 6 distinct tests.



  SKIP: {

    # Check for the existence of any dependencies on other modules/classes.
      eval {
         require Data::Dumper;
         require eBay::API::XML::DataType::ItemType;
         require eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType;
      };

      # If there was an error given by the eval above, then the user must have
      # skipped the auto-generation phase, or there is some other module
      # dependency that is breaking things, thus we should skip this test.
        if ($@) {
           skip(
              "SKIP 1:  Most likely dependency on another module not found:  [ $@ ]\n\n",
              2
           );
        }# end if
        else {
           $::REQUIRED_MODS=1;
        }

    # If we got this far, we must be OK to do the test, test required includes.
      use Data::Dumper;

    # Tests 1-2
      use_ok('eBay::API::XML::DataType::ItemType');
      use_ok('eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType');

  } # end SKIP block

} # end BEGIN block


# Debug use only
#diag("04.middle - \$::REQUIRED_MODS = $::REQUIRED_MODS");


  SKIP: {

    # If there was an error given by the eval above, then the user must have
    # skipped the auto-generation phase, or there is some other module
    # dependency that is breaking things, thus we should skip this test.
      if (!$::REQUIRED_MODS) {
         skip(
            "SKIP 2:  Requred modules were not found to run the next test, skipping.\n\n",
            4
         );
      }# end if


    # Local Variables
      my @outPaymentMethods;
      my $pItem;
      my $xml;
      my $pNewItem;

      my @inPaymentMethods = (
            eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType::PaymentSeeDescription,
            eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType::MOCC,
            eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType::COD,
         );



    # Test when argument is an array.

      # Instantiate an ItemType object.
        $pItem = eBay::API::XML::DataType::ItemType->new();

      # Set some properties with an array type.
        $pItem->setPaymentMethods(@inPaymentMethods);

      # Serialize the object.
        $xml = $pItem->serialize('item');

      # Instantiate a new ItemType object.
        $pNewItem = eBay::API::XML::DataType::ItemType->new();

      # Deserialize the new object with the original objects serialized XML.
        $pNewItem->deserialize('sRawXmlString' => $xml);

      # Get the array type properties from the new object.
        @outPaymentMethods = $pNewItem->getPaymentMethods();

      # Test 3 - Compare the two array type property object structures.
        is_deeply(
           [sort @outPaymentMethods],
           [sort @inPaymentMethods], 
           'argument is an array'
        );



    # Test when argument is a reference to an array.

      # Instanitate an ItemType object.
        $pItem = eBay::API::XML::DataType::ItemType->new();

      # Set some properties with an array reference type.
        $pItem->setPaymentMethods(\@inPaymentMethods);

      # Serialize the object.
        $xml = $pItem->serialize('item');

      # Instantiate a new ItemType object.
        $pNewItem = eBay::API::XML::DataType::ItemType->new();

      # Deserialize the new object with the original objects serialized XML.
        $pNewItem->deserialize('sRawXmlString' => $xml);

      # Get the array type properties from the new object.
        @outPaymentMethods = $pNewItem->getPaymentMethods();

      # Test 4 - Compare the two array type property object structures.
        is_deeply(
           [sort @outPaymentMethods],
           [sort @inPaymentMethods],
           'argument is a reference to an array'
        );



    # Test when argument is a scalar, it has to be converted internaly into an array.

      # Instanitate an ItemType object.
        $pItem = eBay::API::XML::DataType::ItemType->new();

      # Set some scalar properties.
        my $code = eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType::COD;
        $pItem->setPaymentMethods($code);

      # Serialize the object.
        $xml = $pItem->serialize('item');

      # Instantiate a new ItemType object.
        $pNewItem = eBay::API::XML::DataType::ItemType->new();

      # Deserialize the new object with the original objects serialized XML.
        $pNewItem->deserialize('sRawXmlString' => $xml);

      # Get the array type properties from the new object.
        @outPaymentMethods = $pNewItem->getPaymentMethods();

      # Test 5-6:  Make sure the scalar property we set originally is the only
      # property still, and it was retrieved as an array.
        ok( (scalar @outPaymentMethods) == 1, 'one element - count');
        is($outPaymentMethods[0], $code , 'one element - value');


  }# end SKIP block


# Debug use only
#diag("04.end - \$::REQUIRED_MODS = $::REQUIRED_MODS");
