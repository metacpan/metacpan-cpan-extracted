#!/usr/bin/perl -w
#
use strict;
use warnings;


# perl -ID:/milenko/dev/row/lite_soap/schema/xgen_publish/gen test_ser.pl
#use lib "D:/milenko/dev/row/lite_soap/schema/xgen_publish/gen";
# perl -I/cygdrive/d/ccrowviews/row_to_new_api_00/row/cgi-bin/lib test_ser.pl
use IO::File;
use XML::Simple ":strict";
use XML::Tidy;
#use XML::Simple;
use Data::Dumper;

## Calls

use eBay::API::XML::Call::GetToken;
use eBay::API::XML::Call::VerifyAddItem;
use eBay::API::XML::Call::GetCategories;

use eBay::API::XML::Call::VerifyAddItem::VerifyAddItemRequestType;

use eBay::API::XML::CallRetry;

## Enums
use eBay::API::XML::DataType::Enum::ListingDurationCodeType;
use eBay::API::XML::DataType::Enum::CountryCodeType;
use eBay::API::XML::DataType::Enum::CurrencyCodeType;

## DataTypes
use eBay::API::XML::DataType::ItemType;
use eBay::API::XML::DataType::ExternalProductIDType;

use eBay::API::XML::DataType::AmountType;

use eBay::API::XML::DataType::CategoryType;
use eBay::API::XML::DataType::CharacteristicsSetType;
use eBay::API::XML::DataType::CharacteristicType;
use eBay::API::XML::DataType::ExtendedProductFinderIDType;

use eBay::API::XML::DataType::LabelType;
use eBay::API::XML::DataType::Enum::SortOrderCodeType;
use eBay::API::XML::DataType::ValType;

use eBay::API::XML::DataType::FeesType;

use eBay::API::XML::DataType::ShippingDetailsType;
use eBay::API::XML::DataType::ShippingServiceOptionsType;



#main_serialize_reserve_price();
#main_serialize_category();
#main_serialize_item();
#main_serialize_VerifyAddItem();
#main_serialize_fees();

#main_run_getCategoriesAsRefToArray();
main_run_getCategoriesAsArray();
#main_run_verifyAddItem();
#main_run_getToken();
#main_run_whole_http_request_response();
#main_run_verifyAddItem_with_preassambled_request_xml();
	
sub tidy {
  
  my $strXml = shift;

  my $pTidy = XML::Tidy->new('xml' => $strXml);
  $pTidy->tidy();
  my $tidyStrXml = $pTidy->toString();

  return $tidyStrXml;
}

sub main_serialize_reserve_price {

  my $pReservePrice = eBay::API::XML::DataType::AmountType->new();
  $pReservePrice->setCurrencyID('US');
  $pReservePrice->setValue(5.0);

  my $tagName = 'ReservePrice';
  my $srcXmlStr = $pReservePrice->serialize($tagName);

  my $rhXmlSimple = XMLin( $srcXmlStr
	                     , forcearray => []
			     , keyattr => [] );

  print "\n\tDESERIALIZATION\n";
  my $pDestReservePrice = eBay::API::XML::DataType::AmountType->new();
  $pDestReservePrice->deserialize('rhXmlSimple' => $rhXmlSimple);

  my $destXmlStr 
         = $pDestReservePrice->serialize($tagName);

  writeResultsToFiles ('resrvePrice', $srcXmlStr,  $destXmlStr);
}

sub main_serialize_category {

  my $pInitialCategoryType = 	getPrimaryCategory();

  my $tagName = 'PrimaryCategory';
  my $strInitialXml = $pInitialCategoryType->serialize($tagName);

  print $strInitialXml . "\n\n";

  print ("## 111\n");
  my $rhXmlSimple = XMLin( $strInitialXml,
	                     , forcearray => []
			     , keyattr => [] );

  print ("## 222\n");
  my $pDeserCategoryType = 
                     eBay::API::XML::DataType::CategoryType->new();
  
  $pDeserCategoryType->deserialize('rhXmlSimple' => $rhXmlSimple );

  print ("## AFTER DESERIALIZATION\n");

  my $strSecondXml = $pDeserCategoryType->serialize($tagName);
  print "strSecondXml=|$strSecondXml|\n";

  writeResultsToFiles ('categoryType', $strInitialXml,  $strSecondXml);
}

