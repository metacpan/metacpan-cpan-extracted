package Yahoo::Marketing::Test::AdGroupOptimizationGuidelines;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::AdGroupOptimizationGuidelines;

sub test_can_create_ad_group_optimization_guidelines_and_set_all_fields : Test(19) {

    my $ad_group_optimization_guidelines = Yahoo::Marketing::AdGroupOptimizationGuidelines->new
                                                                                          ->CPA( 'cpa' )
                                                                                          ->CPC( 'cpc' )
                                                                                          ->CPM( 'cpm' )
                                                                                          ->ROAS( 'roas' )
                                                                                          ->accountID( 'account id' )
                                                                                          ->adGroupID( 'ad group id' )
                                                                                          ->averageConversionRate( 'average conversion rate' )
                                                                                          ->averageRevenuePerConversion( 'average revenue per conversion' )
                                                                                          ->campaignID( 'campaign id' )
                                                                                          ->contentMatchMaxBid( 'content match max bid' )
                                                                                          ->conversionImportance( 'conversion importance' )
                                                                                          ->impressionImportance( 'impression importance' )
                                                                                          ->leadImportance( 'lead importance' )
                                                                                          ->sponsoredSearchMaxBid( 'sponsored search max bid' )
                                                                                          ->sponsoredSearchMinPosition( 'sponsored search min position' )
                                                                                          ->sponsoredSearchMinPositionImportance( 'sponsored search min position importance' )
                                                                                          ->createTimestamp( '2008-01-06T17:51:55' )
                                                                                          ->lastUpdateTimestamp( '2008-01-07T17:51:55' )
                   ;

    ok( $ad_group_optimization_guidelines );

    is( $ad_group_optimization_guidelines->CPA, 'cpa', 'can get cpa' );
    is( $ad_group_optimization_guidelines->CPC, 'cpc', 'can get cpc' );
    is( $ad_group_optimization_guidelines->CPM, 'cpm', 'can get cpm' );
    is( $ad_group_optimization_guidelines->ROAS, 'roas', 'can get roas' );
    is( $ad_group_optimization_guidelines->accountID, 'account id', 'can get account id' );
    is( $ad_group_optimization_guidelines->adGroupID, 'ad group id', 'can get ad group id' );
    is( $ad_group_optimization_guidelines->averageConversionRate, 'average conversion rate', 'can get average conversion rate' );
    is( $ad_group_optimization_guidelines->averageRevenuePerConversion, 'average revenue per conversion', 'can get average revenue per conversion' );
    is( $ad_group_optimization_guidelines->campaignID, 'campaign id', 'can get campaign id' );
    is( $ad_group_optimization_guidelines->contentMatchMaxBid, 'content match max bid', 'can get content match max bid' );
    is( $ad_group_optimization_guidelines->conversionImportance, 'conversion importance', 'can get conversion importance' );
    is( $ad_group_optimization_guidelines->impressionImportance, 'impression importance', 'can get impression importance' );
    is( $ad_group_optimization_guidelines->leadImportance, 'lead importance', 'can get lead importance' );
    is( $ad_group_optimization_guidelines->sponsoredSearchMaxBid, 'sponsored search max bid', 'can get sponsored search max bid' );
    is( $ad_group_optimization_guidelines->sponsoredSearchMinPosition, 'sponsored search min position', 'can get sponsored search min position' );
    is( $ad_group_optimization_guidelines->sponsoredSearchMinPositionImportance, 'sponsored search min position importance', 'can get sponsored search min position importance' );
    is( $ad_group_optimization_guidelines->createTimestamp, '2008-01-06T17:51:55', 'can get 2008-01-06T17:51:55' );
    is( $ad_group_optimization_guidelines->lastUpdateTimestamp, '2008-01-07T17:51:55', 'can get 2008-01-07T17:51:55' );

};



1;

