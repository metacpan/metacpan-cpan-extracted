#!/usr/bin/perl

use warnings;
use strict;
use lib 'lib';
use WebService::eBay;

my $response = WebService::eBay::APICall("GeteBayOfficialTime");
print "$response->{Timestamp}\n";

my $listingNumber = '142306955';
my $callDetails   = "<ItemID>$listingNumber</ItemID>
<EndingReason>OtherListingError</EndingReason>";

if ( WebService::eBay::APICall( "EndItem", $callDetails ) ) {
	print "\nDeleted $listingNumber from eBay\n";
} else {
	print("\nUnable to end listing $listingNumber\n");
}