sub writeResultsToFiles {
  my $testName = shift;
  my $srcXmlStr = shift;
  my $destXmlStr = shift;

  my $msg = '';
  if ( $srcXmlStr eq $destXmlStr ) {
     $msg = <<"GOOD";
1. pSourceType instantiated, 
2. pSourceType serialized to srcXmlStr
3. xmlString parsed by XML::Simple
4. pDestinationType  instantiated
5. pDestinationType deserialized the XML::Simple structure
6. pDestinationType serialized to destXmlStr
7. destXmlStr EQUALS srcXmlStr
    TEST OK
GOOD
  } else { 
     $msg = 'failed'
  }

     my @arr = ( [$testName .'dest.xml', $destXmlStr]
	         ,[$testName . 'src.xml', $srcXmlStr]
	       );

  foreach my $el ( @arr  ) {
        my $filename = $el->[0];
	my $strXml   = $el->[1];
        my $fh = IO::File->new( "> $filename");
        if ( ! defined $fh ) {
	   print "Could not create file: |$filename|,error=|" . $! . "\n";
	   exit 1;
        }
        print $fh $strXml;
	$fh->close();
  }

  print $msg;
}

sub writeStrToFile {
  my $filename = shift;
  my $str      = shift;

  my $out_fh = IO::File->new( "> $filename ");
  if ( ! defined $out_fh ) {
    my $error = $!;
    print "Could not write to file=|$filename|, error=|$error|\n";
    exit 1;
  }

  print $out_fh $str;
  $out_fh->close();
}

sub readFileIntoStr {

  my $filename = shift;

  my $fh = IO::File->new( "< $filename ");
  if ( ! defined $fh ) {
    my $error = $!;
    print "Could not read file=|$filename|, error=|$error|\n";
    exit 1;
  }

  my $keep = $/;
  $/ = undef;
  my $str = <$fh>;
  $/ = $keep;

  return $str;
}

sub main_serialize_item {

  my $pItemType = getItem_forAddItem();

  my $tagName = 'Item';
  my $srcXmlStr = $pItemType->serialize($tagName);
  $srcXmlStr = tidy($srcXmlStr);
  print $srcXmlStr . "\n";

  my $sBuyItNowPrice = $pItemType->getBuyItNowPrice();
  print Dumper( $pItemType);
  print "sBuyItNowPrice=|$sBuyItNowPrice|\n";

  my $rhXmlSimple = XMLin( $srcXmlStr,
	                     , forcearray => []
			     , keyattr => [] );

  my $pNewItemType = eBay::API::XML::DataType::ItemType->new();
  $pNewItemType->deserialize(
	  	 'tagName'     => $tagName
		,'rhXmlSimple' => $rhXmlSimple
              );

  my $destXmlStr = $pNewItemType->serialize($tagName);
  $destXmlStr= tidy($destXmlStr);

  print ("## AFTER DESERIALIZATION\n");
  writeResultsToFiles ('item', $srcXmlStr,  $destXmlStr);
}

sub getPrimaryCategory{

  my $pType = eBay::API::XML::DataType::CategoryType->new();
  $pType->setCategoryID(357);

  return $pType;
}

