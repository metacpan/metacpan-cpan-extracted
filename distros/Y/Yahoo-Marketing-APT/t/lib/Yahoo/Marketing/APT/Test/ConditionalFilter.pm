package Yahoo::Marketing::APT::Test::ConditionalFilter;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::ConditionalFilter;

sub test_can_create_conditional_filter_and_set_all_fields : Test(14) {

    my $conditional_filter = Yahoo::Marketing::APT::ConditionalFilter->new
                                                                ->ID( 'id' )
                                                                ->accountID( 'account id' )
                                                                ->adBehaviorIDs( 'ad behavior ids' )
                                                                ->adContentTopicIDs( 'ad content topic ids' )
                                                                ->adLandingPageURLs( 'ad landing page urls' )
                                                                ->adThemeIDs( 'ad theme ids' )
                                                                ->advertiserAndNetworkAccountIDs( 'advertiser and network account ids' )
                                                                ->allowReviewedAdsOnly( 'allow reviewed ads only' )
                                                                ->createTimestamp( '2009-01-06T17:51:55' )
                                                                ->isActive( 'is active' )
                                                                ->lastUpdateTimestamp( '2009-01-07T17:51:55' )
                                                                ->name( 'name' )
                                                                ->publisherSelector( 'publisher selector' )
                   ;

    ok( $conditional_filter );

    is( $conditional_filter->ID, 'id', 'can get id' );
    is( $conditional_filter->accountID, 'account id', 'can get account id' );
    is( $conditional_filter->adBehaviorIDs, 'ad behavior ids', 'can get ad behavior ids' );
    is( $conditional_filter->adContentTopicIDs, 'ad content topic ids', 'can get ad content topic ids' );
    is( $conditional_filter->adLandingPageURLs, 'ad landing page urls', 'can get ad landing page urls' );
    is( $conditional_filter->adThemeIDs, 'ad theme ids', 'can get ad theme ids' );
    is( $conditional_filter->advertiserAndNetworkAccountIDs, 'advertiser and network account ids', 'can get advertiser and network account ids' );
    is( $conditional_filter->allowReviewedAdsOnly, 'allow reviewed ads only', 'can get allow reviewed ads only' );
    is( $conditional_filter->createTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $conditional_filter->isActive, 'is active', 'can get is active' );
    is( $conditional_filter->lastUpdateTimestamp, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $conditional_filter->name, 'name', 'can get name' );
    is( $conditional_filter->publisherSelector, 'publisher selector', 'can get publisher selector' );

};



1;

