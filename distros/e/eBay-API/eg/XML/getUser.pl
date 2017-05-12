#! /usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Getopt::Long;
use File::Spec;

use eBay::API::XML::Call::GetUser;
use eBay::API::XML::DataType::Enum::AckCodeType;
use eBay::API::XML::DataType::Enum::DetailLevelCodeType;

# Parse command line
my %options = ();
my @getopt_args = (
    'h',     # print usage
    'u=s',   # userId
                  );

GetOptions(\%options, @getopt_args);
usage() if $options{'h'};

my $userId = $options{'u'};
usage() unless $userId;
# End parse command line

my $pCall = eBay::API::XML::Call::GetUser->new();

    # 1. set UserId
my $pUserID = eBay::API::XML::DataType::UserIDType->new();
$pUserID->setValue($userId);
$pCall->setUserID($pUserID);

    # 2. set detail level
$pCall->setDetailLevel(eBay::API::XML::DataType::Enum::DetailLevelCodeType::ReturnSummary);

    # 3. execute the call
$pCall->execute();

    # 4. look for errors
my $hasErrors = $pCall->hasErrors();
if ($hasErrors) {
    
    my @aErrors = $pCall->getErrors();
    foreach my $pError ( @aErrors ) {

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

    # 5. no errors - retrieve data
    my $pUser = $pCall->getUser();  # type - eBay::API::XML::DataType::UserType

    my $sUserId = $pUser->getUserID()->getValue();
    my $sStatus = $pUser->getStatus();
    my $sSite = $pUser->getSite();

    my $sFeedbackScore = $pUser->getFeedbackScore();
    my $sFeedbackRatingStar = $pUser->getFeedbackRatingStar();
    my $sPositiveFeedbackPercent = $pUser->getPositiveFeedbackPercent();
    my $sUniquePositiveFeedbackCount = $pUser->getUniquePositiveFeedbackCount();
    my $sUniqueNegativeFeedbackCount = $pUser->getUniqueNegativeFeedbackCount();

    my $isUserIDChanged = $pUser->isUserIDChanged();
    my $sUserIDLastChanged = $pUser->getUserIDLastChanged();
    my $isNewUser = $pUser->isNewUser();
    my $sRegistrationDate = $pUser->getRegistrationDate();
    my $isEBayGoodStanding = $pUser->isEBayGoodStanding();

    my $pSellerInfo = $pUser->getSellerInfo();
    my $sSellerLevel = $pSellerInfo->getSellerLevel();
    my $isStoreOwner = $pSellerInfo->isStoreOwner();
    my $isGoodStanding = $pSellerInfo->isGoodStanding();

    print "UserId=$sUserId\n";
    print "Status=$sStatus\n";
    print "Site=$sSite\n";
    print "FeedbackScore=$sFeedbackScore\n";
}

sub usage {

    my $progname = $0;
    $progname =~ s,.*[\\/],,;  # use basename only
    $progname =~ s/\.\w*$//;   # strip extension, if any

    die <<"EOT";
Usage: $progname [-options]
    -u <userId>   userId
    -h            Print this message
EOT
}
