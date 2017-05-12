#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Data::Dumper;

use eBay::API::XML::Call::GetSearchResults;
use eBay::API::XML::DataType::SearchLocationFilterType;
use eBay::API::XML::DataType::PriceRangeFilterType;
use eBay::API::XML::DataType::PaginationType;
use eBay::API::XML::DataType::Enum::CurrencyCodeType;
use eBay::API::XML::DataType::Enum::SearchFlagsCodeType;
use eBay::API::XML::DataType::Enum::CountryCodeType;
use eBay::API::XML::DataType::Enum::SiteIDFilterCodeType;
use eBay::API::XML::DataType::Enum::SearchSortOrderCodeType;
use eBay::API::XML::DataType::Enum::ItemTypeFilterCodeType;

# Parse command line
my %options = ();
my @getopt_args = (
    'h',   # print usage
    'q=s', # query (search string)
                  );

GetOptions(\%options, @getopt_args);
usage() if $options{'h'};

my $sQuery = $options{'q'} || 'test';
# End parse command line

my $pCall = eBay::API::XML::Call::GetSearchResults->new();


    # 1. set query
$pCall->setQuery( $sQuery );

    # 3. set - search in description
$pCall->setSearchFlags(
    [eBay::API::XML::DataType::Enum::SearchFlagsCodeType::SearchInDescription]
                      );

    # 4. set search location filter
my $pFilter = eBay::API::XML::DataType::SearchLocationFilterType->new();
$pFilter->setSearchLocation(
                        eBay::API::XML::DataType::Enum::SiteIDFilterCodeType::SiteImplied
                          );
$pFilter->setCountryCode(eBay::API::XML::DataType::Enum::CountryCodeType::US);   
$pCall->setSearchLocationFilter( $pFilter );

    # 5. set sorting.
$pCall->setOrder(
            eBay::API::XML::DataType::Enum::SearchSortOrderCodeType::SortByEndDate
                );

    # 6. set search by currentPrice amount
my $pPriceRangeFilterType = eBay::API::XML::DataType::PriceRangeFilterType->new();
$pPriceRangeFilterType->getMaxPrice()->setValue(1000);
$pCall->setPriceRangeFilter( $pPriceRangeFilterType );


$pCall->setItemTypeFilter(
            eBay::API::XML::DataType::Enum::ItemTypeFilterCodeType::AuctionItemsOnly
                        );

$pCall->setSiteID(0); # US

    # 4. paginating.
my $pPaginationtype = eBay::API::XML::DataType::PaginationType->new();
$pPaginationtype->setEntriesPerPage(25);
$pPaginationtype->setPageNumber(1);
$pCall->setPagination($pPaginationtype);

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

    my @aSearchItems = $pCall->getSearchResultItemArray()->getSearchResultItem();
    my $sNumOfItems = scalar @aSearchItems;
    if ($sNumOfItems) {
        foreach my $pSearchResultItem (@aSearchItems) {

            my $pItem = $pSearchResultItem->getItem();
            my $sItemId = $pItem->getItemID()->getValue();
            my $sTitle  = $pItem->getTitle();
            my $sSubTitle  = $pItem->getSubTitle();
            my $sDescription  = $pItem->getDescription();
            my $sStartPrice = $pItem->getStartPrice()->getValue();
            my $sCurrencyID = $pItem->getStartPrice()->getCurrencyID();  # code - like 'USD'

            my $pSellingStatus = $pItem->getSellingStatus();
            my $sCurrencyPrice = $pSellingStatus->getCurrentPrice()->getValue();
            my $sCurrencyCode  = $pSellingStatus->getCurrentPrice()->getCurrencyID();
            my $sNumOfBids = $pSellingStatus->getBidCount() || 0;

            my $pListingDetails = $pItem->getListingDetails();
            my $sEndTime = $pListingDetails->getEndTime();

            print "$sItemId, $sTitle, currPrice=$sCurrencyPrice ($sCurrencyCode), numOfBids=$sNumOfBids, endTime=$sEndTime\n";
        }
    } else {
        print "No items found for query='$sQuery'\n";
    }
}

sub usage {

    my $progname = $0;
    $progname =~ s,.*[\\/],,;  # use basename only
    $progname =~ s/\.\w*$//;   # strip extension, if any

    die <<"EOT";
Usage: $progname [-options]
    -q <query>    Query (search) string (pptional)
    -h            Print this message
EOT
}
