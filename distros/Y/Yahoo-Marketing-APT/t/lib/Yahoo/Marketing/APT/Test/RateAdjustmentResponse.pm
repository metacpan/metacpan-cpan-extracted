package Yahoo::Marketing::APT::Test::RateAdjustmentResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::RateAdjustmentResponse;

sub test_can_create_rate_adjustment_response_and_set_all_fields : Test(4) {

    my $rate_adjustment_response = Yahoo::Marketing::APT::RateAdjustmentResponse->new
                                                                           ->errors( 'errors' )
                                                                           ->operationSucceeded( 'operation succeeded' )
                                                                           ->rateAdjustment( 'rate adjustment' )
                   ;

    ok( $rate_adjustment_response );

    is( $rate_adjustment_response->errors, 'errors', 'can get errors' );
    is( $rate_adjustment_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );
    is( $rate_adjustment_response->rateAdjustment, 'rate adjustment', 'can get rate adjustment' );

};



1;

