package Yahoo::Marketing::APT::Test::BaseRateResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::BaseRateResponse;

sub test_can_create_base_rate_response_and_set_all_fields : Test(4) {

    my $base_rate_response = Yahoo::Marketing::APT::BaseRateResponse->new
                                                               ->baseRate( 'base rate' )
                                                               ->errors( 'errors' )
                                                               ->operationSucceeded( 'operation succeeded' )
                   ;

    ok( $base_rate_response );

    is( $base_rate_response->baseRate, 'base rate', 'can get base rate' );
    is( $base_rate_response->errors, 'errors', 'can get errors' );
    is( $base_rate_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );

};



1;

