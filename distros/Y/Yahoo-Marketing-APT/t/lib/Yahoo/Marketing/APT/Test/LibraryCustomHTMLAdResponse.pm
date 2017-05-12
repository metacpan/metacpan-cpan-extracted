package Yahoo::Marketing::APT::Test::LibraryCustomHTMLAdResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::LibraryCustomHTMLAdResponse;

sub test_can_create_library_custom_htmlad_response_and_set_all_fields : Test(4) {

    my $library_custom_htmlad_response = Yahoo::Marketing::APT::LibraryCustomHTMLAdResponse->new
                                                                                      ->errors( 'errors' )
                                                                                      ->libraryCustomHTMLAd( 'library custom htmlad' )
                                                                                      ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $library_custom_htmlad_response );

    is( $library_custom_htmlad_response->errors, 'errors', 'can get errors' );
    is( $library_custom_htmlad_response->libraryCustomHTMLAd, 'library custom htmlad', 'can get library custom htmlad' );
    is( $library_custom_htmlad_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