sub getPrimaryCategoryEverything {

   my $pType = eBay::API::XML::DataType::CategoryType->new();

   $pType->setAutoPayEnabled('true');
  $pType->setB2BVATEnabled('true');
  $pType->setBestOfferEnabled('true');
  $pType->setCatalogEnabled('true');
  $pType->setCategoryID(357);
  $pType->setCategoryLevel(1);
  $pType->setCategoryName('autos');
  $pType->setCategoryParentID(undef);
  $pType->setCategoryParentName(undef);
  $pType->setExpired('true');
  $pType->setIntlAutosFixedCat('false');
  $pType->setKeywords('some keywords');
  $pType->setLSD('true');
  $pType->setLeafCategory('false');
  $pType->setNumOfItems(10);
  $pType->setORPA('true');
  $pType->setORRA('true');
  $pType->setProductFinderAvailable('true');
  $pType->setProductFinderID(100);
  $pType->setProductSearchPageAvailable('true');
  $pType->setSellerGuaranteeEligible('true');
  $pType->setVirtual('true');

     ## 1. START: set CharacteristicsSetType properties
  my $pCharacteristicsSets = 
             eBay::API::XML::DataType::CharacteristicsSetType->new();
  $pCharacteristicsSets->setAttributeSetID(10);
  $pCharacteristicsSets->setAttributeSetVersion('version');
  my $pCharacteristic = 
             eBay::API::XML::DataType::CharacteristicType->new();
  $pCharacteristic->setAttributeID(20);
  $pCharacteristic->setDateFormat("MM:DD:YYYY");
  $pCharacteristic->setDisplaySequence("some display sequence");
  $pCharacteristic->setDisplayUOM("string UOM");

  
  my $pLabelType = eBay::API::XML::DataType::LabelType->new();
  $pLabelType->setName("labelName");       ## ?!?!
  $pCharacteristic->setLabel($pLabelType);
  
  my $pSortOrderCode = "Ascending";  # ENUM!! must be one of enum values
  #$pCharacteristic->setSortOrder($pSortOrderCode);
  
  my $pValType = eBay::API::XML::DataType::ValType->new();
  $pValType->setSuggestedValueLiteral("suggested value");
  $pValType->setValueID(39);
  $pValType->setValueLiteral("value");
  $pCharacteristic->setValueList($pValType);


  $pCharacteristicsSets->setCharacteristics($pCharacteristic);
  $pCharacteristicsSets->setName("characteristinssetsName-Value");
     ## 1. END: set CharacteristicsSetType properties

  $pType->setCharacteristicsSets ( $pCharacteristicsSets );

     ## 2. START: set ExtendedProductFinderIDType properties
  my $pProductFinderIDsType = 
         eBay::API::XML::DataType::ExtendedProductFinderIDType->new();
  $pProductFinderIDsType->setProductFinderBuySide('false');
  $pProductFinderIDsType->setProductFinderID(100);
  $pType->setProductFinderIDs ($pProductFinderIDsType);

     ## 2. END: set ExtendedProductFinderIDType properties

  return $pType;
}


sub getItem_forAddItem { 

   my $pItem = undef;
   my $sEnvSiteId = $ENV{'EBAY_API_SITE_ID'};

   my $run_sg = 0;
   if ( defined $sEnvSiteId ) {
      if ( $sEnvSiteId eq '' ) {
      	$run_sg = 0;  # us
      } elsif ( $sEnvSiteId == 216 ) {
      	$run_sg = 1;  # sg
      }
   }
   if ( $run_sg == 1 ) {
      $pItem = getItem_forAddItem_SG();   
   } else {
      $pItem = getItem_forAddItem_US();   
   }
   return $pItem;
}

