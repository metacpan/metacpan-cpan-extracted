#!/usr/bin/perl -w
#
use strict;
use warnings;

#use Test::More tests => 2;
use Test::More 'no_plan';

use XML::Simple ":strict";
use Data::Dumper;

use eBay::API::XML::t::TidyHelper;

use eBay::API::XML::DataType::ItemType;
use eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType;


ok ( test_deser_3_paymentmethods()
	     , 'Scalar array deserilization: array has more than 1 element' );
ok ( test_deser_1_paymentmethod()
	     , 'Scalar array deserilization: array has only 1 element' );
ok ( test_deser_0_paymentmethod()
	     , 'Scalar array deserilization: array has 0 element' );

#
#
#  1.  START: Test scalar array deserilization
#
#     

=head2 test_deser_3_paymentmethods()

=cut

sub test_deser_3_paymentmethods {

  my $raPaymentMethodsOne = [
        eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType::VisaMC
       ,eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType::COD
       ,eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType::CCAccepted
 			 ]; 

  _test_scalar_array_deserilization ( $raPaymentMethodsOne
	               , 'deserilization - 3 payment methods' );
}

=head2 test_deser_1_paymentmethod()

=cut

sub test_deser_1_paymentmethod {

  my $raPaymentMethodsOne = [
        eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType::VisaMC
 			 ]; 

   _test_scalar_array_deserilization ( $raPaymentMethodsOne
	                          , 'deserilization - 1 payment method');
}

=head2 test_deser_0_paymentmethod()

This test tests whether getters that return a ref to an array always
return a defined reference even if there are no elements in the array.

The test will fail if after deserilization getter that retrieves a ref to an
array, returns undefined value!!

=cut

sub test_deser_0_paymentmethod {

  my $raPaymentMethodsOne = [];

   _test_scalar_array_deserilization ( $raPaymentMethodsOne
	                          , 'deserilization - 0 payment methods');
}

=head2 _test_scalar_array_deserilization()

=cut

sub _test_scalar_array_deserilization {

  my $raSrcPaymentMethods = shift;
  my $tstName = shift;

  my $pSrcItem = eBay::API::XML::DataType::ItemType->new();

  $pSrcItem->setPaymentMethods($raSrcPaymentMethods);

  my $sTag = 'item';
  my $sXmlStr = $pSrcItem->serialize($sTag);

  $sXmlStr = eBay::API::XML::t::TidyHelper::tidyXml($sXmlStr);
  #print $sXmlStr;

     # Deserilize
  my $pDestItem = eBay::API::XML::DataType::ItemType->new();
  $pDestItem->deserialize('sRawXmlString' => $sXmlStr);
  
  #print Dumper($pDestItem);
  my $raDestPaymentMethods = $pDestItem->getPaymentMethods();

  if ( (scalar @$raSrcPaymentMethods) 
	    == (scalar @$raDestPaymentMethods) ) {
      my $size = scalar @$raSrcPaymentMethods;
      return 1;      
      #print "Test '$tstName' ok, src arr and dest arr have the same size: $size\n";
  } else {
      return 0;
      #print "Test '$tstName' FAILED\n";
  }
  #print "\n";
}

#
#
#   1. END: Test scalar array deserilization
#
#     

#
#
#   2. START: Test Simple type deserilization
#
#     

use eBay::API::XML::DataType::ItemType;
use eBay::API::XML::DataType::AmountType;
use eBay::API::XML::DataType::ItemIDType;


my $gsBuyItNowPriceValue = 99;
my $gsReservePriceValue  =  5;
my $gsItemID             = '246';
my $gsSellerUserID       = 'johndoe';


my $pItem;

$pItem = getItem_full_OO();
ok( testSimpleTypeDeserilization( $pItem )
      , 'SimpleType: full OO test AmountType, UserIDType, and ItemIDType' );

$pItem = getItem_partially_OO();
ok( testSimpleTypeDeserilization( $pItem )
      , 'SimpleType: partial OO test: AmountType, UserIDType, and ItemIDType');


=head2 testSimpleTypeDeserilization()

Simple types have 'value' property. This test contains examples that show
how such properties should be set and retrieved:

 $pItemType->getReservePrice()->getValue();
 $pItemType->getItemID()->getValue();
 $pItemType->getSeller()->getUserID()->getValue();

 The folling code would retrieve just object containing those properties:

 $pItemType->getReservePrice();
 $pItemType->getItemID();
 $pItemType->getSeller()->getUserID();

=cut

