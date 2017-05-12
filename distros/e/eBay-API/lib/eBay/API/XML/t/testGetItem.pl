#!/usr/bin/perl -w
#
use strict;
use warnings;

use Data::Dumper;

use eBay::API::XML::Call::GetItem;
use eBay::API::XML::DataType::ItemType;
use eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType;
use ROW::Date;

my %req_data = {
	         'req_locale' => 'en-SG'
		 ,'req_site_tz' => 'SGT'
	       };

main();

sub getItemFromGetItemCall {

  my $pCall = eBay::API::XML::Call::GetItem->new();
  #$pCall->setItemID(8085855556);
  #$pCall->setItemID(9204407646);   # SG item 
     # ends on 02/21/2006
  $pCall->setItemID(9204429598);   # SG item 

    # payment methods do not return ARRAY which was expected by
    #   a programmer - since it was specified in documentation that
    #    it returns array. TODO this must be fixed  !!!!
    # fails with the following error:
    #  Can't use string ("PayPal") as an ARRAY ref while "strict refs" 
    #    in use at ./test  GetItem.pl line 64.
  $pCall->setItemID(9204409833);   # US item 

  $pCall->execute();

  my $pItem = $pCall->getItem();

  #print Dumper($pItem);

  return $pCall;
}

sub main {

  my $pCall = getItemFromGetItemCall();
  my $pItem = $pCall->getItem();

  my $pSellingStatus    = $pItem->getSellingStatus();

  my $pCurrentPrice     = $pSellingStatus->getCurrentPrice();
  my $sCurrentPrice     = $pCurrentPrice->getValue();
  print "sCurrentPrice=|$sCurrentPrice|\n";

  my $pConvertedPrice   = $pSellingStatus->getConvertedCurrentPrice();
  my $sConvertedPrice   = $pConvertedPrice->getValue();
  print "sConvertedPrice=|$sConvertedPrice|\n";
  
  my $pStartPrice   = $pItem->getStartPrice();
  my $sStartPrice   = $pStartPrice->getValue();  
  print "sStartPrice=|$sStartPrice|\n";

  my $pMinimumToBid   = $pSellingStatus->getMinimumToBid();
  my $sMinimumToBid   = $pMinimumToBid->getValue();
  print "sMinimumToBid=|$sMinimumToBid|\n";
 
  my $pBuyItNowPrice   = $pItem->getBuyItNowPrice();
  my $sBuyItNowPrice   = $pBuyItNowPrice->getValue();
  print "sBuyItNowPrice=|$sBuyItNowPrice|\n";
 
  my $pListingDetails           = $pItem->getListingDetails();
  my $pConvertedBuyItNowPrice   = $pListingDetails->getConvertedBuyItNowPrice();
  my $sConvertedBuyItNowPrice   = $pConvertedBuyItNowPrice->getValue();
  print "sConvertedBuyItNowPrice=|$sConvertedBuyItNowPrice|\n";


  my $raPaymentMethods = $pItem->getPaymentMethods();
  print "raPaymentMethods=|$raPaymentMethods|\n";
  print 'paymentMethods = ['. join("\n\t,", @$raPaymentMethods) . "]\n";
 
  validatePaymentMethods($pItem);

  my $sBidCount = $pSellingStatus->getBidCount();
  print "sBidCount=|$sBidCount|\n";

  my $sCountry = $pItem->getCountry();
  print "sCountry=|$sCountry|\n";
  
  my $SellerId = undef;
  my $isOwner;
  my $pSeller = $pItem->getSeller();
  if ( defined $pSeller ) {
     $SellerId = $pSeller->getUserID();
  }
  print "SellerId=|$SellerId|\n";

  my $HighBidderId = undef;
  my $pHighBidder = $pSellingStatus->getHighBidder();
  if ( defined $pHighBidder ) {
     $HighBidderId = $pHighBidder->getUserID();
  }  

  print "HighBidderId=|" . formatUndef($HighBidderId). "|\n";
  #printHighBidderFromXmlSimpleStructure ($pCall);

  my $cat_id;
  my $cat2_id;

  my $pPrimaryCategory   = $pItem->getPrimaryCategory();
  if ( defined $pPrimaryCategory ) {
     $cat_id = $pPrimaryCategory->getCategoryID();
  }
  print "cat_id=|$cat_id|\n";
  my $pSecondaryCategory = $pItem->getSecondaryCategory();
  if ( defined $pSecondaryCategory ) {
     $cat2_id = $pSecondaryCategory->getCategoryID();
  }
  print "cat2_id=|" . formatUndef($cat2_id) ."|\n";
  
  my $Category_Breadcrumb;
  if ( defined $pPrimaryCategory ) {
     $Category_Breadcrumb = $pPrimaryCategory->getCategoryName();
  }
  print "Category_Breadcrumb=|$Category_Breadcrumb|\n";

  my $Category2_Breadcrumb;
  if ( defined $pSecondaryCategory ) {
     $Category2_Breadcrumb = $pSecondaryCategory->getCategoryName();
  }
  print "Category2_Breadcrumb=|" . formatUndef($Category2_Breadcrumb) . "|\n";



  my $sItemTitle = $pItem->getTitle();
  my $sHighBidder_User_Feedback_Score;
  my $sHighBidder_Star_URL;
  my $sHighBidderNewUser;
  my $sHighBidderChangedId;
  my $sHighBidderUserStatus;
  my $sEIASToken;

  if ( defined $pHighBidder ) {
     $sHighBidder_User_Feedback_Score = $pHighBidder->getFeedbackScore() || 0;
     $sHighBidder_Star_URL            =
         $ROW::Globals::feedback_stars{$pHighBidder->getFeedbackRatingStar()};
     $sHighBidderNewUser              = $pHighBidder->getNewUser();
     $sHighBidderChangedId            = $pHighBidder->getUserIDChanged();
     $sHighBidderUserStatus           = $pHighBidder->getStatus();
     $sEIASToken = $pHighBidder->getEIASToken();
  }

  my $isItemPrivate = $pItem->getPrivateListing();  

  print "sItemTitle=|" . formatUndef($sItemTitle) . "|\n";
  print "sHighBidder_User_Feedback_Score=|" . formatUndef($sHighBidder_User_Feedback_Score) . "|\n";
  print "sHighBidder_Star_URL=|" . formatUndef($sHighBidder_Star_URL) . "|\n";
  print "sHighBidderNewUser=|" . formatUndef($sHighBidderNewUser) . "|\n";
  print "sHighBidderChangedId=|" . formatUndef($sHighBidderChangedId) . "|\n";
  print "sHighBidderUserStatus=|" . formatUndef($sHighBidderUserStatus) . "|\n";
  print "sEIASToken=|" . formatUndef($sEIASToken) . "|\n";
  print "isItemPrivate=|" . formatUndef($isItemPrivate) . "|\n";


  responseBotBlock ($pCall );
  #test_dates($pItem);
  test_dates_and_endings( $pItem );
}

