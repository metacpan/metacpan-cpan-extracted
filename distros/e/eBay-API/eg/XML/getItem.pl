#! /usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Getopt::Long;

use eBay::API::XML::Call::GetItem;
use eBay::API::XML::DataType::Enum::AckCodeType;
use eBay::API::XML::DataType::Enum::DetailLevelCodeType;

# Parse command line
my %options = ();
my @getopt_args = (
    'h',     # print usage
    'i=s',   # itemId
    's=s',   # siteId
                  );

GetOptions(\%options, @getopt_args);
usage() if $options{'h'};

my $sItemId = $options{'i'};
usage() unless $sItemId;

my $sSiteId = $options{'s'} || 0;
# End parse command line

my $pCall = eBay::API::XML::Call::GetItem->new();

    # 1. set site id
$pCall->setSiteID($sSiteId);

    # 2. set itemId
my $pItemIDType = eBay::API::XML::DataType::ItemIDType->new();
$pItemIDType->setValue($sItemId);
$pCall->setItemID($pItemIDType);

    # 3. set detail level
    my $raDetailLevel = [
 eBay::API::XML::DataType::Enum::DetailLevelCodeType::ReturnAll
,eBay::API::XML::DataType::Enum::DetailLevelCodeType::ItemReturnDescription
                        ];
$pCall->setDetailLevel( $raDetailLevel);

    # 4. execute the call
$pCall->execute();

    # 5. look for errors
my $hasErrors = $pCall->hasErrors();
if ($hasErrors) {
    
    my $raErrors = $pCall->getErrors();
    foreach my $pError ( @$raErrors ) {

        my $sErrorCode = $pError->getErrorCode();
        my $sShortMessage = $pError->getShortMessage();
        my $sLongMessage = $pError->getLongMessage();
        print "\n";
        print "ErrorCode=$sErrorCode, ShortMessage=$sShortMessage\n";
        my @aErrorParameters = $pError->getErrorParameters();
        foreach my $pErrorParameter ( @aErrorParameters) {
            my $sParamID = $pErrorParameter->getParamID();
            my $sValue  = $pErrorParameter->getValue();
            print "\tParamID=$sParamID, Value=$sValue\n";
        }
        print "\n";
    }
} else {

        # no errors - retrieve data
    my $pItem = $pCall->getItem();

    $sItemId = $pItem->getItemID()->getValue();

    my $sTitle = $pItem->getTitle();
    my $sSubTitle = $pItem->getSubTitle();
    my $sPrimaryCategoryId = $pItem->getPrimaryCategory()->getCategoryID();
    my $sPrimaryCategoryName = $pItem->getPrimaryCategory()->getCategoryName();
    my $sListingType = $pItem->getListingType();

    print "itemId=$sItemId\n";
    print "title=$sTitle\n";
    my $sQuantity = $pItem->getQuantity();
    my $sStartPrice = $pItem->getStartPrice()->getValue();
    my $sCurrencyID = $pItem->getStartPrice()->getCurrencyID();  # code - like 'USD'
    my $sListingDuration = $pItem->getListingDuration();

        # payment methods
    my @aPaymentMethods = $pItem->getPaymentMethods();
    foreach my $sPaymentMethod ( @aPaymentMethods) {
        #print "$sPaymentMethod\n";
    }
    my $pSeller = $pItem->getSeller();   # type - eBay::API::XML::DataType::UserType
                                         #    see getUser.pl example

        # additional listing info ( listing details )
    my $sTimeLeft = $pItem->getTimeLeft();
    my $pListingDetails = $pItem->getListingDetails();
    my $sStartTime = $pListingDetails->getStartTime();
    my $sEndTime = $pListingDetails->getEndTime();
    my $sConvertedBuyItNowPrice = $pListingDetails->getConvertedBuyItNowPrice()->getValue();
    my $sConvertedBuyItNowCurrencyID = $pListingDetails->getConvertedBuyItNowPrice()->getCurrencyID();

    my $sConvertedStartPrice = $pListingDetails->getConvertedStartPrice()->getValue();
    my $sConvertedStartPriceCurrencyID = $pListingDetails->getConvertedStartPrice()->getCurrencyID();

        # selling status
    my $pSellingStatus = $pItem->getSellingStatus();
    my $sListingStatus = $pSellingStatus->getListingStatus();

        # shipping options
    my @aShipToLocations = $pItem->getShipToLocations();
    my $pShippingDetails = $pItem->getShippingDetails();
    my @aShippingServiceOptions = $pShippingDetails->getShippingServiceOptions();
    foreach my $pShippingServiceOption (@aShippingServiceOptions) {
        my $sShippingService = $pShippingServiceOption->getShippingService();
    }

    my @aInternationalShippingServiceOptions = 
                    $pShippingDetails->getInternationalShippingServiceOption();
    foreach my $pIntlShippingServiceOption (@aInternationalShippingServiceOptions) {
        my $sShippingService = $pIntlShippingServiceOption->getShippingService();
    }
}


sub usage {

    my $progname = $0;
    $progname =~ s,.*[\\/],,;  # use basename only
    $progname =~ s/\.\w*$//;   # strip extension, if any

    die <<"EOT";
Usage: $progname [-options]
    -i <itemId>   itemId (required)
    -s <siteId>   siteId (optional) 
                        (siteId values can be found in 
                            eBay::API::XML::DataType::Enum::SiteCodeType )
    -h            Print this message
EOT
}
