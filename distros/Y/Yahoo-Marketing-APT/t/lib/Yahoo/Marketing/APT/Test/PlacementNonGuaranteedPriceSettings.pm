package Yahoo::Marketing::APT::Test::PlacementNonGuaranteedPriceSettings;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::PlacementNonGuaranteedPriceSettings;

sub test_can_create_placement_non_guaranteed_price_settings_and_set_all_fields : Test(5) {

    my $placement_non_guaranteed_price_settings = Yahoo::Marketing::APT::PlacementNonGuaranteedPriceSettings->new
                                                                                                       ->ROITarget( 'roitarget' )
                                                                                                       ->bidDate( '2009-01-06T17:51:55' )
                                                                                                       ->maxBid( 'max bid' )
                                                                                                       ->pricingType( 'pricing type' )
                   ;

    ok( $placement_non_guaranteed_price_settings );

    is( $placement_non_guaranteed_price_settings->ROITarget, 'roitarget', 'can get roitarget' );
    is( $placement_non_guaranteed_price_settings->bidDate, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $placement_non_guaranteed_price_settings->maxBid, 'max bid', 'can get max bid' );
    is( $placement_non_guaranteed_price_settings->pricingType, 'pricing type', 'can get pricing type' );

};



1;

