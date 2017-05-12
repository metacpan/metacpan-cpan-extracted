package Yahoo::Marketing::APT::Test::PlacementGuaranteedPriceSettings;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::PlacementGuaranteedPriceSettings;

sub test_can_create_placement_guaranteed_price_settings_and_set_all_fields : Test(7) {

    my $placement_guaranteed_price_settings = Yahoo::Marketing::APT::PlacementGuaranteedPriceSettings->new
                                                                                                ->deliveryModel( 'delivery model' )
                                                                                                ->impressionGoal( 'impression goal' )
                                                                                                ->price( 'price' )
                                                                                                ->priceDate( '2009-01-06T17:51:55' )
                                                                                                ->pricingType( 'pricing type' )
                                                                                                ->revenueModel( 'revenue model' )
                   ;

    ok( $placement_guaranteed_price_settings );

    is( $placement_guaranteed_price_settings->deliveryModel, 'delivery model', 'can get delivery model' );
    is( $placement_guaranteed_price_settings->impressionGoal, 'impression goal', 'can get impression goal' );
    is( $placement_guaranteed_price_settings->price, 'price', 'can get price' );
    is( $placement_guaranteed_price_settings->priceDate, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $placement_guaranteed_price_settings->pricingType, 'pricing type', 'can get pricing type' );
    is( $placement_guaranteed_price_settings->revenueModel, 'revenue model', 'can get revenue model' );

};



1;

