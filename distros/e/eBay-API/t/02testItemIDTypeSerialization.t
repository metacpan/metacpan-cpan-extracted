#!/usr/bin/perl

################################################################################
# File: .................. 01testItemIDTypeSerialization.t
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
#      `perl 01testItemIDTypeSerialization.t'
#
################################################################################





BEGIN {


# Debug use only
#diag("02.begin - \$::REQUIRED_MODS = $::REQUIRED_MODS");


# Required Includes
# ------------------------------------------------------------------------------
  use strict;
  use warnings;
  use Test::More tests => 3;      # 3 distinct tests.



  SKIP: {

    # Check for the existence of any dependencies on other modules/classes.
      eval {
         require Data::Dumper;
         require eBay::API::XML::DataType::ItemType
      };

      # If there was an error given by the eval above, then the user must have
      # skipped the auto-generation phase, or there is some other module
      # dependency that is breaking things, thus we should skip this test.
        if ($@) {
           skip(
              "SKIP 1:  Most likely dependency on another module not found:  [ $@ ]\n\n",
              1
           );
        }# end if
        else {
           $::REQUIRED_MODS=1;
        }

    # If we got this far, we must be OK to do the test.
    # Test required includes.
      use Data::Dumper;
      use_ok('eBay::API::XML::DataType::ItemType');    # Test 1

  } # end SKIP block

} # end BEGIN block


# Debug use only
#diag("02.middle - \$::REQUIRED_MODS = $::REQUIRED_MODS");


  SKIP: {

    # If there was an error given by the eval above, then the user must have
    # skipped the auto-generation phase, or there is some other module
    # dependency that is breaking things, thus we should skip this test.
      if (!$::REQUIRED_MODS) {
         skip(
            "SKIP 2:  Requred modules were not found to run the next test, skipping.\n\n",
            2
         );
      }# end if


    # Local Variables
      my $pItem;
      my $xml;
      my $pNewItem;
      my $pItemID;



    # Test 2 - Serialize Without Shortcut

      # Instantiate an ItemType object.
        $pItem = eBay::API::XML::DataType::ItemType->new();

      # Set the item id property the __LONG__ way.
        $pItem->getItemID()->setValue(1000000);

      # Serialize the object into a blob of XML.
        $xml = $pItem->serialize('item');

      # Deserialize what we just serialized.
        $pItem->deserialize('sRawXmlString' => $xml);

      # Instantiate a new ItemType object.
        $pNewItem = eBay::API::XML::DataType::ItemType->new();

      # Deserialize the the first objects serialized XML, into this new object.
        $pNewItem->deserialize('sRawXmlString' => $xml);

      # Test 2 - Compare the two ItemIDType object structures.
        is_deeply($pItem, $pNewItem, 'ItemIDType serialization/deserilization - no shortcut');



    # Test 3 - Serialize With Shortcut

      # Instantiate an ItemType object.
        $pItem = eBay::API::XML::DataType::ItemType->new();

      # Set the item id property the __SHORT__ way.
        $pItem->setItemID(1000000);

      # Serialize the object into a blob of XML.
        $xml = $pItem->serialize('item');

      # Deserialize what we just serialized.
        $pItem->deserialize('sRawXmlString' => $xml);

      # Instantiate a new ItemType object.
        $pNewItem = eBay::API::XML::DataType::ItemType->new();

      # Deserialize the the first objects serialized XML, into this new object.
        $pNewItem->deserialize('sRawXmlString' => $xml);

      # Test 3 - Compare the two ItemIDType object structures.
        is_deeply($pItem, $pNewItem, 'ItemIDType serialization/deserilization - with shortcut');


  }# end SKIP block


# Debug use only
#diag("02.end - \$::REQUIRED_MODS = $::REQUIRED_MODS");
