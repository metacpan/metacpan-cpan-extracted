package Yahoo::Marketing::APT::Test::LibraryClickToSiteOverlayVideoAdResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::LibraryClickToSiteOverlayVideoAdResponse;

sub test_can_create_library_click_to_site_overlay_video_ad_response_and_set_all_fields : Test(4) {

    my $library_click_to_site_overlay_video_ad_response = Yahoo::Marketing::APT::LibraryClickToSiteOverlayVideoAdResponse->new
                                                                                                                    ->errors( 'errors' )
                                                                                                                    ->libraryClickToSiteOverlayVideoAd( 'library click to site overlay video ad' )
                                                                                                                    ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $library_click_to_site_overlay_video_ad_response );

    is( $library_click_to_site_overlay_video_ad_response->errors, 'errors', 'can get errors' );
    is( $library_click_to_site_overlay_video_ad_response->libraryClickToSiteOverlayVideoAd, 'library click to site overlay video ad', 'can get library click to site overlay video ad' );
    is( $library_click_to_site_overlay_video_ad_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

