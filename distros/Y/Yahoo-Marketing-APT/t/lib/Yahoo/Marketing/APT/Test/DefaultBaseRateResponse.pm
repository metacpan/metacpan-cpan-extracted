package Yahoo::Marketing::APT::Test::DefaultBaseRateResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::DefaultBaseRateResponse;

sub test_can_create_default_base_rate_response_and_set_all_fields : Test(4) {

    my $default_base_rate_response = Yahoo::Marketing::APT::DefaultBaseRateResponse->new
                                                                              ->defaultBaseRate( 'default base rate' )
                                                                              ->errors( 'errors' )
                                                                              ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $default_base_rate_response );

    is( $default_base_rate_response->defaultBaseRate, 'default base rate', 'can get default base rate' );
    is( $default_base_rate_response->errors, 'errors', 'can get errors' );
    is( $default_base_rate_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