sub testSimpleTypeDeserilization {
  
  my $pSrcItemType = shift;

  my $tagName = 'Item';
  my $srcXmlStr = $pSrcItemType->serialize($tagName);

  my $pDestItemType = eBay::API::XML::DataType::ItemType->new();
  $pDestItemType->deserialize(
	  	 'tagName'     => $tagName
		,'sRawXmlString' => $srcXmlStr
              );

  my $destXmlStr = $pDestItemType->serialize($tagName);
  $destXmlStr= eBay::API::XML::t::TidyHelper::tidyXml($destXmlStr);


  my $isOk = 1;

  my $sDestBuyItNowPrice = $pDestItemType->getBuyItNowPrice()->getValue();
  if (  $sDestBuyItNowPrice != $gsBuyItNowPriceValue ) {

     print "sDestBuyItNowPrice=|$sDestBuyItNowPrice| - failed\n";
     i$isOk = 0;
  }

  my $sDestReservePrice = $pDestItemType->getReservePrice()->getValue();
  if (  $sDestReservePrice != $gsReservePriceValue ) {

     print "sDestReservePrice=|$sDestReservePrice| - failed\n";
     i$isOk = 0;
  }

  my $sDestItemID = $pDestItemType->getItemID()->getValue();
  if (  $sDestItemID ne $gsItemID ) {

     print "sDestItemID=|$sDestItemID| - failed\n";
     i$isOk = 0;
  }

  my $sDestSellerUserID = $pDestItemType->getSeller()->getUserID()->getValue();
  if (  $sDestSellerUserID ne $gsSellerUserID ) {

     print "sDestSellerUserID=|$sDestSellerUserID| - failed\n";
     i$isOk = 0;
  }

  return $isOk;
}

=head2 getItem_partially_OO()

Simple types are instantiated and populated in shorthanded form

 # 1. set BuyItNowPrice
   use:
      $pItem->setBuyItNowPrice($gsBuyItNowPriceValue);
   instead of:
      $pItem->getBuyItNowPrice()->setValue($gsBuyItNowPriceValue);   

   
 # 3. set ItemID
   use:      
      $pItem->setItemID( $gsItemID );
   instead of:   
      $pItem->getItemID()->setValue( $gsItemID );


 # 4. set seller's userID
   use:      
      $pItem->getSeller()->setUserID( $gsSellerUserID );
   instead of:    
      $pItem->getSeller()->getUserID()->setValue( $gsSellerUserID );
=cut

sub getItem_partially_OO {

   my $pItem = eBay::API::XML::DataType::ItemType->new();

   $pItem->setBuyItNowPrice($gsBuyItNowPriceValue);

   my $pReservePrice = eBay::API::XML::DataType::AmountType->new();
   $pReservePrice->setCurrencyID(
	              eBay::API::XML::DataType::Enum::CurrencyCodeType::USD);
   $pReservePrice->setValue( $gsReservePriceValue );
   $pItem->setReservePrice($pReservePrice);

   $pItem->setItemID( $gsItemID );

   $pItem->getSeller()->setUserID( $gsSellerUserID );
   
   return $pItem;
}

=head2 getItem_full_OO()

Simple types are instantiated and populated in full OO manner:

      # 1. set BuyItNowPrice
   $pItem->getBuyItNowPrice()->setValue($gsBuyItNowPriceValue);

      # 2. set ReservePrice (both value and currency)
   my $pReservePrice = eBay::API::XML::DataType::AmountType->new();
   $pReservePrice->setCurrencyID(
	              eBay::API::XML::DataType::Enum::CurrencyCodeType::USD);
   $pReservePrice->setValue($gsReservePriceValue);
   $pItem->setReservePrice($pReservePrice);

      # 3. set ItemID (both value and currency)
   $pItem->getItemID()->setValue( $gsItemID );

      # 4. set seller's userID
   $pItem->getSeller()->getUserID()->setValue( $gsSellerUserID );

   In this case SimpleType properties are being accessed the very same way 
   they are being accessed in eBay API Java SDK

=cut

sub getItem_full_OO {

   my $pItem = eBay::API::XML::DataType::ItemType->new();

      # 1. set BuyItNowPrice
   $pItem->getBuyItNowPrice()->setValue($gsBuyItNowPriceValue);

      # 2. set ReservePrice (both value and currency)
   my $pReservePrice = eBay::API::XML::DataType::AmountType->new();
   $pReservePrice->setCurrencyID(
	              eBay::API::XML::DataType::Enum::CurrencyCodeType::USD);
   $pReservePrice->setValue($gsReservePriceValue);
   $pItem->setReservePrice($pReservePrice);

      # 3. set ItemID
   $pItem->getItemID()->setValue( $gsItemID );

      # 4. set seller's userID
   $pItem->getSeller()->getUserID()->setValue( $gsSellerUserID );
   
   return $pItem;
}

#
#
#  2. END: Test Simple type deserilization
#
#     

