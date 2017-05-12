#! /usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Getopt::Long;

use eBay::API::XML::Call::GetFeedback;
use eBay::API::XML::DataType::UserIDType;
use eBay::API::XML::DataType::PaginationType;
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

my $sUserId = $options{'u'};
usage() unless $sUserId;
# End parse command line

# 1. instantiate the call
my $pCall = eBay::API::XML::Call::GetFeedback->new();

   # 1.1. set userId
my $pUserIDType = eBay::API::XML::DataType::UserIDType->new();
$pUserIDType->setValue( $sUserId );
$pCall->setUserID( $pUserIDType );

   # 1.2  set pagination parameters
my $pPagatinationType = eBay::API::XML::DataType::PaginationType->new();
$pPagatinationType->setPageNumber( 1 );
$pPagatinationType->setEntriesPerPage( 25 );
$pCall->setPagination( $pPagatinationType );

   # 1.3  set detail level (ReturnAll - to return all feedback items
my $raDetailLevel = [
     eBay::API::XML::DataType::Enum::DetailLevelCodeType::ReturnAll
                    ];
$pCall->setDetailLevel( $raDetailLevel);

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
    my $pFeedbackSummary = $pCall->getFeedbackSummary();

        # 5.1. find positive feedback counts
    my $raPosFeedbackPeriods = 
           $pFeedbackSummary->getPositiveFeedbackPeriodArray()->getFeedbackPeriod();
        # 5.2. find negative feedback counts
    my $raNegFeedbackPeriods = 
       $pFeedbackSummary->getNegativeFeedbackPeriodArray()->getFeedbackPeriod();
        # 5.3. find neutral feedback counts
    my $raNeutFeedbackPeriods = 
       $pFeedbackSummary->getNeutralFeedbackPeriodArray()->getFeedbackPeriod();
        # 5.4. find bid retractions in last 6 months (180 days)
    my $raBidRetractionFeedbackPeriods = 
       $pFeedbackSummary->getBidRetractionFeedbackPeriodArray()->getFeedbackPeriod();
    my @a = (
                 [ 'Positive feedback count', $raPosFeedbackPeriods]
                ,[ 'Negative feedback count', $raNegFeedbackPeriods]
                ,[ 'Neutral feedback count', $raNegFeedbackPeriods]
                ,[ 'Bid retractions feedback count', $raNegFeedbackPeriods]
            );

    my %map = (  '30'=>'Past Month'
                ,'180'=>'Past 6 Months'
                ,'365' => 'Past 12 Months'
                );

    foreach my $ra (@a) {
        my $title = $ra->[0];
        my $raFeedbackPeriod = $ra->[1];
        my $rhPos = extractFeedbackNumbers( $raFeedbackPeriod );
        print "$title:\n";

        foreach my $days ( sort {$a <=> $b} keys %$rhPos ) {
            next if $days == 0;
            my $cntTitle = $map{$days} || '';
            print "\t$cntTitle: $rhPos->{$days}\n";
        }
    }
    print "\n";

    my @aFeedItems = $pCall->getFeedbackDetailArray()->getFeedbackDetail();

    my $cnt = 1;
    foreach my $pFeedItem ( @aFeedItems ) {

        my $sCommentType = $pFeedItem->getCommentType();
        my $sItemNumber = $pFeedItem->getItemID()->getValue() || '';
        my $sFeedbackRole = $pFeedItem->getRole();
        my $sTimeOfComment = $pFeedItem->getCommentTime();

        print "$cnt. CommentType=$sCommentType\n";
        print "    ItemNumber=$sItemNumber\n";
        print "    FeedbackRole=$sFeedbackRole\n";
        print "    TimeOfComment=$sTimeOfComment\n";
        print "\n";
        $cnt++;
    }
}

=head2 extractFeedbackNumbers()

    my %h = {   '7' => undef
               ,'30' => undef 
               ,'180' => undef
            }

=cut 

sub extractFeedbackNumbers {

    my $raFeedbackPeriods = shift;

    my %h = ();
    foreach my $pFeedbackPeriodType ( @$raFeedbackPeriods) {
         my $sPeriodInDays = $pFeedbackPeriodType->getPeriodInDays();
         $h { $sPeriodInDays } = $pFeedbackPeriodType->getCount();
    }
    return \%h;
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
