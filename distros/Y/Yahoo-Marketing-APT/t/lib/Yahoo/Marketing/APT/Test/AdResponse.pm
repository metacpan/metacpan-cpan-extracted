package Yahoo::Marketing::APT::Test::AdResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::AdResponse;

sub test_can_create_ad_response_and_set_all_fields : Test(4) {

    my $ad_response = Yahoo::Marketing::APT::AdResponse->new
                                                  ->ad( 'ad' )
                                                  ->errors( 'errors' )
                                                  ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $ad_response );

    is( $ad_response->ad, 'ad', 'can get ad' );
    is( $ad_response->errors, 'errors', 'can get errors' );
    is( $ad_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

