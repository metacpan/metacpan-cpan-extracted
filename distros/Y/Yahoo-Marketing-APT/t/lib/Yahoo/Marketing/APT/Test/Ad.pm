package Yahoo::Marketing::APT::Test::Ad;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::Ad;

sub test_can_create_ad_and_set_all_fields : Test(14) {

    my $ad = Yahoo::Marketing::APT::Ad->new
                                 ->ID( 'id' )
                                 ->accountID( 'account id' )
                                 ->adOptimizationWeight( 'ad optimization weight' )
                                 ->clickThroughURLs( 'click through urls' )
                                 ->createTimestamp( '2009-01-06T17:51:55' )
                                 ->endDate( '2009-01-07T17:51:55' )
                                 ->lastUpdateTimestamp( '2009-01-08T17:51:55' )
                                 ->legacyAdGroupID( 'legacy ad group id' )
                                 ->libraryAdID( 'library ad id' )
                                 ->placementID( 'placement id' )
                                 ->startDate( '2009-01-09T17:51:55' )
                                 ->status( 'status' )
                                 ->type( 'type' )
                   ;

    ok( $ad );

    is( $ad->ID, 'id', 'can get id' );
    is( $ad->accountID, 'account id', 'can get account id' );
    is( $ad->adOptimizationWeight, 'ad optimization weight', 'can get ad optimization weight' );
    is( $ad->clickThroughURLs, 'click through urls', 'can get click through urls' );
    is( $ad->createTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $ad->endDate, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $ad->lastUpdateTimestamp, '2009-01-08T17:51:55', 'can get 2009-01-08T17:51:55' );
    is( $ad->legacyAdGroupID, 'legacy ad group id', 'can get legacy ad group id' );
    is( $ad->libraryAdID, 'library ad id', 'can get library ad id' );
    is( $ad->placementID, 'placement id', 'can get placement id' );
    is( $ad->startDate, '2009-01-09T17:51:55', 'can get 2009-01-09T17:51:55' );
    is( $ad->status, 'status', 'can get status' );
    is( $ad->type, 'type', 'can get type' );

};



1;

