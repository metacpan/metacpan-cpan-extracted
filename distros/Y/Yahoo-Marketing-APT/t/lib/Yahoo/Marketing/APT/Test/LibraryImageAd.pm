package Yahoo::Marketing::APT::Test::LibraryImageAd;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::LibraryImageAd;

sub test_can_create_library_image_ad_and_set_all_fields : Test(23) {

    my $library_image_ad = Yahoo::Marketing::APT::LibraryImageAd->new
                                                           ->ID( 'id' )
                                                           ->accountID( 'account id' )
                                                           ->adFormat( 'ad format' )
                                                           ->adSizeID( 'ad size id' )
                                                           ->alternateText( 'alternate text' )
                                                           ->associatedToPlacement( 'associated to placement' )
                                                           ->compositeClickThroughURL( 'composite click through url' )
                                                           ->createTimestamp( '2009-01-06T17:51:55' )
                                                           ->editorialStatus( 'editorial status' )
                                                           ->externalCreativeURL( 'external creative url' )
                                                           ->folderID( 'folder id' )
                                                           ->height( 'height' )
                                                           ->imageCreativeID( 'image creative id' )
                                                           ->impressionTrackingURL( 'impression tracking url' )
                                                           ->isLocalCreative( 'is local creative' )
                                                           ->lastUpdateTimestamp( '2009-01-07T17:51:55' )
                                                           ->name( 'name' )
                                                           ->status( 'status' )
                                                           ->type( 'type' )
                                                           ->weight( 'weight' )
                                                           ->width( 'width' )
                                                           ->windowTarget( 'window target' )
                   ;

    ok( $library_image_ad );

    is( $library_image_ad->ID, 'id', 'can get id' );
    is( $library_image_ad->accountID, 'account id', 'can get account id' );
    is( $library_image_ad->adFormat, 'ad format', 'can get ad format' );
    is( $library_image_ad->adSizeID, 'ad size id', 'can get ad size id' );
    is( $library_image_ad->alternateText, 'alternate text', 'can get alternate text' );
    is( $library_image_ad->associatedToPlacement, 'associated to placement', 'can get associated to placement' );
    is( $library_image_ad->compositeClickThroughURL, 'composite click through url', 'can get composite click through url' );
    is( $library_image_ad->createTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $library_image_ad->editorialStatus, 'editorial status', 'can get editorial status' );
    is( $library_image_ad->externalCreativeURL, 'external creative url', 'can get external creative url' );
    is( $library_image_ad->folderID, 'folder id', 'can get folder id' );
    is( $library_image_ad->height, 'height', 'can get height' );
    is( $library_image_ad->imageCreativeID, 'image creative id', 'can get image creative id' );
    is( $library_image_ad->impressionTrackingURL, 'impression tracking url', 'can get impression tracking url' );
    is( $library_image_ad->isLocalCreative, 'is local creative', 'can get is local creative' );
    is( $library_image_ad->lastUpdateTimestamp, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $library_image_ad->name, 'name', 'can get name' );
    is( $library_image_ad->status, 'status', 'can get status' );
    is( $library_image_ad->type, 'type', 'can get type' );
    is( $library_image_ad->weight, 'weight', 'can get weight' );
    is( $library_image_ad->width, 'width', 'can get width' );
    is( $library_image_ad->windowTarget, 'window target', 'can get window target' );

};



1;

