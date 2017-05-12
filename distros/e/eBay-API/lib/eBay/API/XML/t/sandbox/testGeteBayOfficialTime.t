#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 2;

use_ok('eBay::API::XML::Call::GeteBayOfficialTime');
use eBay::API::XML::DataType::Enum::AckCodeType;

my $pCall = eBay::API::XML::Call::GeteBayOfficialTime->new();

$pCall->setDevID('row');
$pCall->setAppID('rowapp');
$pCall->setCertID('rowcert');
$pCall->setUserName('milenko_ph3');
$pCall->setUserPassword('Password123');
$pCall->setSiteID(211);

$pCall->execute();
is($pCall->getAck(), eBay::API::XML::DataType::Enum::AckCodeType::Success
                                     , 'Successful response received, time is '
                                       . ($pCall->getEBayOfficialTime() || '') );

my $sCompatLevel = $pCall->getCompatibilityLevel();
print "sCompatLevel=|$sCompatLevel|\n";

my $sVersion = $pCall->getVersion();
print "sVersion=|$sVersion|\n";

my $sDetailLevel = $pCall->getDetailLevel() || '';
print "sDetailLevel=|$sDetailLevel|\n";

my $sSiteID = $pCall->getSiteID() || '';
print "sSiteID=|$sSiteID|\n";

my $isPrettyPrint = 1;
print $pCall->getHttpRequestAsString( $isPrettyPrint );

print "-----\n";

print $pCall->getHttpResponseAsString( $isPrettyPrint );