sub getItem_forAddItem_US {

    # must test VerifyAddItem with 
    #   a) InternationalShippingServiceOptions
    #   b) ShippingServiceOptions
    #   c) ShipToLocations
    #   d) Attributes
    #   e) CharityListingsInfo
    #   f) Payment methods
      # set item properites

   my $pItem = eBay::API::XML::DataType::ItemType->new();
   my $pBuyItNowPrice = eBay::API::XML::DataType::AmountType->new();
   $pBuyItNowPrice->setValue(99.0);
   $pItem->setBuyItNowPrice($pBuyItNowPrice);

   $pItem->setCountry('US');
   $pItem->setCurrency('USD');
   $pItem->setDescription('NewSchema item description.');
   my $duration = 
   	eBay::API::XML::DataType::Enum::ListingDurationCodeType::Days_7;
   #print "\n\nduration=|$duration|\n\n";
   $pItem->setListingDuration($duration);
   $pItem->setLocation('San Jose, CA');
   my @paymentMethods = (
      eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType::PaymentSeeDescription
     ,eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType::MOCC
     ,eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType::COD
	   		);
   
        #
	# MILENKO TODO
	#  must write UNIT tests that test whether 
	#  all 3 possible kind of array property parameters 
	#  work correctly:
	#     a) a ref to an array
	#     b) an array
	#     c) a scalar			 
   $pItem->setPaymentMethods(\@paymentMethods);
   #$pItem->setPaymentMethods(@paymentMethods);
   #$pItem->setPaymentMethods('PaymentSeeDescription');
   
   $pItem->setQuantity(1);
   $pItem->setRegionID(0);

   my $pReservePrice = eBay::API::XML::DataType::AmountType->new();
   #$pReservePrice->setCurrencyID('US');
   $pReservePrice->setValue(10.0);
   $pItem->setReservePrice($pReservePrice);
   #$pItem->setReservePrice(5.0);

   my $pStartPrice = eBay::API::XML::DataType::AmountType->new();
   $pStartPrice->setValue(5.0);
   $pItem->setStartPrice($pStartPrice);
   #$pItem->setStartPrice(1.0);
   $pItem->setTitle('NewSchema item title');

   my $pPrimaryCategory = eBay::API::XML::DataType::CategoryType->new();
   $pPrimaryCategory->setCategoryID(357);
   $pItem->setPrimaryCategory($pPrimaryCategory);

   my $pShippingDetailsType = getShippingDetailsType();
   $pItem->setShippingDetails($pShippingDetailsType);


   return $pItem;
}

sub getItem_forAddItem_SG {     ## SG

      # set item properites
   my $pItem = eBay::API::XML::DataType::ItemType->new();

   $pItem->setBuyItNowPrice(99.0);
   $pItem->setCountry(eBay::API::XML::DataType::Enum::CountryCodeType::SG);
   $pItem->setCurrency(eBay::API::XML::DataType::Enum::CurrencyCodeType::SGD);
   $pItem->setDescription('NewSchema item description.');
   my $duration = 
   	eBay::API::XML::DataType::Enum::ListingDurationCodeType::Days_7;
   $pItem->setListingDuration($duration);
   $pItem->setLocation('San Jose, CA');
   my @paymentMethods = (
      eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType::PaymentSeeDescription
     ,eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType::MOCC
     ,eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType::COD
	   		);
   
   $pItem->setPaymentMethods(\@paymentMethods);
   
   $pItem->setQuantity(1);
   $pItem->setRegionID(0);

   $pItem->setStartPrice(1.0);
   $pItem->setTitle('NewSchema item title');

   my $pPrimaryCategory = eBay::API::XML::DataType::CategoryType->new();
   $pPrimaryCategory->setCategoryID(20083);  # SG antiques
   $pItem->setPrimaryCategory($pPrimaryCategory);

   return $pItem;
}

sub getShippingDetailsType_ONE_error {

   my $ShippingDetailsType = 
   		eBay::API::XML::DataType::ShippingDetailsType->new();

     # 1. set shipping service options
   my @aShippingServiceOptions = ();
   my $pShippingServiceOptionsType = undef;

      # 1.1. shipping service 1
   $pShippingServiceOptionsType =
         eBay::API::XML::DataType::ShippingServiceOptionsType->new();
   $pShippingServiceOptionsType->setShippingServicePriority(3);
   $pShippingServiceOptionsType->setShippingService(11);

   push @aShippingServiceOptions, $pShippingServiceOptionsType;
   
      # 1.2. shipping service 2
   $pShippingServiceOptionsType =
         eBay::API::XML::DataType::ShippingServiceOptionsType->new();
   $pShippingServiceOptionsType->setShippingServicePriority(2);
   $pShippingServiceOptionsType->setShippingService(10);

   push @aShippingServiceOptions, $pShippingServiceOptionsType;
   
      # 1.3. shipping service 3
   $pShippingServiceOptionsType =
         eBay::API::XML::DataType::ShippingServiceOptionsType->new();
   $pShippingServiceOptionsType->setShippingServicePriority(1);
   $pShippingServiceOptionsType->setShippingService(7);

   push @aShippingServiceOptions, $pShippingServiceOptionsType;
   
   $ShippingDetailsType->setShippingServiceOptions(\@aShippingServiceOptions);
   return $ShippingDetailsType;
}

