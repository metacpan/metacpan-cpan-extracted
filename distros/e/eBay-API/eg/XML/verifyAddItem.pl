#! /usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Getopt::Long;
use File::Spec;

use eBay::API::XML::DataType::ItemType;
use eBay::API::XML::DataType::CategoryType;
use eBay::API::XML::Call::VerifyAddItem;

use eBay::API::XML::DataType::Enum::CountryCodeType;
use eBay::API::XML::DataType::Enum::CurrencyCodeType;
use eBay::API::XML::DataType::Enum::ListingDurationCodeType;
use eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType;

# Parse command line
my %options = ();
my @getopt_args = (
     'h',     # print usage
     't=s',   # authToken
     's=s',   # siteId
   );

GetOptions(\%options, @getopt_args);
usage() if $options{'h'};

my $sAuthToken = $options{'t'};
my $sSiteId = $options{'s'} || 0;

usage() if !($sAuthToken );
# End parse command line

my $sCountryCode  = eBay::API::XML::DataType::Enum::CountryCodeType::US;
my $sCurrencyCode = eBay::API::XML::DataType::Enum::CurrencyCodeType::USD;


    # 1. set item parameters
my $pItem = eBay::API::XML::DataType::ItemType->new();
$pItem->setCountry($sCountryCode);
$pItem->setCurrency($sCurrencyCode);
$pItem->setDescription('NewSchema item description');
$pItem->setListingDuration(eBay::API::XML::DataType::Enum::ListingDurationCodeType::Days_7);
$pItem->setLocation('San Jose, CA');
$pItem->setPaymentMethods(
				[eBay::API::XML::DataType::Enum::BuyerPaymentMethodCodeType::PersonalCheck]
						  );
$pItem->setQuantity(1);
$pItem->setRegionID(0);
$pItem->setStartPrice(1.0);
$pItem->setTitle('NewSchema item title ');

my $pCat = eBay::API::XML::DataType::CategoryType->new();
$pCat->setCategoryID(62053);   # 62053 - Video Games, Games for US site
$pItem->setPrimaryCategory($pCat);

    # 2. instantiate VerifyAddItem call
my $pCall = eBay::API::XML::Call::VerifyAddItem->new();
$pCall->setItem($pItem);

$pCall->setSiteID( $sSiteId );
$pCall->setAuthToken($sAuthToken);

    # 3. execute the call
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
        if ($sErrorCode eq '10001' ) {  # Invalid country
            print "\t Please verify that submitted category exists for site $sSiteId.\n";
        }
        my @aErrorParameters = $pError->getErrorParameters();
        foreach my $pErrorParameter ( @aErrorParameters) {
            my $sParamID = $pErrorParameter->getParamID();
            my $sValue  = $pErrorParameter->getValue();
            print "\tParamID=$sParamID, Value=$sValue\n";
        }
        print "\n";
    }
} else {

    my $sItemId = $pCall->getItemID()->getValue();
    print "sItemId=$sItemId\n";

    my @aFees = $pCall->getResponseDataType()->getFees()->getFee();
    foreach my $pFee (@aFees) {
        my $sFeeName = $pFee->getName();
        my $sFeeValue = $pFee->getFee()->getValue();
        my $sFeeCurrencyID = $pFee->getFee()->getCurrencyID();
        if ($sFeeValue > 0 ) {
            print "$sFeeName = $sFeeValue ($sFeeCurrencyID)\n";
        }
    }
}

sub usage {

    my $progname = $0;
    $progname =~ s,.*[\\/],,;  # use basename only
    $progname =~ s/\.\w*$//;   # strip extension, if any

    die <<"EOT";
Usage: $progname [-options]
    -t <authToken>      user's authToken
    -s <siteId>         siteId of site against a call is being executed
    -h                  Print this message
EOT

}
