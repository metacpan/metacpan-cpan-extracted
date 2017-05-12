package Yahoo::Marketing::APT::Test::AdCopyResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::AdCopyResponse;

sub test_can_create_ad_copy_response_and_set_all_fields : Test(4) {

    my $ad_copy_response = Yahoo::Marketing::APT::AdCopyResponse->new
                                                           ->ads( 'ads' )
                                                           ->errors( 'errors' )
                                                           ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $ad_copy_response );

    is( $ad_copy_response->ads, 'ads', 'can get ads' );
    is( $ad_copy_response->errors, 'errors', 'can get errors' );
    is( $ad_copy_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

