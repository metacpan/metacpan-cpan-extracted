package Yahoo::Marketing::APT::Test::AlternateImage;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::AlternateImage;

sub test_can_create_alternate_image_and_set_all_fields : Test(6) {

    my $alternate_image = Yahoo::Marketing::APT::AlternateImage->new
                                                          ->alternateText( 'alternate text' )
                                                          ->compositeClickThroughURL( 'composite click through url' )
                                                          ->imageCreativeID( 'image creative id' )
                                                          ->imageCreativeURL( 'image creative url' )
                                                          ->impressionTrackingURL( 'impression tracking url' )
                   ;

    ok( $alternate_image );

    is( $alternate_image->alternateText, 'alternate text', 'can get alternate text' );
    is( $alternate_image->compositeClickThroughURL, 'composite click through url', 'can get composite click through url' );
    is( $alternate_image->imageCreativeID, 'image creative id', 'can get image creative id' );
    is( $alternate_image->imageCreativeURL, 'image creative url', 'can get image creative url' );
    is( $alternate_image->impressionTrackingURL, 'impression tracking url', 'can get impression tracking url' );

};



1;

