package Yahoo::Marketing::APT::Test::PlacementGuaranteedSettings;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::PlacementGuaranteedSettings;

sub test_can_create_placement_guaranteed_settings_and_set_all_fields : Test(20) {

    my $placement_guaranteed_settings = Yahoo::Marketing::APT::PlacementGuaranteedSettings->new
                                                                                     ->adBehaviorID( 'ad behavior id' )
                                                                                     ->adDeliveryModeID( 'ad delivery mode id' )
                                                                                     ->adFormatID( 'ad format id' )
                                                                                     ->adLinkingSettings( 'ad linking settings' )
                                                                                     ->adSizeID( 'ad size id' )
                                                                                     ->contentTopicID( 'content topic id' )
                                                                                     ->contentTypeID( 'content type id' )
                                                                                     ->customContentCategoryID( 'custom content category id' )
                                                                                     ->deliveryModel( 'delivery model' )
                                                                                     ->impressionGoal( 'impression goal' )
                                                                                     ->inventorySearchFilter( 'inventory search filter' )
                                                                                     ->placementTarget( 'placement target' )
                                                                                     ->price( 'price' )
                                                                                     ->priceDate( '2009-01-06T17:51:55' )
                                                                                     ->pricingModel( 'pricing model' )
                                                                                     ->revenueCategory( 'revenue category' )
                                                                                     ->revenueModel( 'revenue model' )
                                                                                     ->sectionIDs( 'section ids' )
                                                                                     ->siteID( 'site id' )
                   ;

    ok( $placement_guaranteed_settings );

    is( $placement_guaranteed_settings->adBehaviorID, 'ad behavior id', 'can get ad behavior id' );
    is( $placement_guaranteed_settings->adDeliveryModeID, 'ad delivery mode id', 'can get ad delivery mode id' );
    is( $placement_guaranteed_settings->adFormatID, 'ad format id', 'can get ad format id' );
    is( $placement_guaranteed_settings->adLinkingSettings, 'ad linking settings', 'can get ad linking settings' );
    is( $placement_guaranteed_settings->adSizeID, 'ad size id', 'can get ad size id' );
    is( $placement_guaranteed_settings->contentTopicID, 'content topic id', 'can get content topic id' );
    is( $placement_guaranteed_settings->contentTypeID, 'content type id', 'can get content type id' );
    is( $placement_guaranteed_settings->customContentCategoryID, 'custom content category id', 'can get custom content category id' );
    is( $placement_guaranteed_settings->deliveryModel, 'delivery model', 'can get delivery model' );
    is( $placement_guaranteed_settings->impressionGoal, 'impression goal', 'can get impression goal' );
    is( $placement_guaranteed_settings->inventorySearchFilter, 'inventory search filter', 'can get inventory search filter' );
    is( $placement_guaranteed_settings->placementTarget, 'placement target', 'can get placement target' );
    is( $placement_guaranteed_settings->price, 'price', 'can get price' );
    is( $placement_guaranteed_settings->priceDate, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $placement_guaranteed_settings->pricingModel, 'pricing model', 'can get pricing model' );
    is( $placement_guaranteed_settings->revenueCategory, 'revenue category', 'can get revenue category' );
    is( $placement_guaranteed_settings->revenueModel, 'revenue model', 'can get revenue model' );
    is( $placement_guaranteed_settings->sectionIDs, 'section ids', 'can get section ids' );
    is( $placement_guaranteed_settings->siteID, 'site id', 'can get site id' );

};



1;