sub getShippingDetailsType_response_TWO_errors {

   my $ShippingDetailsType = 
   		eBay::API::XML::DataType::ShippingDetailsType->new();

     # 1. set shipping service options
   my @aShippingServiceOptions = ();
   my $pShippingServiceOptionsType = undef;

      # 1.1. shipping service 3
   $pShippingServiceOptionsType =
         eBay::API::XML::DataType::ShippingServiceOptionsType->new();
   $pShippingServiceOptionsType->setShippingServicePriority(1);
   $pShippingServiceOptionsType->setShippingService('USPSParcel');

   push @aShippingServiceOptions, $pShippingServiceOptionsType;
   
   $ShippingDetailsType->setShippingServiceOptions(\@aShippingServiceOptions);
   return $ShippingDetailsType;
}

sub getShippingDetailsType_NO_errors_ONE_warning {

   my $ShippingDetailsType = 
   		eBay::API::XML::DataType::ShippingDetailsType->new();

     # 1. set shipping service options
   my @aShippingServiceOptions = ();
   my $pShippingServiceOptionsType = undef;

      # 1.1. shipping service 3
   $pShippingServiceOptionsType =
         eBay::API::XML::DataType::ShippingServiceOptionsType->new();
   $pShippingServiceOptionsType->setShippingServicePriority(1);
   $pShippingServiceOptionsType->setShippingService('USPSParcel');
   $pShippingServiceOptionsType->setShippingServiceCost(10);

   push @aShippingServiceOptions, $pShippingServiceOptionsType;
   
   $ShippingDetailsType->setShippingServiceOptions(\@aShippingServiceOptions);
   return $ShippingDetailsType;
}

sub getShippingDetailsType {

  my $ShippingDetailsType;
          # I used to have problems with getShippingDetailsType_ONE_error
	  #   It was not properly parsed because it does return an array.
	  #      I FIXED IT, BUT I HAVE TO CREATE A UNIT TEST FOR THIS!!!    
	  #  
  #$ShippingDetailsType = getShippingDetailsType_ONE_error();
  #$ShippingDetailsType = getShippingDetailsType_response_TWO_errors();
  $ShippingDetailsType = getShippingDetailsType_NO_errors_ONE_warning();

  return $ShippingDetailsType;
}

sub main_serialize_VerifyAddItem {

  my $pItemType = getItem_forAddItem();

  my $tagName = 'VerifyAddItemRequest'; 

  my $pSrcReq = 
       eBay::API::XML::Call::VerifyAddItem::VerifyAddItemRequestType->new();
  $pSrcReq->setItem($pItemType);

  my $pExternalProductID = 
       eBay::API::XML::DataType::ExternalProductIDType->new();
  $pExternalProductID->setReturnSearchResultOnDuplicates('true');
  $pExternalProductID->setValue('externalProductID value');

  $pSrcReq->setExternalProductID($pExternalProductID);
  
  my $srcXmlStr = $pSrcReq->serialize($tagName);


  my $rhXmlSimple = XMLin( $srcXmlStr,
	                     , forcearray => []
			     , keyattr => [] );

  my $pDestReq = 
       eBay::API::XML::Call::VerifyAddItem::VerifyAddItemRequestType->new();
  $pDestReq->deserialize(
	  	 'tagName'     => $tagName
		,'rhXmlSimple' => $rhXmlSimple
              );
  my $destXmlStr = $pDestReq->serialize($tagName);

  print ("## AFTER DESERIALIZATION\n");
  writeResultsToFiles ('verifyadditemrequest', $srcXmlStr,  $destXmlStr);
}

