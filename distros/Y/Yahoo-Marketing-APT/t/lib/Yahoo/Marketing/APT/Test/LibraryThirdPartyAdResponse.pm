package Yahoo::Marketing::APT::Test::LibraryThirdPartyAdResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::LibraryThirdPartyAdResponse;

sub test_can_create_library_third_party_ad_response_and_set_all_fields : Test(4) {

    my $library_third_party_ad_response = Yahoo::Marketing::APT::LibraryThirdPartyAdResponse->new
                                                                                       ->errors( 'errors' )
                                                                                       ->libraryThirdPartyAd( 'library third party ad' )
                                                                                       ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $library_third_party_ad_response );

    is( $library_third_party_ad_response->errors, 'errors', 'can get errors' );
    is( $library_third_party_ad_response->libraryThirdPartyAd, 'library third party ad', 'can get library third party ad' );
    is( $library_third_party_ad_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

