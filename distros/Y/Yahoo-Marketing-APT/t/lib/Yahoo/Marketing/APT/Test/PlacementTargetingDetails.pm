package Yahoo::Marketing::APT::Test::PlacementTargetingDetails;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::PlacementTargetingDetails;

sub test_can_create_placement_targeting_details_and_set_all_fields : Test(11) {

    my $placement_targeting_details = Yahoo::Marketing::APT::PlacementTargetingDetails->new
                                                                                 ->ID( 'id' )
                                                                                 ->accountID( 'account id' )
                                                                                 ->adAttributesString( 'ad attributes string' )
                                                                                 ->audienceTargetingString( 'audience targeting string' )
                                                                                 ->contentTargetingString( 'content targeting string' )
                                                                                 ->frequencyTargetingString( 'frequency targeting string' )
                                                                                 ->placementAdAttributes( 'placement ad attributes' )
                                                                                 ->placementAudienceTargetingAttributes( 'placement audience targeting attributes' )
                                                                                 ->placementContentTargetingAttributes( 'placement content targeting attributes' )
                                                                                 ->placementFrequencyTargetingAttributes( 'placement frequency targeting attributes' )
                   ;

    ok( $placement_targeting_details );

    is( $placement_targeting_details->ID, 'id', 'can get id' );
    is( $placement_targeting_details->accountID, 'account id', 'can get account id' );
    is( $placement_targeting_details->adAttributesString, 'ad attributes string', 'can get ad attributes string' );
    is( $placement_targeting_details->audienceTargetingString, 'audience targeting string', 'can get audience targeting string' );
    is( $placement_targeting_details->contentTargetingString, 'content targeting string', 'can get content targeting string' );
    is( $placement_targeting_details->frequencyTargetingString, 'frequency targeting string', 'can get frequency targeting string' );
    is( $placement_targeting_details->placementAdAttributes, 'placement ad attributes', 'can get placement ad attributes' );
    is( $placement_targeting_details->placementAudienceTargetingAttributes, 'placement audience targeting attributes', 'can get placement audience targeting attributes' );
    is( $placement_targeting_details->placementContentTargetingAttributes, 'placement content targeting attributes', 'can get placement content targeting attributes' );
    is( $placement_targeting_details->placementFrequencyTargetingAttributes, 'placement frequency targeting attributes', 'can get placement frequency targeting attributes' );

};



1;

