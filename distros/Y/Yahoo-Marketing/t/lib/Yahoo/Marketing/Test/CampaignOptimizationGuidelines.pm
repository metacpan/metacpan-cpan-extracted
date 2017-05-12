package Yahoo::Marketing::Test::CampaignOptimizationGuidelines;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::CampaignOptimizationGuidelines;

sub test_can_create_campaign_optimization_guidelines_and_set_all_fields : Test(22) {

    my $campaign_optimization_guidelines = Yahoo::Marketing::CampaignOptimizationGuidelines->new
                                                                                           ->CPA( 'cpa' )
                                                                                           ->CPC( 'cpc' )
                                                                                           ->CPM( 'cpm' )
                                                                                           ->ROAS( 'roas' )
                                                                                           ->accountID( 'account id' )
                                                                                           ->averageConversionRate( 'average conversion rate' )
                                                                                           ->averageRevenuePerConversion( 'average revenue per conversion' )
                                                                                           ->bidLimitHeadroom( 'bid limit headroom' )
                                                                                           ->campaignID( 'campaign id' )
                                                                                           ->conversionImportance( 'conversion importance' )
                                                                                           ->conversionMetric( 'conversion metric' )
                                                                                           ->impressionImportance( 'impression importance' )
                                                                                           ->leadImportance( 'lead importance' )
                                                                                           ->maxBid( 'max bid' )
                                                                                           ->monthlySpendRate( 'monthly spend rate' )
                                                                                           ->sponsoredSearchMinPosition( 'sponsored search min position' )
                                                                                           ->sponsoredSearchMinPositionImportance( 'sponsored search min position importance' )
                                                                                           ->taggedForConversion( 'tagged for conversion' )
                                                                                           ->taggedForRevenue( 'tagged for revenue' )
                                                                                           ->createTimestamp( '2008-01-06T17:51:55' )
                                                                                           ->lastUpdateTimestamp( '2008-01-07T17:51:55' )
                   ;

    ok( $campaign_optimization_guidelines );

    is( $campaign_optimization_guidelines->CPA, 'cpa', 'can get cpa' );
    is( $campaign_optimization_guidelines->CPC, 'cpc', 'can get cpc' );
    is( $campaign_optimization_guidelines->CPM, 'cpm', 'can get cpm' );
    is( $campaign_optimization_guidelines->ROAS, 'roas', 'can get roas' );
    is( $campaign_optimization_guidelines->accountID, 'account id', 'can get account id' );
    is( $campaign_optimization_guidelines->averageConversionRate, 'average conversion rate', 'can get average conversion rate' );
    is( $campaign_optimization_guidelines->averageRevenuePerConversion, 'average revenue per conversion', 'can get average revenue per conversion' );
    is( $campaign_optimization_guidelines->bidLimitHeadroom, 'bid limit headroom', 'can get bid limit headroom' );
    is( $campaign_optimization_guidelines->campaignID, 'campaign id', 'can get campaign id' );
    is( $campaign_optimization_guidelines->conversionImportance, 'conversion importance', 'can get conversion importance' );
    is( $campaign_optimization_guidelines->conversionMetric, 'conversion metric', 'can get conversion metric' );
    is( $campaign_optimization_guidelines->impressionImportance, 'impression importance', 'can get impression importance' );
    is( $campaign_optimization_guidelines->leadImportance, 'lead importance', 'can get lead importance' );
    is( $campaign_optimization_guidelines->maxBid, 'max bid', 'can get max bid' );
    is( $campaign_optimization_guidelines->monthlySpendRate, 'monthly spend rate', 'can get monthly spend rate' );
    is( $campaign_optimization_guidelines->sponsoredSearchMinPosition, 'sponsored search min position', 'can get sponsored search min position' );
    is( $campaign_optimization_guidelines->sponsoredSearchMinPositionImportance, 'sponsored search min position importance', 'can get sponsored search min position importance' );
    is( $campaign_optimization_guidelines->taggedForConversion, 'tagged for conversion', 'can get tagged for conversion' );
    is( $campaign_optimization_guidelines->taggedForRevenue, 'tagged for revenue', 'can get tagged for revenue' );
    is( $campaign_optimization_guidelines->createTimestamp, '2008-01-06T17:51:55', 'can get 2008-01-06T17:51:55' );
    is( $campaign_optimization_guidelines->lastUpdateTimestamp, '2008-01-07T17:51:55', 'can get 2008-01-07T17:51:55' );

};



1;

