package Yahoo::Marketing::APT::Test::LibraryInteractivePharmaceuticalVideoAd;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::LibraryInteractivePharmaceuticalVideoAd;

sub test_can_create_library_interactive_pharmaceutical_video_ad_and_set_all_fields : Test(17) {

    my $library_interactive_pharmaceutical_video_ad = Yahoo::Marketing::APT::LibraryInteractivePharmaceuticalVideoAd->new
                                                                                                               ->ID( 'id' )
                                                                                                               ->accountID( 'account id' )
                                                                                                               ->actFour( 'act four' )
                                                                                                               ->actOne( 'act one' )
                                                                                                               ->actThree( 'act three' )
                                                                                                               ->actTwo( 'act two' )
                                                                                                               ->adFormat( 'ad format' )
                                                                                                               ->associatedToPlacement( 'associated to placement' )
                                                                                                               ->createTimestamp( '2009-01-06T17:51:55' )
                                                                                                               ->editorialStatus( 'editorial status' )
                                                                                                               ->folderID( 'folder id' )
                                                                                                               ->impressionTrackingURLs( 'impression tracking urls' )
                                                                                                               ->lastUpdateTimestamp( '2009-01-07T17:51:55' )
                                                                                                               ->name( 'name' )
                                                                                                               ->status( 'status' )
                                                                                                               ->type( 'type' )
                   ;

    ok( $library_interactive_pharmaceutical_video_ad );

    is( $library_interactive_pharmaceutical_video_ad->ID, 'id', 'can get id' );
    is( $library_interactive_pharmaceutical_video_ad->accountID, 'account id', 'can get account id' );
    is( $library_interactive_pharmaceutical_video_ad->actFour, 'act four', 'can get act four' );
    is( $library_interactive_pharmaceutical_video_ad->actOne, 'act one', 'can get act one' );
    is( $library_interactive_pharmaceutical_video_ad->actThree, 'act three', 'can get act three' );
    is( $library_interactive_pharmaceutical_video_ad->actTwo, 'act two', 'can get act two' );
    is( $library_interactive_pharmaceutical_video_ad->adFormat, 'ad format', 'can get ad format' );
    is( $library_interactive_pharmaceutical_video_ad->associatedToPlacement, 'associated to placement', 'can get associated to placement' );
    is( $library_interactive_pharmaceutical_video_ad->createTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $library_interactive_pharmaceutical_video_ad->editorialStatus, 'editorial status', 'can get editorial status' );
    is( $library_interactive_pharmaceutical_video_ad->folderID, 'folder id', 'can get folder id' );
    is( $library_interactive_pharmaceutical_video_ad->impressionTrackingURLs, 'impression tracking urls', 'can get impression tracking urls' );
    is( $library_interactive_pharmaceutical_video_ad->lastUpdateTimestamp, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $library_interactive_pharmaceutical_video_ad->name, 'name', 'can get name' );
    is( $library_interactive_pharmaceutical_video_ad->status, 'status', 'can get status' );
    is( $library_interactive_pharmaceutical_video_ad->type, 'type', 'can get type' );

};



1;

