package Yahoo::Marketing::APT::Test::PlacementNonGuaranteedSettings;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::PlacementNonGuaranteedSettings;

sub test_can_create_placement_non_guaranteed_settings_and_set_all_fields : Test(11) {

    my $placement_non_guaranteed_settings = Yahoo::Marketing::APT::PlacementNonGuaranteedSettings->new
                                                                                            ->adBehaviorIDs( 'ad behavior ids' )
                                                                                            ->adDeliveryModeIDs( 'ad delivery mode ids' )
                                                                                            ->adSizeIDs( 'ad size ids' )
                                                                                            ->bidDescriptor( 'bid descriptor' )
                                                                                            ->contentTopicIDs( 'content topic ids' )
                                                                                            ->contentTypeIDs( 'content type ids' )
                                                                                            ->customContentCategoryIDs( 'custom content category ids' )
                                                                                            ->networkID( 'network id' )
                                                                                            ->sectionIDs( 'section ids' )
                                                                                            ->siteIDs( 'site ids' )
                   ;

    ok( $placement_non_guaranteed_settings );

    is( $placement_non_guaranteed_settings->adBehaviorIDs, 'ad behavior ids', 'can get ad behavior ids' );
    is( $placement_non_guaranteed_settings->adDeliveryModeIDs, 'ad delivery mode ids', 'can get ad delivery mode ids' );
    is( $placement_non_guaranteed_settings->adSizeIDs, 'ad size ids', 'can get ad size ids' );
    is( $placement_non_guaranteed_settings->bidDescriptor, 'bid descriptor', 'can get bid descriptor' );
    is( $placement_non_guaranteed_settings->contentTopicIDs, 'content topic ids', 'can get content topic ids' );
    is( $placement_non_guaranteed_settings->contentTypeIDs, 'content type ids', 'can get content type ids' );
    is( $placement_non_guaranteed_settings->customContentCategoryIDs, 'custom content category ids', 'can get custom content category ids' );
    is( $placement_non_guaranteed_settings->networkID, 'network id', 'can get network id' );
    is( $placement_non_guaranteed_settings->sectionIDs, 'section ids', 'can get section ids' );
    is( $placement_non_guaranteed_settings->siteIDs, 'site ids', 'can get site ids' );

};



1;

