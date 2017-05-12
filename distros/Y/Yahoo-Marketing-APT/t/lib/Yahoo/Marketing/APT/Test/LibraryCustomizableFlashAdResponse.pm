package Yahoo::Marketing::APT::Test::LibraryCustomizableFlashAdResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::LibraryCustomizableFlashAdResponse;

sub test_can_create_library_customizable_flash_ad_response_and_set_all_fields : Test(4) {

    my $library_customizable_flash_ad_response = Yahoo::Marketing::APT::LibraryCustomizableFlashAdResponse->new
                                                                                                     ->errors( 'errors' )
                                                                                                     ->libraryCustomizableFlashAd( 'library customizable flash ad' )
                                                                                                     ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $library_customizable_flash_ad_response );

    is( $library_customizable_flash_ad_response->errors, 'errors', 'can get errors' );
    is( $library_customizable_flash_ad_response->libraryCustomizableFlashAd, 'library customizable flash ad', 'can get library customizable flash ad' );
    is( $library_customizable_flash_ad_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

