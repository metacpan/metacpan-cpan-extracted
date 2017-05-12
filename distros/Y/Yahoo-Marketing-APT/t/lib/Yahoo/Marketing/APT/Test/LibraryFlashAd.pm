package Yahoo::Marketing::APT::Test::LibraryFlashAd;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::LibraryFlashAd;

sub test_can_create_library_flash_ad_and_set_all_fields : Test(23) {

    my $library_flash_ad = Yahoo::Marketing::APT::LibraryFlashAd->new
                                                           ->ID( 'id' )
                                                           ->accountID( 'account id' )
                                                           ->adFormat( 'ad format' )
                                                           ->adSizeID( 'ad size id' )
                                                           ->alternateImage( 'alternate image' )
                                                           ->associatedToPlacement( 'associated to placement' )
                                                           ->compositeClickThroughURLs( 'composite click through urls' )
                                                           ->createTimestamp( '2009-01-06T17:51:55' )
                                                           ->editorialStatus( 'editorial status' )
                                                           ->flashCreativeID( 'flash creative id' )
                                                           ->flashCreativeURL( 'flash creative url' )
                                                           ->folderID( 'folder id' )
                                                           ->height( 'height' )
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

    ok( $library_flash_ad );

    is( $library_flash_ad->ID, 'id', 'can get id' );
    is( $library_flash_ad->accountID, 'account id', 'can get account id' );
    is( $library_flash_ad->adFormat, 'ad format', 'can get ad format' );
    is( $library_flash_ad->adSizeID, 'ad size id', 'can get ad size id' );
    is( $library_flash_ad->alternateImage, 'alternate image', 'can get alternate image' );
    is( $library_flash_ad->associatedToPlacement, 'associated to placement', 'can get associated to placement' );
    is( $library_flash_ad->compositeClickThroughURLs, 'composite click through urls', 'can get composite click through urls' );
    is( $library_flash_ad->createTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $library_flash_ad->editorialStatus, 'editorial status', 'can get editorial status' );
    is( $library_flash_ad->flashCreativeID, 'flash creative id', 'can get flash creative id' );
    is( $library_flash_ad->flashCreativeURL, 'flash creative url', 'can get flash creative url' );
    is( $library_flash_ad->folderID, 'folder id', 'can get folder id' );
    is( $library_flash_ad->height, 'height', 'can get height' );
    is( $library_flash_ad->impressionTrackingURL, 'impression tracking url', 'can get impression tracking url' );
    is( $library_flash_ad->isLocalCreative, 'is local creative', 'can get is local creative' );
    is( $library_flash_ad->lastUpdateTimestamp, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $library_flash_ad->name, 'name', 'can get name' );
    is( $library_flash_ad->status, 'status', 'can get status' );
    is( $library_flash_ad->type, 'type', 'can get type' );
    is( $library_flash_ad->weight, 'weight', 'can get weight' );
    is( $library_flash_ad->width, 'width', 'can get width' );
    is( $library_flash_ad->windowTarget, 'window target', 'can get window target' );

};



1;

