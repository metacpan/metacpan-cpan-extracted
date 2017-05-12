package Yahoo::Marketing::APT::Test::PlacementAdAttributes;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::PlacementAdAttributes;

sub test_can_create_placement_ad_attributes_and_set_all_fields : Test(6) {

    my $placement_ad_attributes = Yahoo::Marketing::APT::PlacementAdAttributes->new
                                                                         ->adBehaviors( 'ad behaviors' )
                                                                         ->adDeliveryModes( 'ad delivery modes' )
                                                                         ->adFormat( 'ad format' )
                                                                         ->adLinkingType( 'ad linking type' )
                                                                         ->adSizes( 'ad sizes' )
                   ;

    ok( $placement_ad_attributes );

    is( $placement_ad_attributes->adBehaviors, 'ad behaviors', 'can get ad behaviors' );
    is( $placement_ad_attributes->adDeliveryModes, 'ad delivery modes', 'can get ad delivery modes' );
    is( $placement_ad_attributes->adFormat, 'ad format', 'can get ad format' );
    is( $placement_ad_attributes->adLinkingType, 'ad linking type', 'can get ad linking type' );
    is( $placement_ad_attributes->adSizes, 'ad sizes', 'can get ad sizes' );

};



1;

