package Yahoo::Marketing::Test::Ad;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::Ad;

sub test_can_create_ad_and_set_all_fields : Test(20) {

    my $ad = Yahoo::Marketing::Ad->new
                                 ->ID( 'id' )
                                 ->accountID( 'account id' )
                                 ->adGroupID( 'ad group id' )
                                 ->carrierConfig( 'carrier config' )
                                 ->contentMatchQualityScore( 'content match quality score' )
                                 ->description( 'description' )
                                 ->displayUrl( 'display url' )
                                 ->editorialStatus( 'editorial status' )
                                 ->name( 'name' )
                                 ->participatesInMarketplace( 'participates in marketplace' )
                                 ->shortDescription( 'short description' )
                                 ->sponsoredSearchQualityScore( 'sponsored search quality score' )
                                 ->status( 'status' )
                                 ->title( 'title' )
                                 ->update( 'update' )
                                 ->url( 'url' )
                                 ->createTimestamp( '2008-01-06T17:51:55' )
                                 ->deleteTimestamp( '2008-01-07T17:51:55' )
                                 ->lastUpdateTimestamp( '2008-01-08T17:51:55' )
                   ;

    ok( $ad );

    is( $ad->ID, 'id', 'can get id' );
    is( $ad->accountID, 'account id', 'can get account id' );
    is( $ad->adGroupID, 'ad group id', 'can get ad group id' );
    is( $ad->carrierConfig, 'carrier config', 'can get carrier config' );
    is( $ad->contentMatchQualityScore, 'content match quality score', 'can get content match quality score' );
    is( $ad->description, 'description', 'can get description' );
    is( $ad->displayUrl, 'display url', 'can get display url' );
    is( $ad->editorialStatus, 'editorial status', 'can get editorial status' );
    is( $ad->name, 'name', 'can get name' );
    is( $ad->participatesInMarketplace, 'participates in marketplace', 'can get participates in marketplace' );
    is( $ad->shortDescription, 'short description', 'can get short description' );
    is( $ad->sponsoredSearchQualityScore, 'sponsored search quality score', 'can get sponsored search quality score' );
    is( $ad->status, 'status', 'can get status' );
    is( $ad->title, 'title', 'can get title' );
    is( $ad->update, 'update', 'can get update' );
    is( $ad->url, 'url', 'can get url' );
    is( $ad->createTimestamp, '2008-01-06T17:51:55', 'can get 2008-01-06T17:51:55' );
    is( $ad->deleteTimestamp, '2008-01-07T17:51:55', 'can get 2008-01-07T17:51:55' );
    is( $ad->lastUpdateTimestamp, '2008-01-08T17:51:55', 'can get 2008-01-08T17:51:55' );

};



1;

