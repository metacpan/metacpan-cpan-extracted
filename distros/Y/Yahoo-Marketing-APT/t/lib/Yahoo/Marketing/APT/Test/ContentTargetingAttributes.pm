package Yahoo::Marketing::APT::Test::ContentTargetingAttributes;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::ContentTargetingAttributes;

sub test_can_create_content_targeting_attributes_and_set_all_fields : Test(8) {

    my $content_targeting_attributes = Yahoo::Marketing::APT::ContentTargetingAttributes->new
                                                                                   ->contentTopics( 'content topics' )
                                                                                   ->contentTypes( 'content types' )
                                                                                   ->customContentCategories( 'custom content categories' )
                                                                                   ->placementTarget( 'placement target' )
                                                                                   ->sections( 'sections' )
                                                                                   ->siteStructureSettings( 'site structure settings' )
                                                                                   ->sites( 'sites' )
                   ;

    ok( $content_targeting_attributes );

    is( $content_targeting_attributes->contentTopics, 'content topics', 'can get content topics' );
    is( $content_targeting_attributes->contentTypes, 'content types', 'can get content types' );
    is( $content_targeting_attributes->customContentCategories, 'custom content categories', 'can get custom content categories' );
    is( $content_targeting_attributes->placementTarget, 'placement target', 'can get placement target' );
    is( $content_targeting_attributes->sections, 'sections', 'can get sections' );
    is( $content_targeting_attributes->siteStructureSettings, 'site structure settings', 'can get site structure settings' );
    is( $content_targeting_attributes->sites, 'sites', 'can get sites' );

};



1;

