package Yahoo::Marketing::APT::Test::LibraryThirdPartyAd;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::LibraryThirdPartyAd;

sub test_can_create_library_third_party_ad_and_set_all_fields : Test(21) {

    my $library_third_party_ad = Yahoo::Marketing::APT::LibraryThirdPartyAd->new
                                                                      ->ID( 'id' )
                                                                      ->accountID( 'account id' )
                                                                      ->adBehavior( 'ad behavior' )
                                                                      ->adFormat( 'ad format' )
                                                                      ->adSecurity( 'ad security' )
                                                                      ->adSizeID( 'ad size id' )
                                                                      ->associatedToPlacement( 'associated to placement' )
                                                                      ->createTimestamp( '2009-01-06T17:51:55' )
                                                                      ->editorialStatus( 'editorial status' )
                                                                      ->folderID( 'folder id' )
                                                                      ->height( 'height' )
                                                                      ->impressionTrackingURL( 'impression tracking url' )
                                                                      ->lastUpdateTimestamp( '2009-01-07T17:51:55' )
                                                                      ->name( 'name' )
                                                                      ->status( 'status' )
                                                                      ->tag( 'tag' )
                                                                      ->tagWithMacros( 'tag with macros' )
                                                                      ->type( 'type' )
                                                                      ->vendorID( 'vendor id' )
                                                                      ->width( 'width' )
                   ;

    ok( $library_third_party_ad );

    is( $library_third_party_ad->ID, 'id', 'can get id' );
    is( $library_third_party_ad->accountID, 'account id', 'can get account id' );
    is( $library_third_party_ad->adBehavior, 'ad behavior', 'can get ad behavior' );
    is( $library_third_party_ad->adFormat, 'ad format', 'can get ad format' );
    is( $library_third_party_ad->adSecurity, 'ad security', 'can get ad security' );
    is( $library_third_party_ad->adSizeID, 'ad size id', 'can get ad size id' );
    is( $library_third_party_ad->associatedToPlacement, 'associated to placement', 'can get associated to placement' );
    is( $library_third_party_ad->createTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $library_third_party_ad->editorialStatus, 'editorial status', 'can get editorial status' );
    is( $library_third_party_ad->folderID, 'folder id', 'can get folder id' );
    is( $library_third_party_ad->height, 'height', 'can get height' );
    is( $library_third_party_ad->impressionTrackingURL, 'impression tracking url', 'can get impression tracking url' );
    is( $library_third_party_ad->lastUpdateTimestamp, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $library_third_party_ad->name, 'name', 'can get name' );
    is( $library_third_party_ad->status, 'status', 'can get status' );
    is( $library_third_party_ad->tag, 'tag', 'can get tag' );
    is( $library_third_party_ad->tagWithMacros, 'tag with macros', 'can get tag with macros' );
    is( $library_third_party_ad->type, 'type', 'can get type' );
    is( $library_third_party_ad->vendorID, 'vendor id', 'can get vendor id' );
    is( $library_third_party_ad->width, 'width', 'can get width' );

};



1;

