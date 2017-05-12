#! /usr/bin/perl -w
use strict;
use warnings;
use Test::More qw (no_plan);
use Data::Dumper;

print "Test GetFeedback call.\n";
use_ok('eBay::API::XML::Call::GetFeedback');
my $call = new eBay::API::XML::Call::GetFeedback;
$call->setUserID('rlbunau');
#print "request: " . $call->getRequestRawXml() . "\n";
$call->execute();

#print $call->getResponseRawXml() . "\n";
is($call->getResponseAck(), 'Success', 'Successful response received.');
#print $call->getFeedbackSummary()->getUniquePositiveFeedbackCount() . "\n";
is( $call->getFeedbackSummary()->getUniquePositiveFeedbackCount(), 0, 
    'Retrieved positive feedback count.');
#print $call->getFeedbackSummary()->getUniqueNegativeFeedbackCount() . "\n";
is( $call->getFeedbackSummary()->getUniqueNegativeFeedbackCount(), 0, 
    'Retrieved negative feedback count.');