sub responseBotBlock {

   my $pCall = shift;	
   my $pResponseBotBlock = $pCall->getResponseBotBlock();
   my $sResponseBotBlockToken = $pResponseBotBlock->getBotBlockToken();
   my $sResponseBotBlockURL   = $pResponseBotBlock->getBotBlockUrl();

   if ( $sResponseBotBlockToken  ) {
     print "sResponseBotBlockToken=|$sResponseBotBlockToken|\n";	   
   }
   if ( $sResponseBotBlockURL ) {
     print "sResponseBotBlockURL=|$sResponseBotBlockURL|\n";	   
   }
}

sub test_dates {
  my $pItem = shift;
  my $pListingDetails = $pItem->getListingDetails();

  my $sItemEndTime = $pListingDetails->getEndTime();
  
  print "sItemEndTime=|$sItemEndTime|\n";

  #$sItemEndTime = '2006-02-17 23:20:56';
  $sItemEndTime = convertNewApiDateToOldApiDate($sItemEndTime); 
  my $tTextEndTime = ROW::Date->new($sItemEndTime);

  print Dumper($tTextEndTime);

  #$tTextEndTime->locale($req_data->{req_locale});
  #$tTextEndTime->change_zone($req_data->{req_site_tz});
  
}

sub test_dates_and_endings {
   my $pItem = shift;
   my $pListingDetails = $pItem->getListingDetails();

   my $sItemEndTime = $pListingDetails->getEndTime();
   $sItemEndTime = convertNewApiDateToOldApiDate($sItemEndTime);

   my $sItemStartTime = $pListingDetails->getStartTime();
   $sItemStartTime = convertNewApiDateToOldApiDate($sItemStartTime);

   print "sItemEndTime=|$sItemEndTime|\n";
   print "sItemStartTime=|$sItemStartTime|\n";

   $sItemEndTime   = '2004-02-25 01:55:40';
   $sItemStartTime = '2004-02-25 01:55:40';

   my $end_time = ROW::Date->new($sItemEndTime);
   print "1. end_time=|" . Dumper($end_time) . "|\n";
   #$end_time->locale($req_data{req_locale});
   #$end_time->change_zone($req_data{req_site_tz});
   print "2. end_time=|" . Dumper($end_time) . "|\n";

   my $start_time = ROW::Date->new($sItemStartTime);
   #$start_time->locale($req_data{req_locale});
   #$start_time->change_zone($req_data{req_site_tz});

   my $Duration = ROW::Delta->new($start_time, $end_time)->days();
    
   # Calculate if the auction has less than an hour left or has ended
   my $sItemTimeLeft = $pItem->getTimeLeft();
   #P2DT21H24M15S = 2DT, 21H, 24M, 15S
   
   my $rhTimeLeft = convertNewApiTimeLeftToOldApiTimeLeft($sItemTimeLeft);

#<TimeLeft>   
#  <Days>0</Days> 
#  <Seconds>0</Seconds> 
#  <Minutes>0</Minutes> 
#  <Hours>0</Hours>
#</TimeLeft>   
   my $TimeLeft = ROW::Delta->new($rhTimeLeft);
   print "time-left=|" . Dumper ($TimeLeft);
   #$TimeLeft->locale($req_data{req_locale});
   my $totalSeconds = $TimeLeft->total_seconds;
   my $isEnding = $totalSeconds < 24 * 60 * 60;
   my $isEnded = $totalSeconds <= 0; 

   print "sItemTimeLeft=|$sItemTimeLeft|\n";
   print "isEnding=|$isEnding|\n";
   print "isEnded=|$isEnded|\n";
   print "totalSeconds=|$totalSeconds|\n";
   print "Duration=|$Duration|\n";
}