sub main_serialize_fees {

   my $tagName = 'Fees';
   my $pFees = eBay::API::XML::DataType::FeesType->new();
  
   my @arrFees = ();

   my @arrArgs = ( ['fee number 1', 10, 'USD']
	    ,['fee number 2', 20, 'AUD'] 
	          );

   foreach my $raArg ( @arrArgs) {
	   
      my $feeName       = $raArg->[0];
      my $feeValue      = $raArg->[1];
      my $feeCurrencyID = $raArg->[2];

      my $pFeeType;
      $pFeeType = eBay::API::XML::DataType::FeeType->new();
      push @arrFees, $pFeeType;

      $pFeeType->setName( $feeName );
      
      my $pFeeAmount = eBay::API::XML::DataType::AmountType->new();
      $pFeeType->setFee($pFeeAmount);
      $pFeeAmount->setValue($feeValue);
      $pFeeAmount->setCurrencyID($feeCurrencyID);

   }	   
   $pFees->setFee ( \@arrFees );
   my $srcXmlStr = $pFees->serialize( $tagName );

   
   my $rhXmlSimple = XMLin( $srcXmlStr,
	                     , forcearray => []
			     , keyattr => [] );
   my $pDestReq = 
       eBay::API::XML::DataType::FeesType->new();
   $pDestReq->deserialize(
	  	 'tagName'     => $tagName
		,'rhXmlSimple' => $rhXmlSimple
              );
   my $destXmlStr = $pDestReq->serialize($tagName);

   print ("## AFTER DESERIALIZATION\n");
   writeResultsToFiles ('fees', $srcXmlStr,  $destXmlStr);
}

sub create_VerifyAddItemCall {

  my $pCall = undef;

  	## MILENKO TODO
	#   Must create real test file ".t" so 
	#   that all tests can be run as real Unit tests

  $pCall = _create_generic_VerifyAddItemCall();
  #$pCall = _create_VerifyAddItemCall_testRetries();
  #$pCall = _create_VerifyAddItemCall_testRetriesWithConnFailure();
  #$pCall = _create_VerifyAddItemCall_testTimeout();

  return $pCall;
}

sub _create_generic_VerifyAddItemCall {

  my $pItemType = getItem_forAddItem();

  my $pCall = eBay::API::XML::Call::VerifyAddItem->new();
  $pCall->setItem($pItemType);
  $pCall->setVersion(445);
  #$pCall->setVersion($pCall->getCompatibilityLevel());
  $pCall->setDetailLevel('ReturnAll');
 
  return $pCall; 
}

sub _create_VerifyAddItemCall_testRetries {

  my $pCall = _create_generic_VerifyAddItemCall();
  
  my $pCallRetry = eBay::CallRetry::createTestCallRetry();
  $pCall->setCallRetry($pCallRetry);
  
  return $pCall;
}

sub _create_VerifyAddItemCall_testRetriesWithConnFailure {

  my $pCall = _create_generic_VerifyAddItemCall();
  
  my $pCallRetry = eBay::CallRetry::createTestCallRetry();
  $pCall->setCallRetry($pCallRetry);
  $pCall->setProxy('http://test.dummy.comx');
  
  return $pCall;
}

sub _create_VerifyAddItemCall_testTimeout {

  my $pCall = _create_generic_VerifyAddItemCall();
  
  $pCall->setTimeout(1);

  return $pCall;
}

sub main_run_verifyAddItem {

  my $pCall = create_VerifyAddItemCall();
  
  my $requestRawXml = $pCall->getRequestRawXml();
  writeStrToFile ("VerifyAddItemRequest.xml", $requestRawXml);
  my $tidyXml = tidy ( $requestRawXml);
  print "\n$tidyXml\n";
  #exit 1;
  $pCall->execute();

  process_VerifyAddItem_AfterExecute( $pCall );

}

