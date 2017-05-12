#! /usr/bin/perl -w
use strict;
use warnings;
use Test::More qw (no_plan);
use Data::Dumper;

print "Test GetUser call.\n";
use_ok('eBay::API::XML::Call::GetUser');

use eBay::API::XML::DataType::Enum::AckCodeType;

my $call = new eBay::API::XML::Call::GetUser;
my $request = $call->getRequestDataType();
my $props = $request->getPropertiesList();
foreach (@{$props}) {
  my ($fieldname, $namespace, $arraytype, $datatype) = @$_;
  print $fieldname . " " . $namespace . ' ' . $arraytype . ' ' . $datatype . "\n";
#  print Dumper $_;
}
can_ok($call, 'setUserID');
$call->setUserID('rlbunau');
print $call->getRequestRawXml() . "\n";
$call->setDetailLevel('ReturnSummary');
$call->execute();
#print Dumper($call);
#print $call->getResponseRawXml() . "\n";
is($call->getAck(), 'Success', 'Successful response received.');
is($call->getUser()->getSite(), 'Australia', 
   'Expect user site is Australia: ' . $call->getUser()->getSite());
#print Dumper($call->getUser());
ok ($call->getUser()->getSellerInfo()->isQualifiesForB2BVAT() == 0 
        ,'Successful retrieve of seller info.');

#
#  Test when user not found
#      whether we indeed get error '904'
#

my $pCall = eBay::API::XML::Call::GetUser->new();
$pCall->setUserID('user_not_found_dd');
$pCall->setDetailLevel('ReturnSummary');
$pCall->execute();

my $sAck = $pCall->getAck();
isnt( $sAck, eBay::API::XML::DataType::Enum::AckCodeType::Success
            , 'Call failed - which was expected!');

my $hasUserNotFoundError = $pCall->hasError(904);    
ok ( $hasUserNotFoundError, 'User not found - which was expected!');
