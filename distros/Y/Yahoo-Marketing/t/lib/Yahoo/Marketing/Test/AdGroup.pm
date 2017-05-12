package Yahoo::Marketing::Test::AdGroup;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::AdGroup;

sub test_can_create_ad_group_and_set_all_fields : Test(21) {

    my $ad_group = Yahoo::Marketing::AdGroup->new
                                            ->ID( 'id' )
                                            ->accountID( 'account id' )
                                            ->advancedMatchON( 'advanced match on' )
                                            ->campaignID( 'campaign id' )
                                            ->carrierConfig( 'carrier config' )
                                            ->contentMatchMaxBid( 'content match max bid' )
                                            ->contentMatchON( 'content match on' )
                                            ->name( 'name' )
                                            ->sponsoredSearchMaxBid( 'sponsored search max bid' )
                                            ->sponsoredSearchON( 'sponsored search on' )
                                            ->status( 'status' )
                                            ->watchON( 'watch on' )
                                            ->adAutoOptimizationON( 'ad auto optimization on' )
                                            ->contentMatchBidStatus( 'content match bid status' )
                                            ->contentMatchMaxBidTimestamp( '2008-01-06T17:51:55' )
                                            ->contentMatchMinBid( 'content match min bid' )
                                            ->createTimestamp( '2008-01-07T17:51:55' )
                                            ->deleteTimestamp( '2008-01-08T17:51:55' )
                                            ->lastUpdateTimestamp( '2008-01-09T17:51:55' )
                                            ->sponsoredSearchMaxBidTimestamp( '2008-01-10T17:51:55' )
                   ;

    ok( $ad_group );

    is( $ad_group->ID, 'id', 'can get id' );
    is( $ad_group->accountID, 'account id', 'can get account id' );
    is( $ad_group->advancedMatchON, 'advanced match on', 'can get advanced match on' );
    is( $ad_group->campaignID, 'campaign id', 'can get campaign id' );
    is( $ad_group->carrierConfig, 'carrier config', 'can get carrier config' );
    is( $ad_group->contentMatchMaxBid, 'content match max bid', 'can get content match max bid' );
    is( $ad_group->contentMatchON, 'content match on', 'can get content match on' );
    is( $ad_group->name, 'name', 'can get name' );
    is( $ad_group->sponsoredSearchMaxBid, 'sponsored search max bid', 'can get sponsored search max bid' );
    is( $ad_group->sponsoredSearchON, 'sponsored search on', 'can get sponsored search on' );
    is( $ad_group->status, 'status', 'can get status' );
    is( $ad_group->watchON, 'watch on', 'can get watch on' );
    is( $ad_group->adAutoOptimizationON, 'ad auto optimization on', 'can get ad auto optimization on' );
    is( $ad_group->contentMatchBidStatus, 'content match bid status', 'can get content match bid status' );
    is( $ad_group->contentMatchMaxBidTimestamp, '2008-01-06T17:51:55', 'can get 2008-01-06T17:51:55' );
    is( $ad_group->contentMatchMinBid, 'content match min bid', 'can get content match min bid' );
    is( $ad_group->createTimestamp, '2008-01-07T17:51:55', 'can get 2008-01-07T17:51:55' );
    is( $ad_group->deleteTimestamp, '2008-01-08T17:51:55', 'can get 2008-01-08T17:51:55' );
    is( $ad_group->lastUpdateTimestamp, '2008-01-09T17:51:55', 'can get 2008-01-09T17:51:55' );
    is( $ad_group->sponsoredSearchMaxBidTimestamp, '2008-01-10T17:51:55', 'can get 2008-01-10T17:51:55' );

};



1;

