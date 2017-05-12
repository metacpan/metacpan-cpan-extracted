package Yahoo::Marketing::APT::Test::LibraryFlashAdResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::LibraryFlashAdResponse;

sub test_can_create_library_flash_ad_response_and_set_all_fields : Test(4) {

    my $library_flash_ad_response = Yahoo::Marketing::APT::LibraryFlashAdResponse->new
                                                                            ->errors( 'errors' )
                                                                            ->libraryFlashAd( 'library flash ad' )
                                                                            ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $library_flash_ad_response );

    is( $library_flash_ad_response->errors, 'errors', 'can get errors' );
    is( $library_flash_ad_response->libraryFlashAd, 'library flash ad', 'can get library flash ad' );
    is( $library_flash_ad_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

