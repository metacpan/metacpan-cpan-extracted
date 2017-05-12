package Yahoo::Marketing::APT::Test::AdAttributes;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::AdAttributes;

sub test_can_create_ad_attributes_and_set_all_fields : Test(6) {

    my $ad_attributes = Yahoo::Marketing::APT::AdAttributes->new
                                                      ->adBehaviorIDs( 'ad behavior ids' )
                                                      ->adDeliveryModeIDs( 'ad delivery mode ids' )
                                                      ->adFormatID( 'ad format id' )
                                                      ->adLinkingSettings( 'ad linking settings' )
                                                      ->adSizeIDs( 'ad size ids' )
                   ;

    ok( $ad_attributes );

    is( $ad_attributes->adBehaviorIDs, 'ad behavior ids', 'can get ad behavior ids' );
    is( $ad_attributes->adDeliveryModeIDs, 'ad delivery mode ids', 'can get ad delivery mode ids' );
    is( $ad_attributes->adFormatID, 'ad format id', 'can get ad format id' );
    is( $ad_attributes->adLinkingSettings, 'ad linking settings', 'can get ad linking settings' );
    is( $ad_attributes->adSizeIDs, 'ad size ids', 'can get ad size ids' );

};



1;

