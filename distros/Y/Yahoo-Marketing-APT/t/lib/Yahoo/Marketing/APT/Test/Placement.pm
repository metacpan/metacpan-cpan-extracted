package Yahoo::Marketing::APT::Test::Placement;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::Placement;

sub test_can_create_placement_and_set_all_fields : Test(22) {

    my $placement = Yahoo::Marketing::APT::Placement->new
                                               ->ID( 'id' )
                                               ->accountID( 'account id' )
                                               ->adAttributes( 'ad attributes' )
                                               ->adOptimization( 'ad optimization' )
                                               ->comments( 'comments' )
                                               ->contentTargetingAttributes( 'content targeting attributes' )
                                               ->createTimestamp( '2009-01-06T17:51:55' )
                                               ->endDate( '2009-01-07T17:51:55' )
                                               ->guaranteedPriceSettings( 'guaranteed price settings' )
                                               ->inventorySearchFilter( 'inventory search filter' )
                                               ->lastUpdateTimestamp( '2009-01-08T17:51:55' )
                                               ->name( 'name' )
                                               ->nonGuaranteedPriceSettings( 'non guaranteed price settings' )
                                               ->orderID( 'order id' )
                                               ->revenueCategory( 'revenue category' )
                                               ->revisedFromPlacementID( 'revised from placement id' )
                                               ->revisedToPlacementID( 'revised to placement id' )
                                               ->startDate( '2009-01-09T17:51:55' )
                                               ->status( 'status' )
                                               ->transferredFromPlacementID( 'transferred from placement id' )
                                               ->transferredToPlacementID( 'transferred to placement id' )
                   ;

    ok( $placement );

    is( $placement->ID, 'id', 'can get id' );
    is( $placement->accountID, 'account id', 'can get account id' );
    is( $placement->adAttributes, 'ad attributes', 'can get ad attributes' );
    is( $placement->adOptimization, 'ad optimization', 'can get ad optimization' );
    is( $placement->comments, 'comments', 'can get comments' );
    is( $placement->contentTargetingAttributes, 'content targeting attributes', 'can get content targeting attributes' );
    is( $placement->createTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $placement->endDate, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $placement->guaranteedPriceSettings, 'guaranteed price settings', 'can get guaranteed price settings' );
    is( $placement->inventorySearchFilter, 'inventory search filter', 'can get inventory search filter' );
    is( $placement->lastUpdateTimestamp, '2009-01-08T17:51:55', 'can get 2009-01-08T17:51:55' );
    is( $placement->name, 'name', 'can get name' );
    is( $placement->nonGuaranteedPriceSettings, 'non guaranteed price settings', 'can get non guaranteed price settings' );
    is( $placement->orderID, 'order id', 'can get order id' );
    is( $placement->revenueCategory, 'revenue category', 'can get revenue category' );
    is( $placement->revisedFromPlacementID, 'revised from placement id', 'can get revised from placement id' );
    is( $placement->revisedToPlacementID, 'revised to placement id', 'can get revised to placement id' );
    is( $placement->startDate, '2009-01-09T17:51:55', 'can get 2009-01-09T17:51:55' );
    is( $placement->status, 'status', 'can get status' );
    is( $placement->transferredFromPlacementID, 'transferred from placement id', 'can get transferred from placement id' );
    is( $placement->transferredToPlacementID, 'transferred to placement id', 'can get transferred to placement id' );

};



1;

