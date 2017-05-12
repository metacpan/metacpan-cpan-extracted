package Yahoo::Marketing::APT::Test::LibraryClickableVideoAdResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::LibraryClickableVideoAdResponse;

sub test_can_create_library_clickable_video_ad_response_and_set_all_fields : Test(4) {

    my $library_clickable_video_ad_response = Yahoo::Marketing::APT::LibraryClickableVideoAdResponse->new
                                                                                               ->errors( 'errors' )
                                                                                               ->libraryClickableVideoAd( 'library clickable video ad' )
                                                                                               ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $library_clickable_video_ad_response );

    is( $library_clickable_video_ad_response->errors, 'errors', 'can get errors' );
    is( $library_clickable_video_ad_response->libraryClickableVideoAd, 'library clickable video ad', 'can get library clickable video ad' );
    is( $library_clickable_video_ad_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

