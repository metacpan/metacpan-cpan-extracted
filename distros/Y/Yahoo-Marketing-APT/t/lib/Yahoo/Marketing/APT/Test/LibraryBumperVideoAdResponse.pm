package Yahoo::Marketing::APT::Test::LibraryBumperVideoAdResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::LibraryBumperVideoAdResponse;

sub test_can_create_library_bumper_video_ad_response_and_set_all_fields : Test(4) {

    my $library_bumper_video_ad_response = Yahoo::Marketing::APT::LibraryBumperVideoAdResponse->new
                                                                                         ->errors( 'errors' )
                                                                                         ->libraryBumperVideoAd( 'library bumper video ad' )
                                                                                         ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $library_bumper_video_ad_response );

    is( $library_bumper_video_ad_response->errors, 'errors', 'can get errors' );
    is( $library_bumper_video_ad_response->libraryBumperVideoAd, 'library bumper video ad', 'can get library bumper video ad' );
    is( $library_bumper_video_ad_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