sub main_run_whole_http_request_response {

  my $pCall = create_VerifyAddItemCall();
  
  my $sHttpRequestAsString = $pCall->getHttpRequestAsString();
  print "\nsHttpRequestAsString=|$sHttpRequestAsString|\n";

  $pCall->execute();
  
  if ( $pCall->isHttpRequestSubmitted() ) {
     my $hasErrors = $pCall->hasErrors();
     my $hasWarnings = $pCall->hasWarnings();
     my $sAck = $pCall->getResponseAck();
     print "hasErrors=|$hasErrors|\n";
     print "hasWarnings=|$hasWarnings|\n";
     print "sAck=|$sAck|\n";
  }

  my $sHttpResponseAsString = $pCall->getHttpResponseAsString();
  print "\nsHttpResponseAsString=|$sHttpResponseAsString|\n";
}

sub main_run_verifyAddItem_with_preassambled_request_xml {

  my $pCall = create_VerifyAddItemCall();
  
  my $rawRequestXml = '<nothing/>';
  my $inFilename = 'VerifyAddItemRequest_for_test.xml';
     #
     # MILENKO TODO
     #  Must create a test that tests errors when an empty 
     #    or near empty XML request is submitted.
     #
  $rawRequestXml = readFileIntoStr( $inFilename );

  $pCall->setRequestRawXml( $rawRequestXml );
  
  $pCall->execute();

  process_VerifyAddItem_AfterExecute( $pCall );

}

sub process_VerifyAddItem_AfterExecute {
  
  my $pCall = shift;	
  
  my $responseRawXml = $pCall->getResponseRawXml();
  writeStrToFile ("VerifyAddItemResponse.xml", $responseRawXml);
  my $formatedRawOutput = $responseRawXml;
  if ( $pCall->isResponseValidXml() ) {
     $formatedRawOutput= tidy ( $formatedRawOutput);
  }
  print "\n$formatedRawOutput\n";

  print Dumper ( $pCall->getResponseErrors() ) ;

  my $hasErrorsOrWarnings = $pCall->hasErrors() || $pCall->hasWarnings();
  
  if ( $hasErrorsOrWarnings == 1 ) {
     my $raErrors = $pCall->getResponseErrors();
     if ( defined $raErrors) {
        #print Dumper($raErrors); print "\n";
        my $ndx = 1;
        foreach my $pError ( @$raErrors ) {
       
          my $sErrorCode    = $pError->getErrorCode();
          my $sSeverityCode = $pError->getSeverityCode();
          my $sLongMessage  = $pError->getLongMessage();
          print "#####  START: error= $ndx   ############################\n";
             print Dumper($pError);
          print "#####  END:   error= $ndx   ############################\n";
          print "sErrorCode=|$sErrorCode|\n";
          print "sSeverityCode=|$sSeverityCode|\n";
          print "sLongMessage=|$sLongMessage|\n";
          $ndx++;
        }
     }
  }

  my $isFailure = $pCall->hasErrors();
  if ( $isFailure ) {
     print "\nCall has returned severe errors, no need to process any other respones values\n\n";
  } else {
     my $sCategoryID = $pCall->getCategoryID() || '';
     my $sCategory2ID = $pCall->getCategory2ID() || '';

     # THIS MIGHT BE A PROBLEM
     #   MILENKO TODO
     #  ItemID is a generated as a complex type but
     #    in fact it is just a simple value 'xs:string'
     #      So basically I should not be generating a special class for
     #      ItemIDType

     my $sItemID      = $pCall->getItemID()->getValue();
     
     print "\n";
     print "itemID      =|$sItemID|\n";
     print "sCategoryID =|$sCategoryID|\n";
     print "sCategory2ID=|$sCategory2ID|\n";
     print "Fees:\n";
     my $pFees = $pCall->getFees();
     if ( defined $pFees ) {
        my $raFees = $pFees->getFee();
        foreach my $pFee (@$raFees) {

           my $pAmount = $pFee->getFee();
           my $sAmount = $pAmount->getValue();
           my $sCurrencyID = $pAmount->getCurrencyID();
           my $sFeeName = $pFee->getName();
           print "$sCurrencyID, $sAmount, $sFeeName\n";
        }
     } else {
        print "There are no fees\n";
     }

        #
	#  This is used to test: getXmlSimpleDataStructure() method
	#
     my @arrPath;
     @arrPath = ('fakenode');
     @arrPath = ('Fees');
     @arrPath = ('Fees', 'Fee');
     @arrPath = ('Errors');
     my $rh = $pCall->getXmlSimpleDataStructure( \@arrPath );
     #print Dumper ( $rh );
  }

}

