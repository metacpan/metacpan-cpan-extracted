#! /usr/bin/perl -w
use strict;
use warnings;
use Test::More qw (no_plan);
use Data::Dumper;

use Scalar::Util 'blessed';

print "Test GetItem call.\n";
use_ok('eBay::API::XML::Call::GetAttributesCS');

use eBay::API::XML::DataType::Enum::AckCodeType;
use eBay::API::XML::DataType::Enum::DetailLevelCodeType;


my $sSiteId = 203;

my $pCall = eBay::API::XML::Call::GetAttributesCS->new();

    # 1. tell server that we can receive GZIPed response
$pCall->setCompression(1);

    # 2. set site id
$pCall->setSiteID($sSiteId);

    # 3. set detail level
my @aDetailLevel = (
        eBay::API::XML::DataType::Enum::DetailLevelCodeType::ReturnAll
                   );
$pCall->setDetailLevel(\@aDetailLevel);

    # 4. set AttributeSetID
my @aAttributeSetID = (2298, 2299);
$pCall->setAttributeSetID(\@aAttributeSetID);
    # 5. execute the call
$pCall->execute();

is($pCall->getResponseAck(), 'Success', 'Successful response received.');
#print $pCall->getResponseRawXml();


