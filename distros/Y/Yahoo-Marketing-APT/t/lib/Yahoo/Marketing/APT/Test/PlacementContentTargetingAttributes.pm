package Yahoo::Marketing::APT::Test::PlacementContentTargetingAttributes;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::PlacementContentTargetingAttributes;

sub test_can_create_placement_content_targeting_attributes_and_set_all_fields : Test(8) {

    my $placement_content_targeting_attributes = Yahoo::Marketing::APT::PlacementContentTargetingAttributes->new
                                                                                                      ->contentTopics( 'content topics' )
                                                                                                      ->contentTypes( 'content types' )
                                                                                                      ->customContentCategories( 'custom content categories' )
                                                                                                      ->customSections( 'custom sections' )
                                                                                                      ->networks( 'networks' )
                                                                                                      ->publishers( 'publishers' )
                                                                                                      ->sites( 'sites' )
                   ;

    ok( $placement_content_targeting_attributes );

    is( $placement_content_targeting_attributes->contentTopics, 'content topics', 'can get content topics' );
    is( $placement_content_targeting_attributes->contentTypes, 'content types', 'can get content types' );
    is( $placement_content_targeting_attributes->customContentCategories, 'custom content categories', 'can get custom content categories' );
    is( $placement_content_targeting_attributes->customSections, 'custom sections', 'can get custom sections' );
    is( $placement_content_targeting_attributes->networks, 'networks', 'can get networks' );
    is( $placement_content_targeting_attributes->publishers, 'publishers', 'can get publishers' );
    is( $placement_content_targeting_attributes->sites, 'sites', 'can get sites' );

};



1;