sub convertNewApiDateToOldApiDate {
  my $newDate = shift;
  my $oldDate = $newDate;

  $oldDate =~ tr/T/ /;
  $oldDate =~ s/\.\d{3}Z$//;
  return $oldDate;
  #2006-02-17T03:03:20.000Z
}


sub convertNewApiTimeLeftToOldApiTimeLeft {

  my $newTimeLeft = shift;
      #P2DT21H24M15S = 2DT, 21H, 24M, 15S

  my $sDays    = 0;
  my $sHours   = 0;
  my $sMinutes = 0;
  my $sSeconds = 0;

  my $tmp;
  $tmp = $newTimeLeft;
  $tmp =~ s/^.*[A-Z](\d+)DT.*$/$1/o;
  $sDays = $tmp;

  $tmp = $newTimeLeft;
  $tmp =~ s/^.*[A-Z](\d+)H.*$/$1/o;
  $sHours = $tmp;

  $tmp = $newTimeLeft;
  $tmp =~ s/^.*[A-Z](\d+)M.*$/$1/o;
  $sMinutes = $tmp;

  $tmp = $newTimeLeft;
  $tmp =~ s/^.*[A-Z](\d+)S.*$/$1/o;
  $sSeconds = $tmp;


  my $rhOldTimeLeft = {
                    'Days'    => $sDays
                   ,'Hours'   => $sHours
                   ,'Minutes' => $sMinutes
                   ,'Seconds' => $sSeconds
                   };		      
  return $rhOldTimeLeft;		   
}

sub formatUndef {
  my $s = shift;

  if ( ! defined $s ) {
     $s = 'NOT DEFINED';
  }  
  return $s;
}

sub printHighBidderFromXmlSimpleStructure {
  my $pCall = shift;	

  my $rhXmlSimpleDs = $pCall->getXmlSimpleDataStructure();
  #print Dumper ($rhXmlSimpleDs);

  my $rhSellingStatus = $rhXmlSimpleDs->{'Item'}->{'SellingStatus'};
  print Dumper ($rhSellingStatus);

  my $HighBidderId = $rhXmlSimpleDs->{'Item'}->{'SellingStatus'}->{'HighBidder'}->{'UserID'};
  
  print "From XmlSimplsDs HighBidderId=|$HighBidderId|\n";
}

sub validatePaymentMethods {
  my $pItem = shift;

    # $raPaymentMethods is a reference to an array
  my $raPaymentMethods = $pItem->getPaymentMethods();

  my %hValidPT = (
  eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType::PersonalCheck 
                                                                     => undef
 ,eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType::MOCC   => undef
 ,eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType::COD    => undef
 ,eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType::VisaMC => undef
 ,eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType::AmEx   => undef
 ,eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType::PaymentSeeDescription => undef
 ,eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType::MoneyXferAccepted
                                                                     => undef
 ,eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType::PayPal => undef
 ,eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType::PaisaPayAccepted
                                                                     => undef
                 );

  my $noValidPT = 1;
  foreach my $sPm ( @$raPaymentMethods) {
     if ( exists($hValidPT{$sPm}) ) {
       $noValidPT = 0;
       last; 
     }
  }

  print "\n noValidPT=|$noValidPT|\n";
}
