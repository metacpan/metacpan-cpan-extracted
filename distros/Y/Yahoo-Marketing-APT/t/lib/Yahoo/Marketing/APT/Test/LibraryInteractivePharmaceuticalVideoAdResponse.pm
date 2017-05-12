package Yahoo::Marketing::APT::Test::LibraryInteractivePharmaceuticalVideoAdResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::LibraryInteractivePharmaceuticalVideoAdResponse;

sub test_can_create_library_interactive_pharmaceutical_video_ad_response_and_set_all_fields : Test(4) {

    my $library_interactive_pharmaceutical_video_ad_response = Yahoo::Marketing::APT::LibraryInteractivePharmaceuticalVideoAdResponse->new
                                                                                                                                ->errors( 'errors' )
                                                                                                                                ->libraryInteractivePharmaceuticalVideoAd( 'library interactive pharmaceutical video ad' )
                                                                                                                                ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $library_interactive_pharmaceutical_video_ad_response );

    is( $library_interactive_pharmaceutical_video_ad_response->errors, 'errors', 'can get errors' );
    is( $library_interactive_pharmaceutical_video_ad_response->libraryInteractivePharmaceuticalVideoAd, 'library interactive pharmaceutical video ad', 'can get library interactive pharmaceutical video ad' );
    is( $library_interactive_pharmaceutical_video_ad_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

