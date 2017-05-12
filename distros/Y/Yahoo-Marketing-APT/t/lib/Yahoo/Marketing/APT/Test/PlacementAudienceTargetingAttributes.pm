package Yahoo::Marketing::APT::Test::PlacementAudienceTargetingAttributes;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::PlacementAudienceTargetingAttributes;

sub test_can_create_placement_audience_targeting_attributes_and_set_all_fields : Test(13) {

    my $placement_audience_targeting_attributes = Yahoo::Marketing::APT::PlacementAudienceTargetingAttributes->new
                                                                                                        ->ages( 'ages' )
                                                                                                        ->audienceSegments( 'audience segments' )
                                                                                                        ->bandwidths( 'bandwidths' )
                                                                                                        ->browsers( 'browsers' )
                                                                                                        ->countries( 'countries' )
                                                                                                        ->customGeoAreas( 'custom geo areas' )
                                                                                                        ->gender( 'gender' )
                                                                                                        ->incomes( 'incomes' )
                                                                                                        ->marketingAreas( 'marketing areas' )
                                                                                                        ->operatingSystems( 'operating systems' )
                                                                                                        ->states( 'states' )
                                                                                                        ->yahooPremiumBehavioralSegments( 'yahoo premium behavioral segments' )
                   ;

    ok( $placement_audience_targeting_attributes );

    is( $placement_audience_targeting_attributes->ages, 'ages', 'can get ages' );
    is( $placement_audience_targeting_attributes->audienceSegments, 'audience segments', 'can get audience segments' );
    is( $placement_audience_targeting_attributes->bandwidths, 'bandwidths', 'can get bandwidths' );
    is( $placement_audience_targeting_attributes->browsers, 'browsers', 'can get browsers' );
    is( $placement_audience_targeting_attributes->countries, 'countries', 'can get countries' );
    is( $placement_audience_targeting_attributes->customGeoAreas, 'custom geo areas', 'can get custom geo areas' );
    is( $placement_audience_targeting_attributes->gender, 'gender', 'can get gender' );
    is( $placement_audience_targeting_attributes->incomes, 'incomes', 'can get incomes' );
    is( $placement_audience_targeting_attributes->marketingAreas, 'marketing areas', 'can get marketing areas' );
    is( $placement_audience_targeting_attributes->operatingSystems, 'operating systems', 'can get operating systems' );
    is( $placement_audience_targeting_attributes->states, 'states', 'can get states' );
    is( $placement_audience_targeting_attributes->yahooPremiumBehavioralSegments, 'yahoo premium behavioral segments', 'can get yahoo premium behavioral segments' );

};



1;

