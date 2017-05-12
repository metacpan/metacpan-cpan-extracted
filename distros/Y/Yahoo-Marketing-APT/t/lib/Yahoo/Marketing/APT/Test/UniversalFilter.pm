package Yahoo::Marketing::APT::Test::UniversalFilter;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::UniversalFilter;

sub test_can_create_universal_filter_and_set_all_fields : Test(13) {

    my $universal_filter = Yahoo::Marketing::APT::UniversalFilter->new
                                                            ->accountID( 'account id' )
                                                            ->adBehaviorIDs( 'ad behavior ids' )
                                                            ->adContentTopicIDs( 'ad content topic ids' )
                                                            ->adLandingPageURLs( 'ad landing page urls' )
                                                            ->adThemeIDs( 'ad theme ids' )
                                                            ->advertiserAndNetworkAccountIDs( 'advertiser and network account ids' )
                                                            ->allowReviewedAdsOnly( 'allow reviewed ads only' )
                                                            ->inventoryAudienceGeographicWOEIDs( 'inventory audience geographic woeids' )
                                                            ->inventoryContentTopicIDs( 'inventory content topic ids' )
                                                            ->inventoryContentTypeIDs( 'inventory content type ids' )
                                                            ->inventoryDomains( 'inventory domains' )
                                                            ->publisherAndNetworkAccountIDs( 'publisher and network account ids' )
                   ;

    ok( $universal_filter );

    is( $universal_filter->accountID, 'account id', 'can get account id' );
    is( $universal_filter->adBehaviorIDs, 'ad behavior ids', 'can get ad behavior ids' );
    is( $universal_filter->adContentTopicIDs, 'ad content topic ids', 'can get ad content topic ids' );
    is( $universal_filter->adLandingPageURLs, 'ad landing page urls', 'can get ad landing page urls' );
    is( $universal_filter->adThemeIDs, 'ad theme ids', 'can get ad theme ids' );
    is( $universal_filter->advertiserAndNetworkAccountIDs, 'advertiser and network account ids', 'can get advertiser and network account ids' );
    is( $universal_filter->allowReviewedAdsOnly, 'allow reviewed ads only', 'can get allow reviewed ads only' );
    is( $universal_filter->inventoryAudienceGeographicWOEIDs, 'inventory audience geographic woeids', 'can get inventory audience geographic woeids' );
    is( $universal_filter->inventoryContentTopicIDs, 'inventory content topic ids', 'can get inventory content topic ids' );
    is( $universal_filter->inventoryContentTypeIDs, 'inventory content type ids', 'can get inventory content type ids' );
    is( $universal_filter->inventoryDomains, 'inventory domains', 'can get inventory domains' );
    is( $universal_filter->publisherAndNetworkAccountIDs, 'publisher and network account ids', 'can get publisher and network account ids' );

};



1;

