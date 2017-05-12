package Yahoo::Marketing::APT::Test::LibraryImageAdResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::LibraryImageAdResponse;

sub test_can_create_library_image_ad_response_and_set_all_fields : Test(4) {

    my $library_image_ad_response = Yahoo::Marketing::APT::LibraryImageAdResponse->new
                                                                            ->errors( 'errors' )
                                                                            ->libraryImageAd( 'library image ad' )
                                                                            ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $library_image_ad_response );

    is( $library_image_ad_response->errors, 'errors', 'can get errors' );
    is( $library_image_ad_response->libraryImageAd, 'library image ad', 'can get library image ad' );
    is( $library_image_ad_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