sub main_run_getToken {

  my $pCall = eBay::API::XML::Call::GetToken->new();
  
  $pCall->execute();

  my $sHardExpirationTime = $pCall->getHardExpirationTime();
  my $eBayAuthToken = $pCall->getEBayAuthToken();

  print "\n\n";
  print "sHardExpirationTime=|$sHardExpirationTime|\n";
  print "eBayAuthToken=|$eBayAuthToken|\n";
}

sub main_run_getCategoriesAsRefToArray {

  my $pCall = eBay::API::XML::Call::GetCategories->new();

  $pCall->setVersion(445);
  $pCall->setCategorySiteID(0);
  $pCall->setLevelLimit(1);
  $pCall->setDetailLevel('ReturnAll');

  $pCall->execute();
  my $responseRawXml = $pCall->getResponseRawXml();
  
  writeStrToFile ("GetCategoriesResponse.xml", $responseRawXml);

  my $pCategoryArray = $pCall->getCategoryArray();
  
  my $numOfCategories = $pCall->getCategoryCount() || 0;
  my $secNumOfCategories = '';
  my $raCategories = [];
  if ( $numOfCategories > 0 ) {
	
    $raCategories = $pCategoryArray->getCategory();
    $secNumOfCategories = scalar @$raCategories;
  }

  foreach my $pCategoryType (@$raCategories) {
     print Dumper($pCategoryType) . "\n";
  }

  my $sCategoryVersion = $pCall->getCategoryVersion() || '';
  my $sCurrency        = $pCall->getCurrency() || '';

  print "numOfCategories=|$numOfCategories|\n";
  print "secNumOfCategories=|$secNumOfCategories|\n";
  print "sCategoryVersion=|$sCategoryVersion|\n";
  print "sCurrency=|$sCurrency|\n";
}

sub main_run_getCategoriesAsArray {

  my $pCall = eBay::API::XML::Call::GetCategories->new();

  $pCall->setVersion(445);
  $pCall->setCategorySiteID(0);
  $pCall->setLevelLimit(1);
  $pCall->setDetailLevel('ReturnAll');

  $pCall->execute();
  my $responseRawXml = $pCall->getResponseRawXml();
  
  writeStrToFile ("GetCategoriesResponse.xml", $responseRawXml);

  my $pCategoryArray = $pCall->getCategoryArray();
  
  my $numOfCategories = $pCall->getCategoryCount() || 0;
  my $secNumOfCategories = '';
  my @aCategories = ();
  if ( $numOfCategories > 0 ) {
	
    @aCategories = $pCategoryArray->getCategory();
    $secNumOfCategories = scalar @aCategories;
  }

  foreach my $pCategoryType (@aCategories) {
     print Dumper($pCategoryType) . "\n";
  }

  my $sCategoryVersion = $pCall->getCategoryVersion() || '';
  my $sCurrency        = $pCall->getCurrency() || '';

  print "Retrieved categories as an ARRAY, instead of as a ref to an array\n";
  print "numOfCategories=|$numOfCategories|\n";
  print "secNumOfCategories=|$secNumOfCategories|\n";
  print "sCategoryVersion=|$sCategoryVersion|\n";
  print "sCurrency=|$sCurrency|\n";
}
